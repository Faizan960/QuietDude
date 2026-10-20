# Notification listener foundation

Quietdude observes Android notification lifecycle events through a
`NotificationListenerService`. This milestone provides permission handling,
sanitized observation, and in-memory rule evaluation only. It does not hide,
silence, dismiss, or rewrite notifications.

## Components

| Component | Responsibility |
|---|---|
| `QuietdudeNotificationListenerService` | Receives Android listener callbacks and immediately extracts allow-listed metadata. |
| `NotificationMetadataExtractor` | Defensively reads package, category, post time, text-key presence, and group-summary flag from `StatusBarNotification`. |
| `NotificationEventSanitizer` | Produces the Flutter payload, hashes the raw key, and drops absent/invalid metadata. |
| `NotificationListenerEventBus` | Process-local, sink-only event and connection-status delivery to Flutter. No queue and no storage. |
| `PlatformBridge` | MethodChannel operations plus the `platform_events` and `listener_status_events` EventChannels. |
| `AndroidPlatformAdapter` | Parses typed listener status, connection changes, and sanitized events; converts bridge failures into conservative states. |
| `NotificationObservationService` | Evaluates posted events against the existing rule engine and builds a plan without submitting it. |

The notification listener runs in the normal app process. It is not a foreground
service and must never be started directly; Android binds it after the user
grants notification access.

## Android manifest

```xml
<service
    android:name=".QuietdudeNotificationListenerService"
    android:exported="true"
    android:label="Quietdude notification access"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService"/>
    </intent-filter>
</service>
```

`android.permission.BIND_NOTIFICATION_LISTENER_SERVICE` is a signature-level
binding permission held by the system. It is not a runtime permission and is not
listed in `<uses-permission>`. The service is exported so the system can bind it,
but the binding permission prevents ordinary apps from doing so.

## Permission flow

1. The UI reads `Settings.Secure.enabled_notification_listeners`.
2. Each colon-separated component is parsed and matched against the exact app
   package and listener service class, including Android's shorthand
   `package/.Service` form.
3. Status is reported as `granted`, `not_granted`, `unsupported`, or `error`.
4. The user opens `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` from an
   explicit button. Opening the screen does not grant access and does not change
   the local status.
5. On `AppLifecycleState.resumed`, Quietdude re-reads access and capabilities, so
   returning from system settings refreshes the UI.
6. The native listener publishes a connection-status change on a separate EventChannel.
   Flutter re-queries access and capabilities when the status changes, while the app
   is running, without polling system settings. A bound listener is treated as
   proof of access during the brief period in which the settings read can lag a
   live regrant. One bounded reconciliation query runs shortly after each
   connection transition to pick up the settled access value; this is not a
   periodic poll.

No permission is requested at launch.

## Service lifecycle

- `onListenerConnected`: mark the listener connected and publish a status change.
- `onListenerDisconnected`: mark the listener disconnected and publish a status
  change.
- `onNotificationPosted`: sanitize a posted event.
- `onNotificationRemoved`: sanitize a removed event.
- `onDestroy`: clear the connected flag and publish a disconnect if the state
  changed.

Repeated `connected` or `disconnected` callbacks are idempotent; the status bus
does not emit duplicate transitions. Connection changes use
`com.example.notification_privacy/listener_status_events` with the payload
`{"connection": "connected"}` or `{"connection": "disconnected"}`. This stream
contains no access result and no notification metadata. The Dart adapter treats
unknown or malformed status payloads as no event, and a status-stream error only
logs a safe operation marker; access status still comes from an explicit query.

The raw `StatusBarNotification` reference is not retained. Callbacks return
quickly after extracting a fixed set of scalar values. Events and status changes
are only delivered while Flutter has an attached sink. There is no queue, so an
event emitted while the app is not listening is discarded.

## Foreground, background, and process restart

- App backgrounding does not mean the listener disconnected. Android owns the
  service lifecycle and may keep it connected. Flutter visibility and listener
  availability are separate states.
- On app resume, Quietdude re-queries listener access and capabilities. Opening
  system settings never changes the local state optimistically.
- A fresh process starts with `isConnected = false` in native memory. No
  connection claim is stored in Drift. The status query returns the current
  access and connection values, and the listener can reconnect when Android
  binds it.
- The latest observation is in-memory only. It resets after process death; it is
  not replayed from a queue or database. Rules remain intact because they are
  stored separately in SQLite.
- Android may restore listener binding after a reboot through the normal
  listener mechanism. Quietdude does not use a boot receiver or start the
  listener itself.

## Event payload

Flutter receives maps with this allow-listed schema:

```json
{
  "type": "posted",
  "package": "com.example.chat",
  "eventId": "3f2a... (32 hex characters)",
  "category": "msg",
  "postedAt": 1700000000000,
  "hasText": true,
  "isGroupSummary": false
}
```

| Field | Meaning |
|---|---|
| `type` | `posted` or `removed`. |
| `package` | Package that posted the notification. |
| `eventId` | Truncated SHA-256 of the raw notification key plus a process-local random salt. It allows posted/removed correlation in one process without exposing the key. |
| `category` | Android category when present and at most 64 characters; otherwise `null`. |
| `postedAt` | Epoch milliseconds from the notification, or the current time if absent/invalid. |
| `hasText` | Whether title/text/big-text/sub-text keys were present. Values are not read. |
| `isGroupSummary` | Whether the notification has `FLAG_GROUP_SUMMARY`. |

