package com.example.notification_privacy

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Minimal, read-only bridge used to prove Flutter <-> Kotlin communication.
 *
 * Enforcement is deliberately unimplemented. Capability responses must never
 * imply that Quietdude can already suppress or rewrite notifications.
 */
class PlatformBridge(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.example.notification_privacy/platform"

        fun register(engine: FlutterEngine, activity: Activity) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(PlatformBridge(activity))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(capabilities())
            "checkPermission" -> {
                val permission = call.argument<String>("permission")
                result.success(checkPermission(permission))
            }
            "openSettings" -> {
                val permission = call.argument<String>("permission")
                result.success(openSettings(permission))
            }
            "submitEnforcementRequest" -> result.success(
                mapOf(
                    "status" to "unsupported",
                    "message" to "Notification enforcement is not implemented in this build.",
                ),
            )
            else -> result.notImplemented()
        }
    }

    private fun capabilities(): List<Map<String, Any?>> {
        val listenerGranted = isNotificationListenerGranted()
        val dndGranted = isDoNotDisturbAccessGranted()
        return listOf(
            capability(
                id = "notification_listener",
                status = if (listenerGranted) "scaffolded" else "requires_permission",
                detail = if (listenerGranted) {
                    "Notification access is granted, but the listener service is not implemented yet."
                } else {
                    "Notification access has not been granted. No notification content is read."
                },
            ),
            capability(
                id = "preview_redaction",
                status = "scaffolded",
                detail = "Requires notification access. Preview rewriting is not implemented yet.",
            ),
            capability(
                id = "do_not_disturb_control",
                status = if (dndGranted) "scaffolded" else "requires_permission",
                detail = "Interruption-filter control is not implemented and would require user authorization.",
            ),
            capability(
                id = "notification_dismissal",
                status = "requires_permission",
                detail = "Dismissal depends on notification access and Android version limits.",
            ),
            capability(
                id = "keyword_filtering",
                status = "scaffolded",
                detail = "Only possible where the operating system exposes notification text.",
            ),
            capability(
                id = "discreet_alerts",
                status = "planned",
                detail = "Urgency-based discreet alerts are not implemented.",
            ),
            capability(
                id = "geofence_events",
                status = "planned",
                detail = "Native geofencing is not implemented; no location permission is requested.",
            ),
            capability(
                id = "wearable_proximity",
                status = "planned",
                detail = "BLE proximity is not implemented; no Bluetooth permission is requested.",
            ),
        )
    }

    private fun capability(id: String, status: String, detail: String) = mapOf(
        "id" to id,
        "status" to status,
        "detail" to detail,
    )

    private fun isNotificationListenerGranted(): Boolean {
        val enabled = Settings.Secure.getString(
            activity.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return enabled.split(":").any { component ->
            component.startsWith(activity.packageName)
        }
    }

    private fun isDoNotDisturbAccessGranted(): Boolean {
        val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.isNotificationPolicyAccessGranted
    }

    private fun checkPermission(permission: String?): Map<String, Any?> = when (permission) {
        "notification_listener" -> mapOf(
            "state" to if (isNotificationListenerGranted()) "granted" else "denied",
        )
        "do_not_disturb_access" -> mapOf(
            "state" to if (isDoNotDisturbAccessGranted()) "granted" else "denied",
        )
        "location", "bluetooth" -> mapOf("state" to "not_applicable")
        else -> mapOf("state" to "unknown")
    }

    private fun openSettings(permission: String?): Boolean {
        val intent = when (permission) {
            "notification_listener" -> Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            "do_not_disturb_access" -> Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            else -> return false
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
