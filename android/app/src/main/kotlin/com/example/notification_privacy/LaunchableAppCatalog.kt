package com.example.notification_privacy

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream
import java.util.Locale

data class LaunchableAppEntry(
    val packageName: String,
    val label: String,
    val iconPng: ByteArray?,
)

/**
 * Lists launchable apps without QUERY_ALL_PACKAGES. The manifest query limits
 * visibility to activities that handle MAIN/LAUNCHER.
 */
object LaunchableAppCatalog {
    fun query(context: Context): List<LaunchableAppEntry> {
        val packageManager = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(intent, 0)
        }

        val entries = activities.mapNotNull { resolveInfo ->
            val packageName = resolveInfo.activityInfo?.packageName?.trim().orEmpty()
            if (packageName.isEmpty()) {
                return@mapNotNull null
            }
            val label = try {
                resolveInfo.loadLabel(packageManager).toString().trim()
            } catch (_: Exception) {
                ""
            }
            val icon = try {
                resolveInfo.loadIcon(packageManager)
            } catch (_: Exception) {
                null
            }
            LaunchableAppEntry(
                packageName = packageName,
                label = label.ifEmpty { packageName },
                iconPng = icon?.let(::drawableToPng),
            )
        }
        return normalize(entries, excludedPackage = context.packageName)
    }

    fun normalize(
        entries: Iterable<LaunchableAppEntry>,
        excludedPackage: String?,
    ): List<LaunchableAppEntry> {
        val byPackage = linkedMapOf<String, LaunchableAppEntry>()
        for (entry in entries) {
            val packageName = entry.packageName.trim()
            if (packageName.isEmpty() || packageName == excludedPackage) {
                continue
            }
            if (byPackage.containsKey(packageName)) {
                continue
            }
            val label = entry.label.trim().ifEmpty { packageName }.take(MAX_LABEL_LENGTH)
            byPackage[packageName] = entry.copy(packageName = packageName, label = label)
        }
        return byPackage.values.sortedWith(
            compareBy(
                { it.label.lowercase(Locale.ROOT) },
                { it.packageName },
            ),
        )
    }

    private fun drawableToPng(drawable: Drawable): ByteArray? {
        return try {
            val bitmap = Bitmap.createBitmap(ICON_SIZE, ICON_SIZE, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, ICON_SIZE, ICON_SIZE)
            drawable.draw(canvas)
            ByteArrayOutputStream().use { output ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                bitmap.recycle()
                output.toByteArray()
            }
        } catch (_: Exception) {
            null
        }
    }

    private const val ICON_SIZE = 96
    private const val MAX_LABEL_LENGTH = 120
}
