package com.example.notification_privacy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Android entry point for Quietdude.
 *
 * No notification, location, or Bluetooth runtime permissions are requested
 * here. Notification access remains user-granted special access, and post-arrival
 * dismissal stays behind the narrow native bridge in [PlatformBridge].
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformBridge.register(flutterEngine, this)
    }
}
