package com.healthpilot.health_pilot

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.health.services.client.HealthServices
import androidx.health.services.client.MeasureCallback
import androidx.health.services.client.PassiveListenerCallback
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.DeltaDataType
import androidx.health.services.client.data.PassiveListenerConfig
import androidx.lifecycle.LifecycleService
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * VitalsService — Wear OS foreground service that:
 *  1. Reads heart rate and SpO2 in real-time via MeasureClient (every 1-2 s).
 *  2. Listens for completed sleep sessions via PassiveMonitoringClient.
 *  3. Sends all data to the paired phone over the Wearable Data Layer.
 *
 * Always calls .setUrgent() on every PutDataRequest — without it the watch
 * batches delivery and data can be delayed by several minutes.
 *
 * Extends LifecycleService (not WearActivity) so the service survives screen-sleep.
 */
class VitalsService : LifecycleService() {

    companion object {
        private const val TAG = "VitalsService"
        private const val CHANNEL_ID = "vitals_foreground_channel"
        private const val NOTIFICATION_ID = 101

        // Data Layer paths — must match WearListenerService on the phone
        private const val PATH_VITALS = "/vitals"
        private const val PATH_SLEEP  = "/sleep"

        // Null sentinel: Data Layer maps cannot hold null, so we use -1.0
        // and restore null on the phone side before sending to Flutter.
        private const val NULL_SENTINEL = -1.0
    }

    // ── Health Services handles ──────────────────────────────────────────────

    private val healthClient by lazy { HealthServices.getClient(this) }
    private val measureClient  by lazy { healthClient.measureClient }
    private val passiveClient  by lazy { healthClient.passiveMonitoringClient }

    // Accumulated values so we always send both fields together even if only
    // one type updated in a given callback firing.
    private var latestHr:   Double = NULL_SENTINEL
    private var latestSpo2: Double = NULL_SENTINEL

    // ── MeasureCallback (real-time HR + SpO2, fires every ~1-2 s) ────────────

    private val measureCallback = object : MeasureCallback {

        override fun onAvailabilityChanged(
            dataType: DeltaDataType<*, *>,
            availability: Availability,
        ) {
            Log.d(TAG, "Availability changed: $dataType → $availability")
        }

        override fun onDataReceived(data: DataPointContainer) {
            // Heart rate samples
            data.getData(DataType.HEART_RATE_BPM).lastOrNull()?.let {
                latestHr = it.value
            }
            // SpO2 samples
            data.getData(DataType.SPO2).lastOrNull()?.let {
                latestSpo2 = it.value
            }

            Log.d(TAG, "Sensor reading → HR=$latestHr  SpO2=$latestSpo2")
            sendVitalsToPhone(latestHr, latestSpo2)
        }
    }

    // ── PassiveListenerCallback (sleep sessions arrive after session ends) ───

