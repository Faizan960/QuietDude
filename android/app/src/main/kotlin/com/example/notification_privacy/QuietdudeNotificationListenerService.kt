package com.example.notification_privacy

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Observation-only notification listener. Android owns this service's
 * lifecycle; it is not a foreground service and must never be started directly.
 *
 * Each callback extracts allow-listed metadata immediately and drops the
 * StatusBarNotification reference. Notification text is never copied, logged, or
 * persisted in this milestone.
 */
class QuietdudeNotificationListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        NotificationListenerEventBus.setConnected(true)
    }

    override fun onListenerDisconnected() {
        NotificationListenerEventBus.setConnected(false)
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        NotificationListenerEventBus.setConnected(false)
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
        NotificationListenerEventBus.emit(event)
    }
}