The payload contains no title, body, text, sender, people list, conversation
title, raw key, bitmap, or raw extras. `SanitizedNotificationEvent` in Dart has no
field for content.

## Rule evaluation boundary

`lastNotificationObservationProvider` maps posted events into
`NotificationObservationService`. The service builds a `RuleContext` with:

- `now = event.postedAt.toLocal()`
- `notificationSourcePackage = event.packageName`

The event timestamp crosses the bridge as an epoch instant. Time-window rules
deliberately evaluate the corresponding local wall-clock time, not the UTC fields
of that instant. A notification posted at 23:30 local time therefore matches a
23:00-23:59 rule regardless of the device's offset from UTC.

App-scoped conditions use `notificationSourcePackage` when present, otherwise
`foregroundAppPackage`. Evaluation uses the existing deterministic priority
policy and returns an `ExecutionPlan`, but nothing is submitted to the platform.
Removed events are observed but not evaluated. Enforcement remains
`unsupported` on the native bridge.

## Time-window semantics

`TimeWindow` uses minutes from local midnight and has these established rules:

- `startMinute` is inclusive; `endMinute` is exclusive.
- A same-day window such as 09:00-17:00 includes 09:00 and excludes 17:00.
- If `startMinute > endMinute`, the window crosses midnight. For example,
  22:00-06:00 includes 22:00 through 05:59.
- Equal endpoints retain the existing compatibility behavior: the window covers
  the entire day. Existing stored rules are not reinterpreted.
- Values outside 0-1439 are rejected. The current rule editor does not create
  time-window rules, but the domain model and database mapping support them.

Dart's built-in `DateTime` exposes only UTC or the device's local zone. Quietdude
does not add a named-time-zone dependency, so rules cannot pin an arbitrary IANA
zone. Evaluation uses the device-local wall clock and therefore follows the
device's timezone and daylight-saving rules. During a spring-forward gap a local
time that does not exist cannot be represented; during a fall-back repeated hour
both occurrences map to the same local minute range. Tests inject explicit
`DateTime` values and do not depend on the machine's current time, but arbitrary
named-zone and DST transition simulation is not available without a timezone
package. This is a documented limitation, not an unstated rule semantic.

## Privacy and retention

- Event sinks are memory-only and receive events only while Flutter is listening.
- Events are not queued, persisted in Drift, written to files, or sent over the
  network.
- No notification content is logged. Dart diagnostics only record operation
  failures and malformed payload counts, never fields.
- The database schema is unchanged; no content columns exist.
- Event IDs use a salt that is regenerated on each app process start.
- Access can be revoked at any time; the app remains usable with denied access.

## Platform limitations

- Notification extras are controlled by the posting app and can be missing,
  sparse, custom, or encrypted. Quietdude does not assume text exists.
- `hasText` is a key-presence signal, not a content guarantee.
- Category values are app-defined; Quietdude only passes a bounded string.
- Group summaries are exposed as a boolean. Conversation/group identifiers and
  people data are deliberately excluded.
- Work-profile notifications, bubbles, media sessions, and OEM skins can vary.
- Android may reconnect or disconnect the listener independently.
- iOS exposes no API for observing other apps' notifications; the iOS adapter
  continues to report `unsupported`.
- Android versions and OEM skins differ in notification-listener settings UI,
  rebinding timing, and notification metadata. A physical-device/OEM matrix is
  still required before calling observation production-ready.

## Automated coverage

- Kotlin JVM tests cover allow-list sanitization, hashed event IDs, posted/removed
  classification, component matching, status-change idempotence, sink teardown,
  and closed-sink safety.
- Flutter tests cover typed status, connection-event parsing, malformed payloads,
  safe stream errors, concurrent listeners, cancellation, re-subscription,
  fresh status refreshes after connection changes, lifecycle refresh, time-window
  boundaries, local wall-clock evaluation, and invalid time-window configuration.
- Android instrumentation tests run on a connected device/emulator. They compare
  the access evaluator with the real `Settings.Secure` value using Android's
  `ComponentName` parser, and verify the allow-listed payload on-device. They do
  not grant notification access automatically.
- Instrumentation tests require an emulator/device and the Android test runner;
  they do not replace the manual grant/revoke/service-rebind flow.

## Manual verification

1. Install and launch the debug APK.
2. Confirm Home/Settings report access not granted when access is off.
3. Open notification access settings, enable Quietdude, and return.
4. Confirm Home/Settings report access granted and listener connected.
5. Post a test notification; confirm Home shows the package, type, and text-key
   presence without any title/body.
6. Remove the notification; confirm a removed event is observed.
7. Background and foreground the app; confirm the status and latest event remain
   consistent and no duplicate observation appears.
8. Revoke access while the app is running or backgrounded, return/resume, and
   confirm the denied state is shown.
9. Grant access again, return/resume, and confirm Android rebinds the listener
   without reinstalling.
10. Search logcat for the test title/body; confirm neither appears in app-process
    logs.
11. Force-stop, relaunch, and confirm rules remain stored while the latest
    in-memory event resets.
12. If practical, reboot the emulator/device and confirm Android restores the
    listener binding after access remains granted.
13. Record the actual API level. Do not claim system-settings authorization can
    be automated; it is a manual system-UI step.

## Deferred to the enforcement milestone

- Preview redaction or blocking.
- Notification dismissal.
- Do Not Disturb / interruption-filter changes.
- Keyword matching against notification text.
- Urgency exceptions, contact rules, and BLE/geofence inputs.

