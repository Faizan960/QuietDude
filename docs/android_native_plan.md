# Android native integration plan

This document records the Android implementation path. Notification observation
is implemented; enforcement is not.

## Implemented listener foundation

- `MainActivity` is a Flutter activity written in Kotlin.
- `PlatformBridge` registers the method channel
  `com.example.notification_privacy/platform`, the notification-event channel
  `com.example.notification_privacy/platform_events`, and the connection-status
  channel `com.example.notification_privacy/listener_status_events`.
- Methods: `getCapabilities`, `checkPermission`,
  `getNotificationListenerStatus`, `openNotificationListenerSettings`,
  `openSettings`, and `submitEnforcementRequest`.
- `submitEnforcementRequest` still returns `unsupported`. No state is changed.
- `QuietdudeNotificationListenerService` handles posted/removed events and
  connection changes.
- The manifest has one service declaration protected by
  `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`; it adds no
  `<uses-permission>` entries.
- The app does not request access at startup. Settings are opened only from an
  explicit user action.

## Notification access

Implemented:

1. `QuietdudeNotificationListenerService : NotificationListenerService`.
2. Manifest binding permission and listener intent filter; exported so the
   system can bind it, protected by the signature permission.
3. Access check by parsing `Settings.Secure.enabled_notification_listeners` and
   matching the app package plus exact service class.
4. Typed status: `granted`, `not_granted`, `unsupported`, `error`, plus
   `connected`/`disconnected`/`unavailable` connection state.
5. `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` opened only after an in-app
   explanation. Resume triggers a recheck.
6. Allow-listed metadata only: type, package, salted event-id hash, category,
   timestamp, `hasText`, and `isGroupSummary`. No title, body, sender, people, or
   conversation data.
7. In-memory event delivery through EventChannel. Events are never persisted or
   logged.
8. Domain evaluation of posted events without submitting enforcement.

Deferred:

1. Preview redaction or blocking.
2. Dismissal.
3. Interruption-filter changes.
4. Keyword/text matching.
5. Per-action outcome reporting once an action exists.

Constraints:

- Notification access is broad special access and can be revoked.
- Group summaries, foreground services, media notifications, and OEM behavior
  vary.
- `hasText` is key presence, not a guarantee of readable content.
- Notification categories are app-defined and bounded before forwarding.
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

- Kotlin JVM tests cover notification-access component parsing and event
  sanitization, including missing fields, content-free payload keys, hashed event
  IDs, posted/removed classification, status idempotence, and sink teardown.
- Flutter tests cover typed status/event parsing, connection changes, malformed
  payloads, safe stream errors, cancellation, re-subscription, fresh status
  refreshes, missing plugins, lifecycle refresh, and UI states.
- Android instrumentation tests compare access evaluation with the real
  `Settings.Secure` value and verify the payload allowlist on a connected
  device/emulator. Run `:app:connectedDebugAndroidTest` and record the API level.
- Real `StatusBarNotification`, service binding, permission grant/revoke, and
  Android rebinding require a device/emulator and are verified manually.
- Manual test matrix must include permission granted/denied/revoked/regranted,
  posted and removed events, background/foreground, process death, reboot,
  notification group summaries, and logcat content checks.
- Never mark a capability implemented solely because a method call returned.
