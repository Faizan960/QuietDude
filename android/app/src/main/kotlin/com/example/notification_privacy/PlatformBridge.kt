package com.example.notification_privacy

import android.app.Activity
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Capability, observation, app-catalog, and narrow dismissal bridge.
 *
 * Preview rewriting remains unsupported. Dismissal is post-arrival, best-effort,
 * and only accepts opaque event IDs; raw notification keys never cross the
 * bridge.
 */
class PlatformBridge(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.example.notification_privacy/platform"
        const val EVENT_CHANNEL = "com.example.notification_privacy/platform_events"
        const val STATUS_EVENT_CHANNEL =
            "com.example.notification_privacy/listener_status_events"

        fun register(engine: FlutterEngine, activity: Activity) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(PlatformBridge(activity))
            EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(
                    object : EventChannel.StreamHandler {
                        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                            if (events != null) {
                                NotificationListenerEventBus.attach(events)
                            }
                        }

                        override fun onCancel(arguments: Any?) {
                            NotificationListenerEventBus.detachCurrent()
                        }
                    },
                )
            EventChannel(engine.dartExecutor.binaryMessenger, STATUS_EVENT_CHANNEL)
                .setStreamHandler(
                    object : EventChannel.StreamHandler {
                        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                            if (events != null) {
                                NotificationListenerEventBus.attachStatus(events)
                            }
                        }

                        override fun onCancel(arguments: Any?) {
                            NotificationListenerEventBus.detachCurrentStatus()
                        }
                    },
                )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(capabilities())
            "checkPermission" -> {
                val permission = call.argument<String>("permission")
                result.success(checkPermission(permission))
            }
            "getNotificationListenerStatus" -> result.success(listenerStatus())
            "openNotificationListenerSettings" ->
                result.success(openNotificationListenerSettings())
            "openSettings" -> {
                val permission = call.argument<String>("permission")
                result.success(openSettings(permission))
            }
            "submitEnforcementRequest" -> result.success(
                mapOf(
                    "status" to "unsupported",
                    "message" to "Notifications cannot be modified before display.",
                ),
            )
            "getLaunchableApps" -> result.success(launchableApps())
            "requestNotificationDismissal" -> {
                val eventId = call.argument<String>("eventId")?.trim()
                val packageName = call.argument<String>("package")?.trim()
                if (eventId.isNullOrEmpty() || packageName.isNullOrEmpty()) {
                    result.success(
                        mapOf(
                            "status" to "failed",
                            "message" to "Invalid dismissal request.",
                        ),
                    )
                } else {
                    result.success(
                        NotificationDismissalRegistry.dismiss(eventId, packageName),
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun launchableApps(): Map<String, Any?> {
        return try {
            val apps = LaunchableAppCatalog.query(activity).map { app ->
                mapOf(
                    "package" to app.packageName,
                    "label" to app.label,
                    "icon" to app.iconPng,
                )
            }
            mapOf(
                "status" to "ok",
                "apps" to apps,
            )
        } catch (_: Exception) {
            mapOf(
                "status" to "error",
                "message" to "The app list could not be loaded.",
            )
        }
    }

    private fun capabilities(): List<Map<String, Any?>> {
        val (listenerAccess, listenerConnected) = listenerSnapshot()
        val dndGranted = isDoNotDisturbAccessGranted()
        return listOf(
            capability(
                id = "notification_listener",
                status = when {
                    listenerAccess == "granted" && listenerConnected -> "implemented"
                    listenerAccess == "granted" -> "unavailable"
                    listenerAccess == "not_granted" -> "requires_permission"
                    listenerAccess == "unsupported" -> "unsupported"
                    else -> "unavailable"
                },
                detail = when {
                    listenerAccess == "granted" && listenerConnected ->
                        "Notification listener connected. Reads allow-listed metadata only; " +
                            "explicit app-targeted dismissal is reported separately."
                    listenerAccess == "granted" ->
                        "Notification access is granted, but the listener is not connected. " +
                            "Android may reconnect it when needed."
                    listenerAccess == "not_granted" ->
                        "Notification access has not been granted. No notification content is read."
                    listenerAccess == "unsupported" ->
                        "Notification listener access is not available on this device."
                    else ->
                        "Notification access status could not be determined."
                },
            ),
            capability(
                id = "preview_redaction",
                status = "unsupported",
                detail = "Android does not provide a supported cross-app preview rewrite API.",
            ),
            capability(
                id = "do_not_disturb_control",
                status = if (dndGranted) "scaffolded" else "requires_permission",
                detail = "Interruption-filter control is not implemented and would require user authorization.",
            ),
            capability(
                id = "notification_dismissal",
                status = when {
                    listenerAccess == "granted" &&
                        listenerConnected &&
                        NotificationDismissalRegistry.activeService != null ->
                        "partially_supported"
                    listenerAccess == "granted" -> "unavailable"
                    listenerAccess == "not_granted" -> "requires_permission"
                    listenerAccess == "unsupported" -> "unsupported"
                    else -> "unavailable"
                },
                detail = when {
                    listenerAccess == "granted" &&
                        listenerConnected &&
                        NotificationDismissalRegistry.activeService != null ->
                        "Post-arrival dismissal is best-effort. The notification may " +
                            "appear briefly, alert, or remain on another device."
                    listenerAccess == "granted" ->
                        "Notification access is granted, but the listener is disconnected."
                    listenerAccess == "not_granted" ->
                        "Notification access is required to dismiss after arrival."
                    listenerAccess == "unsupported" ->
                        "Notification dismissal is not available on this device."
                    else -> "Notification dismissal status could not be determined."
                },
            ),
            capability(
                id = "keyword_filtering",
                status = "scaffolded",
                detail = "Only metadata observation is implemented; text filtering is not.",
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

    private fun listenerStatus(): Map<String, Any?> {
        val (access, connected) = listenerSnapshot()
        val connection = when {
            access != "granted" -> "unavailable"
            connected -> "connected"
            else -> "disconnected"
        }
        return mapOf(
            "access" to access,
            "connection" to connection,
        )
    }

    /**
     * A bound listener is proof that access is granted. During a live regrant,
     * the settings provider can briefly lag behind the service binding, so the
     * connection state wins until the next explicit query.
     */
    private fun listenerSnapshot(): Pair<String, Boolean> {
        val connected = NotificationListenerEventBus.isConnected
        val access = if (connected) "granted" else notificationAccessState()
        return access to connected
    }

    private fun notificationAccessState(): String {
        return try {
            val enabled = Settings.Secure.getString(
                activity.contentResolver,
                "enabled_notification_listeners",
            )
            if (
                NotificationAccessEvaluator.isEnabled(
                    enabledListeners = enabled,
                    applicationPackage = activity.packageName,
                    serviceClassName = QuietdudeNotificationListenerService::class.java.name,
                )
            ) {
                "granted"
            } else {
                "not_granted"
            }
        } catch (_: Exception) {
            "error"
        }
    }

    private fun isDoNotDisturbAccessGranted(): Boolean {
        return try {
            val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.isNotificationPolicyAccessGranted
        } catch (_: Exception) {
            false
        }
    }

    private fun checkPermission(permission: String?): Map<String, Any?> = when (permission) {
        "notification_listener" -> mapOf(
            "state" to when (listenerSnapshot().first) {
                "granted" -> "granted"
                "not_granted" -> "denied"
                "unsupported" -> "not_applicable"
                else -> "unknown"
            },
        )
        "do_not_disturb_access" -> mapOf(
            "state" to if (isDoNotDisturbAccessGranted()) "granted" else "denied",
        )
        "location", "bluetooth" -> mapOf("state" to "not_applicable")
        else -> mapOf("state" to "unknown")
    }

    private fun openSettings(permission: String?): Boolean = when (permission) {
        "notification_listener" -> openNotificationListenerSettings()
        "do_not_disturb_access" -> openSystemSettings(
            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS),
        )
        else -> false
    }

    private fun openNotificationListenerSettings(): Boolean {
        return openSystemSettings(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun openSystemSettings(intent: Intent): Boolean {
        return try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        } catch (_: Exception) {
            false
        }
    }
}
