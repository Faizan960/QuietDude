# Android native integration plan

This document records the intended Android implementation path. Only the
capability bridge exists today; no enforcement service is registered.

## Current scaffold

- `MainActivity` is a Flutter activity written in Kotlin.
- `PlatformBridge` registers the method channel
  `com.example.notification_privacy/platform`.
- Supported methods: `getCapabilities`, `checkPermission`, `openSettings`, and
  `submitEnforcementRequest`.
- `submitEnforcementRequest` returns `unsupported`. No state is changed.
- The manifest declares no permissions and no services.
- The app does not request access at startup. `openSettings` is invoked only by an
  explicit future user action.

## Notification access

Planned shape:

1. Add `QuietdudeNotificationListener : NotificationListenerService`.
2. Declare it in the manifest with
   `android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"`
   and the `android.service.notification.NotificationListenerService` intent
   filter. Do not export it.
3. Check access through `Settings.Secure.enabled_notification_listeners` or by
   binding, and report `permission_required` when absent.
4. Open `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` only after an in-app
   explanation.
5. Process `StatusBarNotification` metadata in memory. Never persist title, text,
   sender, or conversation content.
6. For preview redaction, use supported notification update paths. Do not claim
   that a notification can always be prevented from appearing.
7. Report per-action outcomes: applied, partially applied, unsupported,
   permission required, failed, or not applicable.

Constraints:

- Notification access is broad special access and can be revoked.
- Group summaries, foreground services, media notifications, and OEM behavior
  vary.
- Dismissal uses notification keys and may fail for protected or already
  dismissed notifications.
- Do not add an AccessibilityService for notification interception.

## Do Not Disturb / interruption filters

- Check `NotificationManager.isNotificationPolicyAccessGranted`.
- Request access via `Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`.
- Never enable DND silently. Apply only a user-authored rule action.
- Snapshot the previous `interruptionFilter`, restore it when a rule no longer
  applies, and report restoration failures.
- Verify behavior across Android versions and OEMs before labeling it
  implemented.

## Runtime permissions and settings flows

- Add permissions only with the corresponding feature and manifest entry.
- Use `ActivityCompat.requestPermissions`/the Activity Result API for runtime
  permissions and `Intent` actions for special access.
- Explain rationale before each flow and handle denial, permanent denial, and
  revocation.
- Keep `docs/permissions.md` synchronized with every manifest change.

## Location and geofencing

- Not implemented and no location package installed.
- Preferred approach: a small native boundary using `GeofencingClient` (Google
  Play services) or `LocationManager`, after a compatibility spike.
- Requires explicit foreground location permission; background location requires
  a separate, justified user flow on recent Android.
- Register geofences with a `PendingIntent`; evaluate rules when a transition
  arrives. Store rule definitions, not location history.
- Handle reboot, permission revocation, and background limits.

## BLE wearable proximity

- `flutter_blue_plus` is installed but not called.
- Add Android 12+ `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` runtime permissions (and
  legacy permissions/location for older versions) only when the feature ships.
- Prefer scanning for a known service/device identifier and stopping promptly.
- Do not use scan results for advertising or store scan history. Store only the
  user-selected wearable label.
- The proximity signal should feed `RuleContext.wearableNearby`; evaluation stays
  in Dart.

## Scheduling

- Time-based rules can be evaluated when the app is active.
- For deferrable background work, evaluate WorkManager first.
- Use AlarmManager exact alarms only if a product requirement cannot tolerate
  deferral, and only with the correct special access and policy justification.

## Native execution-status reporting

Extend `PlatformBridge` with a structured request/response:

```text
submitEnforcementRequest(ruleId, actions) ->
  { status, appliedActions, skippedActions, message }
```

The Kotlin layer must report the actual OS result, including partial success and
permission errors. The Dart `RuleExecutionResult` mirrors that shape; the UI must
display the reported status rather than assuming a match equals success.

## Manifest additions checklist

| Feature | Manifest change | User flow |
|---|---|---|
| Notification listener | Service + binding permission + intent filter | Notification access settings |
| DND control | None beyond existing manager API | Policy access settings |
| Own notifications | `POST_NOTIFICATIONS` (Android 13+) | Runtime prompt |
| Location | Fine/coarse, optionally background location | Runtime + settings |
| BLE | `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` (legacy on older) | Nearby-devices prompt |
| Contacts | `READ_CONTACTS` only if unavoidable | Runtime prompt |
| Scheduling | WorkManager or exact-alarm permission if justified | Possibly special access |

## Testing

- Add instrumentation or Robolectric tests where they can validate Android
  behavior without a device.
- Manual test matrix must include permission granted/denied/revoked, notification
  group summaries, OEM-specific DND behavior, reboot, and process death.
- Never mark a capability implemented solely because a method call returned.
