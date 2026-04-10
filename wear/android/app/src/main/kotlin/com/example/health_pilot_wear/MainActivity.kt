package com.example.health_pilot_wear

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(SamsungSensorPlugin())
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val permissions = mutableListOf(Manifest.permission.BODY_SENSORS)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                permissions.add(Manifest.permission.ACTIVITY_RECOGNITION)
            }
            
            val toRequest = permissions.filter { 
                checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED 
            }
            if (toRequest.isNotEmpty()) {
                requestPermissions(toRequest.toTypedArray(), 1001)
            }
        }
    }
}
