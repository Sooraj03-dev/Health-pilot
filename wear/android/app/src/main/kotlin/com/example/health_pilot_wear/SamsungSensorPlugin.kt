package com.example.health_pilot_wear

import android.content.Context
import android.util.Log
import android.os.Handler
import android.os.Looper
import com.samsung.android.service.health.tracking.*
import com.samsung.android.service.health.tracking.data.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class SamsungSensorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private var healthTrackingService: HealthTrackingService? = null
    private var hrTracker: HealthTracker? = null
    private var spo2Tracker: HealthTracker? = null
    private var pendingResult: Result? = null
    private var latestHR: Int? = null
    private var latestSpO2: Int? = null
    private lateinit var context: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        context = binding.applicationContext
        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "health_pilot/sensor"
        )
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startScan" -> {
                pendingResult = result
                latestHR = null
                latestSpO2 = null
                connectAndScan()
            }
            "stopScan" -> {
                stopTracking()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun connectAndScan() {
        val listener = object : ConnectionListener {
            override fun onConnectionSuccess() {
                startHRTracking()
            }
            override fun onConnectionEnded() {
                val res = pendingResult
                pendingResult = null
                res?.error("DISCONNECTED", "Service ended", null)
            }
            override fun onConnectionFailed(e: HealthTrackerException) {
                val res = pendingResult
                pendingResult = null
                res?.error("CONNECTION_FAILED", e.message, null)
            }
        }

        healthTrackingService = HealthTrackingService(listener, context)
        healthTrackingService?.connectService()
    }

    private fun startHRTracking() {
        Log.d("HealthPilot", "Starting HR track...")
        hrTracker = healthTrackingService?.getHealthTracker(HealthTrackerType.HEART_RATE)

        hrTracker?.setEventListener(
            object : HealthTracker.TrackerEventListener {
                override fun onDataReceived(dataPoints: List<DataPoint>) {
                    dataPoints.lastOrNull()?.let { dp ->
                        val hr = dp.getValue(ValueKey.HeartRateSet.HEART_RATE)
                        if (hr > 0) {
                            latestHR = hr
                            Log.d("HealthPilot", "HR captured: $hr. Switching to SpO2...")
                            
                            // Stop HR to free up PPG sensor for SpO2
                            hrTracker?.unsetEventListener()
                            mainHandler.post { startSpO2Tracking() }
                        }
                    }
                }
                override fun onFlushCompleted() {}
                override fun onError(error: HealthTracker.TrackerError) {
                    val res = pendingResult
                    pendingResult = null
                    res?.error("HR_ERROR", error.name, null)
                    stopTracking()
                }
            }
        )
    }

    private fun startSpO2Tracking() {
        Log.d("HealthPilot", "Starting SpO2 track...")
        spo2Tracker = healthTrackingService?.getHealthTracker(HealthTrackerType.SPO2)

        spo2Tracker?.setEventListener(
            object : HealthTracker.TrackerEventListener {
                override fun onDataReceived(dataPoints: List<DataPoint>) {
                    dataPoints.lastOrNull()?.let { dp ->
                        val spo2 = dp.getValue(ValueKey.SpO2Set.SPO2)
                        val status = dp.getValue(ValueKey.SpO2Set.STATUS)
                        
                        // Status 0 usually means measurement successful/stable
                        if (spo2 > 0 && status == 0) {
                            latestSpO2 = spo2
                            checkAndReturn()
                        } else {
                            Log.d("HealthPilot", "SpO2 measuring... current: $spo2 (status: $status)")
                        }
                    }
                }
                override fun onFlushCompleted() {}
                override fun onError(error: HealthTracker.TrackerError) {
                    val res = pendingResult
                    pendingResult = null
                    res?.error("SPO2_ERROR", error.name, null)
                    stopTracking()
                }
            }
        )
    }

    private fun checkAndReturn() {
        val h = latestHR
        val s = latestSpO2
        val res = pendingResult

        if (h != null && s != null && res != null) {
            Log.d("HealthPilot", "Scan complete. HR: $h, SpO2: $s")
            res.success(mapOf("heart_rate" to h, "spo2" to s))
            pendingResult = null
            stopTracking()
        }
    }

    private fun stopTracking() {
        try {
            hrTracker?.unsetEventListener()
            spo2Tracker?.unsetEventListener()
            healthTrackingService?.disconnectService()
        } catch (e: Exception) {
            Log.e("HealthPilot", "Stop tracking error: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        stopTracking()
        methodChannel.setMethodCallHandler(null)
    }
}
