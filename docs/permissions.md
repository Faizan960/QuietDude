# Permissions and special access

Quietdude requests **no permissions at launch**. The scaffold only reads whether
notification access and Do Not Disturb policy access are already granted. It
never opens a permission prompt automatically.

Sensitive access must be explained in context before the system flow is opened,
and the user must take the final action.

## Current state

| Access | Requested now? | Implemented now? | User-visible action now? |
|---|---|---|---|
| Notification listener access | No | No | No |
| Do Not Disturb access | No | No | No |
| Notifications (`POST_NOTIFICATIONS`) | No | No | No |
| Location | No | No | No |
| Bluetooth | No | No | No |
| Contacts | No | No | No |
| Internet | No | No | No |

`flutter_blue_plus` is installed but unused, and its Android manifest declares no
Bluetooth permissions. The app manifest currently declares no permissions.

## Planned accesses

### Notification listener access (Android)

- **Why:** Read notification metadata (and, where exposed, text) to apply
  redaction, silence, dismissal, or keyword rules.
- **When:** Only when the user enables a rule that needs notification access.
- **Manifest additions (future):**
  - `<service android:name=".QuietdudeNotificationListener" android:exported="false" android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">`
  - `<intent-filter><action android:name="android.service.notification.NotificationListenerService" /></intent-filter>`
  - `<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />`
    is not a normal permission; the service declaration uses the system binding
    permission. Notification access is granted as special access.
- **User action:** Open `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` and
  enable Quietdude. Access can be revoked at any time.
- **Caveat:** Access is broad. Quietdude must not log or persist notification
  bodies or contact details. Some apps cannot be intercepted, and content may be
  missing or encrypted.

### Do Not Disturb / interruption filter access (Android)

- **Why:** Apply a user-approved silence action for a matching rule.
- **When:** Only when a rule includes the silence action and the user opts in.
- **Manifest additions:** None for policy access itself. The app uses
  `NotificationManager.setInterruptionFilter`.
- **User action:** Open `Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS` and
  grant access. The user must be able to revoke it.
- **Caveat:** Do not silently enable DND or leave it on after a rule expires.
  Restore the previous filter and surface failures. OEMs and Android versions
  behave differently.

### Notifications (Android 13+)

- **Why:** Only if Quietdude later shows its own notifications (for example, an
  alert or foreground-service indicator).
- **Manifest addition:** `android.permission.POST_NOTIFICATIONS`.
- **User action:** Runtime permission prompt, only when the feature is used.
- **Caveat:** This permission does not grant access to other apps' notifications.

### Location (future geofencing)

- **Why:** Evaluate a location condition. The scaffold does not include location.
- **Manifest additions (candidate):** `ACCESS_COARSE_LOCATION`,
  `ACCESS_FINE_LOCATION`, and, only if justified, `ACCESS_BACKGROUND_LOCATION`.
  Add `ACCESS_BACKGROUND_LOCATION` separately and explain the background impact.
- **User action:** Runtime permission; background location requires a dedicated
  settings flow on recent Android versions.
- **Caveat:** Geofencing background behavior is restricted by Doze, OEM policies,
  and Android 12+ background location rules. Prefer a native implementation or a
  verified library after a compatibility spike.

### Bluetooth (future BLE proximity)

- **Why:** Detect whether a paired wearable is nearby without tracking location.
- **Manifest additions (candidate, Android 12+):**
  `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, with `android:usesPermissionFlags="neverForLocation"`
  where scanning is not used for location. Android 11 and older require
  `BLUETOOTH`/`BLUETOOTH_ADMIN` and may require location permission for scans.
- **User action:** Nearby-devices runtime permission when the user enables
  wearable proximity. iOS shows a Bluetooth usage prompt.
- **Caveat:** Scanning consumes battery and can expose device identifiers. Store
  only the user-selected wearable label, never a scan history.
- **iOS Info.plist (future):** `NSBluetoothAlwaysUsageDescription`.

### Contacts and conversations (not planned in this phase)

- **Why:** A future rule could target a selected contact or conversation.
- **Manifest additions:** `READ_CONTACTS` if direct contact lookup becomes
  necessary.
- **User action:** Runtime permission, with an in-app explanation.
- **Caveat:** Avoid uploading, logging, or storing address-book data. Prefer
  user-selected identifiers and minimize scope.

### Scheduling (future)

- **Why:** Time-based rules that must fire while the app is backgrounded.
- **Manifest additions:** Possibly none for WorkManager; `SCHEDULE_EXACT_ALARM`
  or `USE_EXACT_ALARM` only if exact timing is required and policy-compliant.
- **User action:** Exact-alarm special access on some Android versions.
- **Caveat:** Prefer inexact/deferrable work first; evaluate WorkManager before
  adding exact alarm access.

## iOS permissions (future implementation)

Only supported permissions may be requested, with usage descriptions in
`Info.plist`:

- Location: `NSLocationWhenInUseUsageDescription` (and background variants only
  if a justified background feature exists).
- Bluetooth: `NSBluetoothAlwaysUsageDescription`.
- Local notifications: user authorization for Quietdude's own notifications.

iOS has no permission that grants cross-app notification inspection. Do not add a
permission flow that implies otherwise.

## Rules for implementation

1. Explain the benefit in plain language before opening system settings.
2. Request access only from the feature that needs it, never during startup.
3. Check authorization every time before acting; users can revoke access.
4. Handle denial and "don't ask again" states without claiming success.
5. Do not log sensitive permission-adjacent data.
6. Keep the permission matrix in this document current.
