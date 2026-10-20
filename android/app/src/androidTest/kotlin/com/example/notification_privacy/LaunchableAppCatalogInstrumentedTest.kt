package com.example.notification_privacy

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Locale

@RunWith(AndroidJUnit4::class)
class LaunchableAppCatalogInstrumentedTest {
    @Test
    fun queryExcludesSelfAndReturnsSortedVisibleApps() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val apps = LaunchableAppCatalog.query(context)

        assertFalse(apps.any { it.packageName == context.packageName })
        assertTrue(apps.all { it.packageName.isNotBlank() && it.label.isNotBlank() })
        assertEquals(
            apps.sortedWith(
                compareBy(
                    { it.label.lowercase(Locale.ROOT) },
                    { it.packageName },
                ),
            ),
            apps,
        )
    }
}
