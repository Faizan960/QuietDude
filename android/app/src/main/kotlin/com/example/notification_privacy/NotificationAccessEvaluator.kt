package com.example.notification_privacy

/**
 * Matches the component entries Android stores in
 * `Settings.Secure.enabled_notification_listeners`.
 *
 * This is deliberately pure Kotlin so the matching rules can be unit tested
 * without an Android device. Android may store either a shorthand class name
 * (`package/.Service`) or a fully qualified component.
 */
object NotificationAccessEvaluator {
    fun isEnabled(
        enabledListeners: String?,
        applicationPackage: String,
        serviceClassName: String,
    ): Boolean {
        if (enabledListeners.isNullOrBlank()) {
            return false
        }
        return enabledListeners.split(':').any { component ->
            matchesComponent(component, applicationPackage, serviceClassName)
        }
    }

    private fun matchesComponent(
        component: String,
        applicationPackage: String,
        serviceClassName: String,
    ): Boolean {
        val trimmed = component.trim()
        val separator = trimmed.indexOf('/')
        if (separator <= 0 || separator == trimmed.lastIndex) {
            return false
        }

        val packageName = trimmed.substring(0, separator)
        val rawClassName = trimmed.substring(separator + 1)
        val className = when {
            rawClassName.startsWith('.') -> packageName + rawClassName
            !rawClassName.contains('.') -> "$packageName.$rawClassName"
            else -> rawClassName
        }

        return packageName == applicationPackage && className == serviceClassName
    }
}
