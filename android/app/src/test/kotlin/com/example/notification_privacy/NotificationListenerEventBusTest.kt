package com.example.notification_privacy

import io.flutter.plugin.common.EventChannel
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class NotificationListenerEventBusTest {
    private class RecordingSink(
        private val throwOnSuccess: Boolean = false,
    ) : EventChannel.EventSink {
        val events = mutableListOf<Any?>()

        override fun success(event: Any?) {
            if (throwOnSuccess) {
                throw IllegalStateException("sink closed")
            }
            events.add(event)
        }

        override fun error(
            errorCode: String,
            errorMessage: String?,
            errorDetails: Any?,
        ) {
            throw AssertionError("Unexpected error callback")
        }

        override fun endOfStream() = Unit
    }

    @Before
    fun resetBus() {
        NotificationListenerEventBus.detachCurrent()
        NotificationListenerEventBus.detachCurrentStatus()
        NotificationListenerEventBus.setConnected(false)
    }

    @After
    fun leaveDisconnected() {
        NotificationListenerEventBus.detachCurrent()
        NotificationListenerEventBus.detachCurrentStatus()
        NotificationListenerEventBus.setConnected(false)
    }

    @Test
    fun `connection changes are typed and emitted once`() {
        val sink = RecordingSink()
        NotificationListenerEventBus.attachStatus(sink)

        NotificationListenerEventBus.setConnected(true)
        NotificationListenerEventBus.setConnected(true)
        NotificationListenerEventBus.setConnected(false)
        NotificationListenerEventBus.setConnected(false)

        assertFalse(NotificationListenerEventBus.isConnected)
        assertEquals(
            listOf(
                mapOf("connection" to "connected"),
                mapOf("connection" to "disconnected"),
            ),
            sink.events,
        )
    }

    @Test
    fun `events are emitted only while a sink is attached`() {
        val sink = RecordingSink()
        val event = mapOf("type" to "posted", "package" to "com.example.chat")

        NotificationListenerEventBus.emit(event)
        assertFalse(NotificationListenerEventBus.hasEventSink)
        NotificationListenerEventBus.attach(sink)
        assertTrue(NotificationListenerEventBus.hasEventSink)
        NotificationListenerEventBus.emit(event)
        NotificationListenerEventBus.detachCurrent()
        assertFalse(NotificationListenerEventBus.hasEventSink)
        NotificationListenerEventBus.emit(event)

        assertEquals(listOf(event), sink.events)
    }

    @Test
    fun `closed sinks do not crash the listener`() {
        NotificationListenerEventBus.attach(RecordingSink(throwOnSuccess = true))
        NotificationListenerEventBus.attachStatus(
            RecordingSink(throwOnSuccess = true),
        )

        NotificationListenerEventBus.emit(mapOf("type" to "posted"))
        NotificationListenerEventBus.setConnected(true)
        NotificationListenerEventBus.setConnected(false)

        assertFalse(NotificationListenerEventBus.isConnected)
    }

    @Test
    fun `status sink cannot be mistaken for the notification event sink`() {
        val notificationSink = RecordingSink()
        val statusSink = RecordingSink()

        NotificationListenerEventBus.attach(notificationSink)
        NotificationListenerEventBus.attachStatus(statusSink)
        NotificationListenerEventBus.emit(mapOf("type" to "removed"))
        NotificationListenerEventBus.setConnected(true)

        assertTrue(
            notificationSink.events.single() is Map<*, *> &&
                (notificationSink.events.single() as Map<*, *>)["type"] == "removed",
        )
        assertEquals(
            listOf(mapOf("connection" to "connected")),
            statusSink.events,
        )
    }
}
