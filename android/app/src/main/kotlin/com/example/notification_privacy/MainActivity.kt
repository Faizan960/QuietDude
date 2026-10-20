package com.example.notification_privacy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Provisional Android entry point for Quietdude.
 *
 * No notification, location, or Bluetooth permissions are requested here. The
 * only native surface exposed at scaffold time is the read-only capability
 * bridge in [PlatformBridge].
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformBridge.register(flutterEngine, this)
    }
}
