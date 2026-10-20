package com.example.notification_privacy

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationEventSanitizerTest {
    @Test
    fun `produces posted payload with allow-listed metadata only`() {
        val payload = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = "com.example.chat",
            eventKey = "0|com.example.chat|42|null|10123",
            category = "msg",
            postedAt = 1_700_000_000_000L,
            hasText = true,
            isGroupSummary = false,
            salt = "test-salt",
        )

        assertNotNull(payload)
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
            payload!!.keys,
        )
        assertEquals("posted", payload["type"])
        assertEquals("com.example.chat", payload["package"])
        assertEquals("msg", payload["category"])
        assertEquals(1_700_000_000_000L, payload["postedAt"])
        assertEquals(true, payload["hasText"])
        assertEquals(false, payload["isGroupSummary"])
        assertTrue((payload["eventId"] as String).isNotBlank())
        assertNotEquals("0|com.example.chat|42|null|10123", payload["eventId"])
        assertFalse(payload.values.any { it is String && it.contains("Secret title") })
        assertFalse(payload.values.any { it is String && it.contains("Secret body") })
    }

    @Test
    fun `produces removed payload and correlates the hashed event id`() {
        val posted = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = "com.example.mail",
            eventKey = "notification-key",
            category = null,
            postedAt = 1_700_000_000_000L,
            hasText = false,
            isGroupSummary = true,
            salt = "stable-salt",
        )!!
        val removed = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Removed,
            packageName = "com.example.mail",
            eventKey = "notification-key",
            category = null,
            postedAt = 1_700_000_001_000L,
            hasText = false,
            isGroupSummary = true,
            salt = "stable-salt",
        )!!

        assertEquals("removed", removed["type"])
        assertEquals(posted["eventId"], removed["eventId"])
        assertEquals(null, removed["category"])
    }

    @Test
    fun `hashes different event keys differently`() {
        fun eventId(key: String): String = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = "com.example.chat",
            eventKey = key,
            category = null,
            postedAt = 1,
            hasText = false,
            isGroupSummary = false,
            salt = "salt",
        )!!["eventId"] as String

        assertNotEquals(eventId("key-a"), eventId("key-b"))
    }

    @Test
    fun `rejects missing package and trims unsafe category length`() {
        assertNull(
            NotificationEventSanitizer.sanitize(
                type = NotificationEventType.Posted,
                packageName = "  ",
                eventKey = "key",
                category = null,
                postedAt = 1,
                hasText = false,
                isGroupSummary = false,
            ),
        )

        val payload = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = "com.example.chat",
            eventKey = "key",
            category = "x".repeat(65),
            postedAt = 1,
            hasText = false,
            isGroupSummary = false,
        )!!

        assertNull(payload["category"])
    }

    @Test
    fun `fills a safe timestamp when metadata is incomplete`() {
        val payload = NotificationEventSanitizer.sanitize(
            type = NotificationEventType.Posted,
            packageName = "com.example.chat",
            eventKey = null,
            category = null,
            postedAt = -1,
            hasText = false,
            isGroupSummary = false,
        )!!

        assertTrue((payload["postedAt"] as Long) > 0)
        assertTrue((payload["eventId"] as String).isNotBlank())
    }
}
