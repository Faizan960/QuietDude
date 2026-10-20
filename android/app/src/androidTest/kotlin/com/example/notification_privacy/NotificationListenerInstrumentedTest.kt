package com.example.notification_privacy

import android.content.ComponentName
import android.provider.Settings
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NotificationListenerInstrumentedTest {
    @Test
    fun accessEvaluatorMatchesCurrentSystemListenerConfiguration() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        )
        val serviceClassName =
            QuietdudeNotificationListenerService::class.java.name
        val expected = enabled
            ?.split(':')
            ?.mapNotNull(ComponentName::unflattenFromString)
            ?.any { component ->
                component.packageName == context.packageName &&
                    component.className == serviceClassName
            } ?: false

        val actual = NotificationAccessEvaluator.isEnabled(
            enabledListeners = enabled,
            applicationPackage = context.packageName,
            serviceClassName = serviceClassName,
        )

        assertEquals(expected, actual)
    }

    @Test
    fun sanitizerForwardsOnlyAllowListedMetadata() {
        val event = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = "com.example.chat",
            eventKey = "synthetic-raw-key",
            category = "msg",
            postedAt = 1700000000000,
            hasText = true,
            isGroupSummary = false,
            salt = "instrumented-test-salt",
        )

        assertEquals(
            setOf(
                "type",
                "package",
                "eventId",
                "category",
                "postedAt",
                "hasText",
                "isGroupSummary",
            ),
            event?.keys,
        )
        assertEquals("posted", event?.get("type"))
        assertEquals("com.example.chat", event?.get("package"))
        assertEquals("msg", event?.get("category"))
        assertEquals(1700000000000L, event?.get("postedAt"))
        assertEquals(true, event?.get("hasText"))
        assertEquals(false, event?.get("isGroupSummary"))
        assertFalse(event?.containsKey("title") ?: true)
        assertFalse(event?.containsKey("body") ?: true)
        assertFalse(event?.containsKey("text") ?: true)
        assertTrue(event?.get("eventId") is String)
    }

    @Test
    fun sanitizerHandlesRemovedEventsAndMissingMetadata() {
        val removed = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Removed,
            packageName = "com.example.mail",
            eventKey = null,
            category = null,
            postedAt = 1700000000000,
            hasText = false,
            isGroupSummary = true,
            salt = "instrumented-test-salt",
        )
        val missingPackage = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = null,
            eventKey = "synthetic-raw-key",
            category = null,
            postedAt = null,
            hasText = false,
            isGroupSummary = false,
        )

        assertEquals("removed", removed?.get("type"))
        assertNull(removed?.get("category"))
        assertEquals(true, removed?.get("isGroupSummary"))
        assertNull(missingPackage)
    }
}
