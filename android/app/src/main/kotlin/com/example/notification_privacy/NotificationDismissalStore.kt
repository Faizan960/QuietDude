package com.example.notification_privacy

data class NotificationDismissalTarget(
    val eventId: String,
    val rawKey: String,
    val packageName: String,
    val postTime: Long,
    val recordedAt: Long,
)

/**
 * Process-local mapping from sanitized event IDs to raw notification keys.
 *
 * Raw keys never cross the Flutter bridge, are never persisted or logged, and
 * expire quickly. The map is bounded so a noisy notification stream cannot
 * grow memory without limit.
 */
class NotificationDismissalStore(
    private val maxEntries: Int = 256,
    private val maxAgeMillis: Long = 5 * 60 * 1000,
    private val now: () -> Long = System::currentTimeMillis,
) {
    private val entries = object : LinkedHashMap<String, NotificationDismissalTarget>(
       16,
        0.75f,
       true,
    ) {
        override fun removeEldestEntry(
            eldest: MutableMap.MutableEntry<String, NotificationDismissalTarget>?,
        ): Boolean = size > maxEntries
    }

    @Synchronized
    fun record(
        eventId: String,
        rawKey: String,
        packageName: String,
        postTime: Long,
    ) {
        if (eventId.isEmpty() || rawKey.isEmpty() || packageName.isEmpty() || postTime <= 0) {
            return
        }
        entries[eventId] = NotificationDismissalTarget(
            eventId = eventId,
            rawKey = rawKey,
            packageName = packageName,
            postTime = postTime,
            recordedAt = now(),
        )
    }

    @Synchronized
    fun remove(eventId: String, postTime: Long): Boolean {
        val target = entries[eventId] ?: return false
        if (target.postTime != postTime) {
            return false
        }
        entries.remove(eventId)
        return true
    }

    @Synchronized
    fun find(eventId: String, expectedPackage: String): NotificationDismissalTarget? {
        val target = entries[eventId] ?: return null
        if (now() - target.recordedAt >= maxAgeMillis) {
            entries.remove(eventId)
            return null
        }
        if (target.packageName != expectedPackage) {
            return null
        }
        return target
    }

    @Synchronized
    fun clear() {
        entries.clear()
    }

    @Synchronized
    fun size(): Int = entries.size
}

object NotificationDismissalRegistry {
    val store = NotificationDismissalStore()

    @Volatile
    var activeService: QuietdudeNotificationListenerService? = null
        private set

    fun attach(service: QuietdudeNotificationListenerService) {
        activeService = service
    }

    fun detach(service: QuietdudeNotificationListenerService) {
        if (activeService === service) {
            activeService = null
        }
    }

    fun clear() {
        store.clear()
    }

    fun dismiss(eventId: String, expectedPackage: String): Map<String, Any?> {
        val service = activeService
        if (service == null || !NotificationListenerEventBus.isConnected) {
            return result("listener_unavailable", "Notification access is not active.")
        }
        val target = store.find(eventId, expectedPackage)
            ?: return result("event_unavailable", "The notification is no longer available.")
        val activeKey = findActiveKey(service, target)
            ?: run {
                store.remove(eventId, target.postTime)
                return result("event_unavailable", "The notification is no longer available.")
            }
        return try {
            service.cancelNotification(activeKey)
            store.remove(eventId, target.postTime)
            result("requested", null)
        } catch (_: Exception) {
            result("failed", "Android rejected the dismissal request.")
        }
    }

    private fun findActiveKey(
        service: QuietdudeNotificationListenerService,
        target: NotificationDismissalTarget,
    ): String? {
        return try {
            service.activeNotifications?.firstOrNull { notification ->
                notification.key == target.rawKey &&
                    notification.packageName == target.packageName &&
                    notification.postTime == target.postTime
            }?.key
        } catch (_: Exception) {
            null
        }
    }

    private fun result(status: String, message: String?): Map<String, Any?> {
        return mapOf(
            "status" to status,
            "message" to message,
        )
    }
}
