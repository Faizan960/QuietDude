package com.example.notification_privacy

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Notification listener with allow-listed observation and a narrow, opt-in
 * post-arrival dismissal path. Android owns this service's lifecycle; it is not
 * a foreground service and must never be started directly.
 *
 * Each callback extracts allow-listed metadata immediately and drops the
 * StatusBarNotification reference. Raw keys are retained only in the bounded,
 * expiring process-local dismissal store. Notification text is never copied,
 * logged, or persisted.
 */
class QuietdudeNotificationListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        NotificationDismissalRegistry.attach(this)
        NotificationListenerEventBus.setConnected(true)
    }

    override fun onListenerDisconnected() {
        NotificationListenerEventBus.setConnected(false)
        NotificationDismissalRegistry.detach(this)
        NotificationDismissalRegistry.clear()
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        NotificationListenerEventBus.setConnected(false)
        NotificationDismissalRegistry.detach(this)
        NotificationDismissalRegistry.clear()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        publish(NotificationEventType.Posted, sbn)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        publish(NotificationEventType.Removed, sbn)
    }

    private fun publish(type: NotificationEventType, sbn: StatusBarNotification?) {
        if (sbn == null) {
            return
        }
        val event = NotificationMetadataExtractor.extract(type, sbn) ?: return
        val eventId = event["eventId"] as? String
        val packageName = event["package"] as? String
        val postedAt = (event["postedAt"] as? Number)?.toLong()
        if (eventId != null && packageName != null && postedAt != null) {
            when (type) {
                NotificationEventType.Posted -> {
                    val rawKey = sbn.key
                    if (rawKey != null && NotificationListenerEventBus.hasEventSink) {
                        NotificationDismissalRegistry.store.record(
                            eventId = eventId,
                            rawKey = rawKey,
                            packageName = packageName,
                            postTime = postedAt,
                        )
                    }
                }
                NotificationEventType.Removed ->
                    NotificationDismissalRegistry.store.remove(eventId, postedAt)
            }
        }
        NotificationListenerEventBus.emit(event)
    }
}
