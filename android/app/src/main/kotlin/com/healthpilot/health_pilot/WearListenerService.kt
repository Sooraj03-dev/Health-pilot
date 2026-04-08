package com.healthpilot.health_pilot

import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

/**
 * WearListenerService — phone-side receiver for Data Layer events sent by
 * the Wear OS [VitalsService].
 *
 * Routes:
 *   /vitals  → [HeartRateChannel.sendVitals] (heart rate + SpO2)
 *   /sleep   → [HeartRateChannel.sendSleep]  (completed sleep session)
 *
 * Converts the -1.0 sentinel values back to null before forwarding to Flutter,
 * so Dart code never has to know about the sentinel.
 *
 * Must be registered in AndroidManifest.xml with the DATA_CHANGED intent filter.
 */
class WearListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "WearListenerService"

        private const val PATH_VITALS  = "/vitals"
        private const val PATH_SLEEP   = "/sleep"
        private const val NULL_SENTINEL = -1.0
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        dataEvents.use { buffer ->
            buffer.forEach { event ->
                // We only care about new/changed data, not deletions.
                if (event.type != DataEvent.TYPE_CHANGED) return@forEach

                val path = event.dataItem.uri.path ?: return@forEach
                Log.d(TAG, "Data Layer event received on path: $path")

                when (path) {
                    PATH_VITALS -> handleVitals(event)
                    PATH_SLEEP  -> handleSleep(event)
                    else        -> Log.w(TAG, "Unknown path — ignoring: $path")
                }
            }
        }
    }

    // ── Route handlers ───────────────────────────────────────────────────────

    private fun handleVitals(event: DataEvent) {
        try {
            val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap

            val rawHr   = dataMap.getDouble("heartRate",  NULL_SENTINEL)
            val rawSpo2 = dataMap.getDouble("spo2",       NULL_SENTINEL)
            val ts      = dataMap.getLong("timestamp", System.currentTimeMillis())

            // Restore -1.0 sentinel → null  so Flutter gets a proper null
            val heartRate: Double? = if (rawHr   == NULL_SENTINEL) null else rawHr
            val spo2:      Double? = if (rawSpo2 == NULL_SENTINEL) null else rawSpo2

            Log.d(TAG, "Vitals → HR=$heartRate  SpO2=$spo2  ts=$ts")
            HeartRateChannel.sendVitals(heartRate, spo2, ts)

        } catch (e: Exception) {
            Log.e(TAG, "Error parsing vitals DataMap: ${e.message}")
        }
    }

    private fun handleSleep(event: DataEvent) {
        try {
            val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap

            val sleepStart      = dataMap.getLong("sleepStart")
            val sleepEnd        = dataMap.getLong("sleepEnd")
            val durationMinutes = dataMap.getLong("durationMinutes")

            Log.d(TAG, "Sleep → start=$sleepStart  end=$sleepEnd  dur=${durationMinutes}min")
            HeartRateChannel.sendSleep(sleepStart, sleepEnd, durationMinutes)

        } catch (e: Exception) {
            Log.e(TAG, "Error parsing sleep DataMap: ${e.message}")
        }
    }
}
