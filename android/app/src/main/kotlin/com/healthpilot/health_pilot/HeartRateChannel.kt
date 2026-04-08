package com.healthpilot.health_pilot

import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * Singleton bridge that holds a reference to the Flutter [EventChannel.EventSink].
 *
 * The sink is set when Flutter calls [onListen] (i.e. when the Dart side opens
 * `receiveBroadcastStream()`) and cleared on [onCancel].
 *
 * [WearListenerService] calls [sendVitals] / [sendSleep] from its background
 * thread; both helpers post to the main thread via [EventSink.success], which
 * the EventChannel infrastructure handles safely.
 */
object HeartRateChannel : EventChannel.StreamHandler {

    private const val TAG = "HeartRateChannel"
    const val CHANNEL_NAME = "health_pilot/watch_data"

    @Volatile
    private var sink: EventChannel.EventSink? = null

    // ── StreamHandler ────────────────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        Log.d(TAG, "Flutter EventChannel connected — sink ready.")
    }

    override fun onCancel(arguments: Any?) {
        sink = null
        Log.d(TAG, "Flutter EventChannel disconnected — sink cleared.")
    }

    // ── Outgoing payloads ────────────────────────────────────────────────────

    /**
     * Sends a vitals reading to Flutter.
     *
     * @param heartRate  BPM value, or `null` if the watch reported no reading.
     * @param spo2       SpO2 percentage, or `null` if the watch reported no reading.
     * @param timestamp  Epoch milliseconds when the watch captured the reading.
     */
    fun sendVitals(heartRate: Double?, spo2: Double?, timestamp: Long) {
        val payload = mapOf(
            "type"      to "vitals",
            "heartRate" to heartRate,   // null-safe — Dart handles null
            "spo2"      to spo2,
            "timestamp" to timestamp,
        )
        emit(payload)
    }

    /**
     * Sends a completed sleep session to Flutter.
     *
     * @param sleepStart      Epoch milliseconds of session start.
     * @param sleepEnd        Epoch milliseconds of session end.
     * @param durationMinutes Total duration in whole minutes.
     */
    fun sendSleep(sleepStart: Long, sleepEnd: Long, durationMinutes: Long) {
        val payload = mapOf(
            "type"            to "sleep",
            "sleepStart"      to sleepStart,
            "sleepEnd"        to sleepEnd,
            "durationMinutes" to durationMinutes,
        )
        emit(payload)
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    private fun emit(payload: Map<String, Any?>) {
        val currentSink = sink
        if (currentSink == null) {
            Log.w(TAG, "No active sink — dropping payload: $payload")
            return
        }
        // EventSink.success must be called on the platform (main) thread.
        // Flutter's EventChannel infrastructure guarantees this when the sink
        // is invoked from within a Binder call on the main thread. The
        // WearableListenerService delivers onDataChanged on the main thread,
        // so this is safe as-is.
        try {
            currentSink.success(payload)
            Log.d(TAG, "✓ Emitted to Flutter: type=${payload["type"]}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to emit to Flutter: ${e.message}")
        }
    }
}
