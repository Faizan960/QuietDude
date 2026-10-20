package com.example.notification_privacy

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LaunchableAppCatalogTest {
    @Test
    fun `excludes self, deduplicates packages, and sorts predictably`() {
        val apps = LaunchableAppCatalog.normalize(
            entries = listOf(
                entry("com.example.zebra", "Zebra"),
                entry("com.example.quietdude", "Quietdude"),
                entry("com.example.alpha", "alpha"),
                entry("com.example.alpha", "Duplicate"),
                entry("", "Empty"),
            ),
            excludedPackage = "com.example.quietdude",
        )

        assertEquals(
            listOf("com.example.alpha", "com.example.zebra"),
            apps.map { it.packageName },
        )
        assertEquals(listOf("alpha", "Zebra"), apps.map { it.label })
        assertFalse(apps.any { it.packageName == "com.example.quietdude" })
    }

    @Test
    fun `falls back to package name and caps labels`() {
        val apps = LaunchableAppCatalog.normalize(
            entries = listOf(
                entry("com.example.chat", "   "),
                entry("com.example.news", "n".repeat(200)),
            ),
            excludedPackage = null,
        )

        assertEquals("com.example.chat", apps.first().label)
        assertTrue(apps.last().label.length <= 120)
    }

    private fun entry(packageName: String, label: String): LaunchableAppEntry {
        return LaunchableAppEntry(
            packageName = packageName,
            label = label,
            iconPng = null,
        )
    }
}
