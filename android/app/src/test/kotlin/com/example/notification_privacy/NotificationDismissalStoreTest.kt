package com.example.notification_privacy

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationDismissalStoreTest {
    @Test
    fun `records only the exact package and rejects mismatches`() {
        val store = NotificationDismissalStore(now = { 1_000L })
        store.record(
            eventId = "event-1",
            rawKey = "0|com.example.chat|42|null|10123",
            packageName = "com.example.chat",
            postTime = 900L,
        )

        val target = store.find("event-1", "com.example.chat")

        assertEquals("0|com.example.chat|42|null|10123", target?.rawKey)
        assertEquals("com.example.chat", target?.packageName)
        assertEquals(900L, target?.postTime)
        assertNull(store.find("event-1", "com.example.mail"))
        assertNull(store.find("missing", "com.example.chat"))
    }

    @Test
    fun `removal is scoped to the same post time`() {
        val store = NotificationDismissalStore(now = { 1_000L })
        store.record("event-1", "raw-1", "com.example.chat", 900L)

        assertFalse(store.remove("event-1", 901L))
        assertEquals(1, store.size())
        assertTrue(store.remove("event-1", 900L))
        assertEquals(0, store.size())
        assertNull(store.find("event-1", "com.example.chat"))
    }

    @Test
    fun `expired mappings cannot be used`() {
        var now = 1_000L
        val store = NotificationDismissalStore(
            maxAgeMillis = 5_000L,
            now = { now },
        )
        store.record("event-1", "raw-1", "com.example.chat", 900L)

        now = 6_000L
        assertNull(store.find("event-1", "com.example.chat"))
        assertEquals(0, store.size())
    }

    @Test
    fun `clear and size bound discard native keys`() {
        val store = NotificationDismissalStore(maxEntries = 2, now = { 1_000L })
        store.record("event-1", "raw-1", "com.example.chat", 900L)
        store.record("event-2", "raw-2", "com.example.mail", 901L)
        store.record("event-3", "raw-3", "com.example.news", 902L)

        assertEquals(2, store.size())
        assertNull(store.find("event-1", "com.example.chat"))
        assertEquals(
            "raw-3",
            store.find("event-3", "com.example.news")?.rawKey,
        )

        store.clear()
        assertEquals(0, store.size())
    }
}
