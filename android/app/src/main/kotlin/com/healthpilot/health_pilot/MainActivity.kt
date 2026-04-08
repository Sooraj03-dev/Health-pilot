package com.healthpilot.health_pilot

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the EventChannel that bridges Wear OS Data Layer → Flutter.
        // HeartRateChannel holds the EventSink reference and is called by
        // WearListenerService whenever the watch sends new data.
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HeartRateChannel.CHANNEL_NAME,
        ).setStreamHandler(HeartRateChannel)
    }
}
