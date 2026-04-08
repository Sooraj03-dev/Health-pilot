package com.healthpilot.health_pilot

import android.content.Intent
import android.os.Bundle
import androidx.wear.activity.ConfirmationActivity
import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * Minimal Wear OS launcher activity.
 * Starts [VitalsService] as a foreground service, shows a brief
 * confirmation animation, then finishes itself — the service keeps running.
 */
class MainActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d("WearMain", "Starting VitalsService…")

        val serviceIntent = Intent(this, VitalsService::class.java)
        startForegroundService(serviceIntent)

        // Close the activity after a short delay; service keeps streaming.
        Handler(Looper.getMainLooper()).postDelayed({ finish() }, 500)
    }
}
