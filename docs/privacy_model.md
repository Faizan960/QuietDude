# Privacy model

Quietdude is designed local-first. It has no backend, no account system, no
analytics, and no advertising SDK.

## Data stored on the device

The SQLite database created by Drift stores only rule configuration:

- Rule id, user-visible name, enabled flag, and priority.
- Condition definitions. Currently: time window bounds, foreground app package
  name, and a wearable-nearby condition kind.
- Action definitions. Currently: hide previews, silence notifications, dismiss
  notifications, and discreet alert.
- Created and updated timestamps.

Storage location: the application support directory resolved by
`path_provider`, in `quietdude.sqlite`. Android backup is disabled
(`android:allowBackup="false"`).

Users can delete rules from the Rules screen. Uninstalling the app removes the
local database.

## Notification observation

Quietdude can observe notifications only after the user grants Android's
notification-listener special access. Observation is in-memory and limited to
allow-listed metadata:

- Event type (`posted` or `removed`).
- Posting package name.
- A process-salted, truncated hash of the notification key.
- Notification category, when present (at most 64 characters).
- Posting timestamp.
- Whether title/text/big-text/sub-text keys were present (`hasText`).
- Whether the notification is a group summary.

Title, body, text, sender, people, conversation/group identifiers, raw keys,
bitmaps, and raw extras are not copied into the event model. `hasText` checks for
key presence; it does not read the text value.

Events and connection changes are delivered only while Flutter is listening.
They are not queued to disk, inserted into Drift, logged, or sent over the
network. Connection-status payloads contain only `connected` or `disconnected`.
The Home screen may display the latest package/type/time and rule match until the
app process is replaced or another event arrives. The raw notification object is
not retained. A process restart resets the in-memory latest event; no event is
replayed from a queue or database.

Keyword matching, preview rewriting, dismissal, and interruption-filter changes
are deferred. If transient text processing is added later, it must remain in
memory for the shortest practical duration, must never be logged or persisted,
and must never appear in error messages or crash reports.

Quietdude cannot promise that notifications are blocked before they appear.
Android and iOS impose limits, and the UI must say what actually happened.

## Data explicitly excluded

- No server, cloud sync, Firebase, or remote API.
- No accounts, identity, email, or phone numbers.
- No analytics, crash-reporting SDK with content payloads, or advertising.
- No notification bodies, message history, or contact address books.
- No continuous location history. Future geofence rules should store rule
  definitions, not a movement trail.
- No BLE scan history or advertising identifiers. Only a user-selected wearable
  label may be stored for a proximity rule.
- No API keys, signing secrets, or personal data in source control.

## Permissions

See [permissions.md](permissions.md). The app requests no permissions at launch.
Notification-listener access is special access that the user grants in system
settings after an in-app explanation. It can be revoked at any time; the app
remains usable when denied.

## Logging

`DiagnosticLogger` emits structured events under the `quietdude.*` logger scope.
Logs may include non-content metadata such as a rule id, operation name, or a
malformed-event marker. They must not include notification text, package history,
contact names, phone numbers, exact locations, message content, or raw platform
payloads. Repository warnings use rule ids only. The platform adapter logs the
failed operation, not the payload, and maps notification-stream errors to a
content-free typed exception. The Kotlin listener writes no notification content
to Logcat.

## Network

The main app manifest has no network permission or endpoint; the debug manifest
adds `INTERNET` only for Flutter tooling. If a future feature needs network
access, it requires an explicit privacy review, a clear opt-in, and documentation
of what leaves the device. Notification content must remain excluded by default.

## Threat model and limits

- A notification listener is a broad Android privilege. Malicious or compromised
  device software, accessibility abuse, or rooted devices are outside the app's
  control.
- Rule configuration reveals something about user habits (for example, chosen app
  packages or quiet hours). It stays local and is excluded from Android backup.
- The screen itself can expose content through screenshots or shoulder surfing.
  Blocking screenshots for sensitive screens is a future consideration.
- Local data is not encrypted at rest beyond OS-level storage protections. If
  threat modeling requires database encryption, evaluate SQLCipher deliberately
  rather than assuming SQLite is encrypted.
- Platform capability reports describe what was detected, not a guarantee that an
  action will always succeed.

## Privacy review checklist for new features

1. What data is accessed, and is it necessary?
2. Where does it go, and how long is it retained?
3. Can the feature work with less data or an on-device-only design?
4. Are logs free of content and identifiers?
5. Is the permission explained before it is requested?
6. Does the UI state partial or unsupported behavior honestly?
7. Are new database columns and platform permissions reflected in these docs?
