package com.example.notification_privacy

import io.flutter.plugin.common.EventChannel

/**
 * Process-local bridge between the notification listener service and Flutter.
 *
 * Notification events and connection changes use separate sinks. Events and
 * status changes are only delivered while Flutter is listening. They are never
 * queued, persisted, or written to logs.
 */
object NotificationListenerEventBus {
    private val lock = Any()
    private var eventSink: EventChannel.EventSink? = null
    private var statusSink: EventChannel.EventSink? = null

    @Volatile
    var isConnected: Boolean = false
        private set

    fun attach(sink: EventChannel.EventSink) {
        synchronized(lock) {
            eventSink = sink
        }
    }

    fun attachStatus(sink: EventChannel.EventSink) {
        synchronized(lock) {
            statusSink = sink
        }
    }

    fun detachCurrent() {
        synchronized(lock) {
            eventSink = null
        }
    }

    fun detachCurrentStatus() {
        synchronized(lock) {
            statusSink = null
        }
    }

    fun setConnected(connected: Boolean) {
        val sink = synchronized(lock) {
            if (isConnected == connected) {
                return
            }
            isConnected = connected
            statusSink
        } ?: return
        try {
            sink.success(
                mapOf("connection" to if (connected) "connected" else "disconnected"),
            )
        } catch (_: Exception) {
            // The Flutter engine may be tearing down. Discard the status change.
        }
    }

    fun emit(event: Map<String, Any?>) {
        val sink = synchronized(lock) { eventSink } ?: return
        try {
            sink.success(event)
        } catch (_: Exception) {
            // The Flutter engine may be tearing down. Discard the event.
        }
    }
}