    private val sleepCallback = object : PassiveListenerCallback {

        override fun onNewDataPointsReceived(dataPoints: DataPointContainer) {
            // Convert boot-relative Duration → wall-clock epoch millis
            val bootEpochMs = System.currentTimeMillis() - SystemClock.elapsedRealtime()

            dataPoints.getData(DataType.SLEEP_SESSION).forEach { segment ->
                val startMs = bootEpochMs + segment.startDurationFromBoot.inWholeMilliseconds
                val endMs   = bootEpochMs + segment.endDurationFromBoot.inWholeMilliseconds
                val durationMinutes =
                    (segment.endDurationFromBoot - segment.startDurationFromBoot).inWholeMinutes

                Log.d(TAG, "Sleep session: start=$startMs end=$endMs dur=${durationMinutes}min")
                sendSleepToPhone(startMs, endMs, durationMinutes)
            }
        }

        override fun onRegistered() {
            Log.d(TAG, "Passive sleep listener registered.")
        }

        override fun onRegistrationFailed(throwable: Throwable) {
            Log.e(TAG, "Passive listener registration failed: ${throwable.message}")
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        lifecycleScope.launch {
            registerMeasureCallbacks()
            registerSleepListener()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        lifecycleScope.launch {
            try {
                measureClient.unregisterMeasureCallbackAsync(
                    DataType.HEART_RATE_BPM,
                    measureCallback,
                ).await()
                measureClient.unregisterMeasureCallbackAsync(
                    DataType.SPO2,
                    measureCallback,
                ).await()
                passiveClient.clearPassiveListenerCallbackAsync().await()
            } catch (e: Exception) {
                Log.w(TAG, "Cleanup error: ${e.message}")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        return START_STICKY  // Restart if killed by OS
    }

    // ── Sensor registration ──────────────────────────────────────────────────

    private suspend fun registerMeasureCallbacks() {
        try {
            measureClient.registerMeasureCallbackAsync(
                DataType.HEART_RATE_BPM,
                { runnable -> runnable.run() },  // Main-thread executor
                measureCallback,
            ).await()
            measureClient.registerMeasureCallbackAsync(
                DataType.SPO2,
                { runnable -> runnable.run() },
                measureCallback,
            ).await()
            Log.d(TAG, "MeasureCallbacks registered for HR + SpO2.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register measure callbacks: ${e.message}")
        }
    }

    private suspend fun registerSleepListener() {
        try {
            val config = PassiveListenerConfig.builder()
                .setDataTypes(setOf(DataType.SLEEP_SESSION))
                .build()
            passiveClient.setPassiveListenerCallbackAsync(config, sleepCallback).await()
            Log.d(TAG, "Passive sleep listener registered.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register sleep listener: ${e.message}")
        }
    }

    // ── Data Layer send helpers ──────────────────────────────────────────────

    /**
     * Sends heart rate + SpO2 to the phone on path [PATH_VITALS].
     * Uses -1.0 as sentinel for a missing (null) reading.
     * Always calls .setUrgent() — without it, delivery is batched and delayed.
     */
    private fun sendVitalsToPhone(heartRate: Double, spo2: Double) {
        lifecycleScope.launch {
            try {
                val request = PutDataMapRequest.create(PATH_VITALS).apply {
                    dataMap.putDouble("heartRate", heartRate)
                    dataMap.putDouble("spo2", spo2)
                    dataMap.putLong("timestamp", System.currentTimeMillis())
                }.asPutDataRequest().setUrgent()  // ← CRITICAL: no setUrgent = minutes of delay

                val client = Wearable.getDataClient(this@VitalsService)
                client.putDataItem(request).await()
                Log.d(TAG, "✓ Vitals sent to phone → HR=$heartRate  SpO2=$spo2")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send vitals: ${e.message}")
            }
        }
    }

    /**
     * Sends a completed sleep session to the phone on path [PATH_SLEEP].
     * Times are epoch milliseconds (UTC).
     */
    private fun sendSleepToPhone(sleepStart: Long, sleepEnd: Long, durationMinutes: Long) {
        lifecycleScope.launch {
            try {
                val request = PutDataMapRequest.create(PATH_SLEEP).apply {
                    dataMap.putLong("sleepStart", sleepStart)
                    dataMap.putLong("sleepEnd", sleepEnd)
                    dataMap.putLong("durationMinutes", durationMinutes)
                    // Include current time so identical sessions still trigger onDataChanged
                    dataMap.putLong("timestamp", System.currentTimeMillis())
                }.asPutDataRequest().setUrgent()

                val client = Wearable.getDataClient(this@VitalsService)
                client.putDataItem(request).await()
                Log.d(TAG, "✓ Sleep session sent to phone: ${durationMinutes}min")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send sleep data: ${e.message}")
            }
        }
    }

    // ── Notification helpers ─────────────────────────────────────────────────

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Vitals Monitoring",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps heart rate and SpO2 streaming to your phone."
        }
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Health Pilot")
            .setContentText("Streaming vitals to your phone…")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .build()
    }
}
