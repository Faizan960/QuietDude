package com.example.notification_privacy

import android.app.Notification
import android.service.notification.StatusBarNotification
import java.security.MessageDigest
import java.util.UUID

enum class NotificationEventType(val wireName: String) {
    Posted("posted"),
    Removed("removed"),
}

/**
 * Converts Android notification objects into the small, allow-listed metadata
 * payload that is sent to Flutter.
 *
 * Title, body, subtext, conversation content, people, and raw notification keys
 * are intentionally never copied into the payload. The raw key is hashed with a
 * process-local salt so posted/removed events can be correlated for the lifetime
 * of this process without exposing the key.
 */
object NotificationEventSanitizer {
    private val processSalt: String = UUID.randomUUID().toString()

    fun sanitize(
        type: NotificationEventType,
        packageName: String?,
        eventKey: String?,
        category: String?,
        postedAt: Long?,
        hasText: Boolean,
        isGroupSummary: Boolean,
        salt: String = processSalt,
    ): Map<String, Any?>? {
        val safePackage = packageName?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        val timestamp = postedAt?.takeIf { it > 0 } ?: System.currentTimeMillis()
        val safeCategory = category
            ?.trim()
            ?.takeIf { it.isNotEmpty() && it.length <= MAX_CATEGORY_LENGTH }

        return linkedMapOf(
            "type" to type.wireName,
            "package" to safePackage,
            "eventId" to hashEventKey(eventKey, salt),
            "category" to safeCategory,
            "postedAt" to timestamp,
            "hasText" to hasText,
            "isGroupSummary" to isGroupSummary,
        )
    }

    private fun hashEventKey(eventKey: String?, salt: String): String {
        val material = "$salt:${eventKey ?: UUID.randomUUID().toString()}"
        val digest = MessageDigest.getInstance("SHA-256").digest(material.toByteArray())
        return digest.take(EVENT_ID_BYTES).joinToString("") { byte ->
            "%02x".format(byte.toInt() and 0xff)
        }
    }

    private const val MAX_CATEGORY_LENGTH = 64
    private const val EVENT_ID_BYTES = 16
}

object NotificationMetadataExtractor {
    fun extract(
        type: NotificationEventType,
        statusBarNotification: StatusBarNotification?,
    ): Map<String, Any?>? {
        if (statusBarNotification == null) {
            return null
        }

        return try {
            val notification = statusBarNotification.notification ?: return null
            val extras = notification.extras
            val hasText = extras != null && (
                extras.containsKey(Notification.EXTRA_TITLE) ||
                    extras.containsKey(Notification.EXTRA_TEXT) ||
                    extras.containsKey(Notification.EXTRA_BIG_TEXT) ||
                    extras.containsKey(Notification.EXTRA_SUB_TEXT)
                )
            val isGroupSummary =
                notification.flags and Notification.FLAG_GROUP_SUMMARY != 0

            NotificationEventSanitizer.sanitize(
                type = type,
                packageName = statusBarNotification.packageName,
                eventKey = statusBarNotification.key,
                category = notification.category,
                postedAt = statusBarNotification.postTime,
                hasText = hasText,
                isGroupSummary = isGroupSummary,
            )
        } catch (_: Exception) {
            // Malformed or vendor-specific notification extras must not crash
            // the listener or leak content into diagnostics.
            null
        }
    }
}
