package com.example.notification_privacy

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationAccessEvaluatorTest {
    private val packageName = "com.example.notification_privacy"
    private val serviceName =
        "com.example.notification_privacy.QuietdudeNotificationListenerService"

    @Test
    fun `matches shorthand service component`() {
        assertTrue(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = "$packageName/.QuietdudeNotificationListenerService",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
    }

    @Test
    fun `matches fully qualified component among multiple entries`() {
        assertTrue(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners =
                    "com.other.app/.Listener:$packageName/com.example.notification_privacy.QuietdudeNotificationListenerService",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
    }

    @Test
    fun `rejects another package or service`() {
        assertFalse(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = "com.other.app/.Listener",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
        assertFalse(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = "$packageName/.OtherListener",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
    }

    @Test
    fun `handles missing, blank, and malformed values`() {
        assertFalse(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = null,
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
        assertFalse(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = "  ",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
        assertFalse(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = "$packageName/",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
        assertFalse(
            NotificationAccessEvaluator.isEnabled(
                enabledListeners = "not-a-component",
                applicationPackage = packageName,
                serviceClassName = serviceName,
            ),
        )
    }
}
