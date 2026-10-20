# Architecture

Quietdude separates configuration, evaluation, persistence, and enforcement so
that a matching rule never implies the operating system can execute it.

## Layers

```text
Flutter UI (features/)
    │ watches providers
    ▼
Application wiring (app/providers.dart)
    │
    ├── RuleRepository ──► Drift ──► local SQLite
    │
    ├── RuleEngine ──► RulePriorityPolicy ──► ExecutionPlan
    │                                      │
    └── PlatformAdapter ◄──────────────────┘
             │
             ├── AndroidPlatformAdapter ──► MethodChannel ──► Kotlin bridge
             │                             EventChannel ◄── listener events
             ├── IosPlatformAdapter (static, honest capability reporting)
             └── UnsupportedPlatformAdapter (desktop/web)
```

### UI (`lib/features`)

Home, Rules, Settings, and reusable capability widgets. Widgets read Riverpod
providers and call repository methods for mutations. They never issue SQL or
call platform channels directly.

### Application wiring (`lib/app`)

`main.dart` mounts `ProviderScope`. `app/providers.dart` chooses the platform
adapter, opens the database, exposes the rule stream, and constructs the engine
and enforcement service. `router.dart` owns `go_router` routes and `theme.dart`
owns the Material 3 theme.

### Domain (`lib/domain`)

Pure Dart. No Flutter widgets, Drift, or Android imports.

- `models/`: `PrivacyRule`, `RuleContext`, `RulePriority`, `RuleExecutionStatus`,
  `RuleExecutionResult`, `PlatformCapability`, `NotificationListenerStatus`,
  `SanitizedNotificationEvent`, `NotificationObservation`.
- `conditions/`: sealed `RuleCondition` variants and time-window semantics.
  Implemented: always, time window (including overnight), foreground app, and
  wearable-nearby flag. Time windows use local wall-clock fields, start-inclusive
  and end-exclusive bounds; equal endpoints retain all-day compatibility. See
  [notification_listener.md](notification_listener.md#time-window-semantics).
- `actions/`: sealed `RuleAction` variants. Implemented: hide previews, silence
  notifications, dismiss notifications, discreet alert. Each action maps to the
  platform capability it would require.
- `policy/`: `RulePriorityPolicy` resolves matching rules.
- `engine/`: `DefaultRuleEngine` evaluates rules and builds an `ExecutionPlan`.
  `NotificationObservationService` evaluates sanitized posted events in memory
  and never submits a plan. `RuleEnforcementService` submits a plan to a
  `PlatformAdapter` only when explicitly invoked; the app does not invoke it yet.

### Data (`lib/data`)

Drift defines three typed tables:

- `privacy_rules`: id, name, enabled, priority rank, created/updated timestamps.
- `rule_condition_rows`: rule id, typed kind, time-window bounds, or app package.
- `rule_action_rows`: rule id and typed action kind.

`DriftRuleRepository` maps rows to domain objects and keeps SQL behind the
`RuleRepository` interface. Foreign keys cascade on rule deletion. Condition and
action rows are replaced transactionally when a rule is updated. No notification
bodies, messages, or contact content have a column.

Schema extension path: add typed columns/tables for new condition or action
parameters, introduce a Drift schema version and migration, and extend the
repository mapping. Do not replace the schema with an opaque JSON blob.

### Platform (`lib/platform`)

`contracts/platform_adapter.dart` defines capability queries, permission checks,
listener status, settings access, notification-event streaming, connection-status
streaming, and enforcement submission. Results are typed and include `Applied`,
`Partially applied`, `Unsupported`, `Permission required`, `Failed`, and
`Not applicable`. `contracts/platform_channel.dart` wraps `MethodChannel` and two
`EventChannel`s so platform errors are typed.

The Android adapter parses native capability/status maps and sanitized events,
ignores malformed payloads, caches one event stream to avoid duplicate native
subscriptions, and returns conservative failure states if the bridge is
unavailable. Notification-stream errors become
a content-free `NotificationEventStreamException`. The iOS adapter reports
capabilities as unsupported or planned and returns an unsupported listener status
with empty event and connection streams. The desktop adapter reports planned
capabilities only.

## Rule evaluation and conflict resolution

1. Only enabled rules with at least one condition are candidates.
2. A rule matches when every condition matches the `RuleContext`.
3. Matching rules are sorted deterministically:
   1. higher `RulePriority` first,
   2. more conditions (more specific) first,
   3. more recently updated first,
   4. lexicographically smaller rule id last-resort tie-break.
4. The first rule wins and supplies the action set. Other matching rules are
   recorded as suppressed. This is intentionally winner-takes-all for the
   scaffold; action-level merging can be added later with an explicit policy.
5. `DefaultRuleEngine.buildPlan` returns an empty plan when nothing matches or
   the winner has no actions.
6. `RuleEnforcementService` submits the plan. The adapter, not the engine, decides
   whether the OS can execute it and reports the actual outcome.

## Android bridge

`MainActivity` registers `PlatformBridge` on
`com.example.notification_privacy/platform`, the notification-event EventChannel
on `com.example.notification_privacy/platform_events`, and the connection-status
EventChannel on `com.example.notification_privacy/listener_status_events`.
Methods:

- `getCapabilities`: returns read-only capability maps, including listener
  connection state.
- `checkPermission`: reports notification-listener and DND policy access.
- `getNotificationListenerStatus`: returns typed `access` and `connection`.
- `openNotificationListenerSettings`: opens notification-access settings.
- `openSettings`: opens the relevant Android settings screen only after a user
  action.
- `submitEnforcementRequest`: always returns `unsupported` in this build.

`QuietdudeNotificationListenerService` receives posted/removed callbacks and
updates connection state. Connection transitions are emitted once on the separate
status channel; notification events and status changes never share a payload.
The service is declared with
`android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`; no runtime permission or
unrelated manifest permission is added. Events are sanitized before crossing the
EventChannel and are never persisted. See
[notification_listener.md](notification_listener.md).

## Application lifecycle

`QuietdudeApp` observes app lifecycle changes. On resume it invalidates listener
status and capability providers so a return from Android settings reflects the
user's actual choice. It also listens to typed native connection transitions and
re-queries status/capabilities when the listener connects or disconnects without
polling. A single delayed reconciliation query follows each transition so a
settings write that settles just after the service binding/disconnect is
reflected. Flutter backgrounding is not treated as a listener disconnect;
Android owns that service lifecycle. A fresh process starts from native in-memory state
and a fresh query, not from persisted connection claims. Opening settings does
not optimistically alter state.

## Notification observation flow

```text
Android notification
  → NotificationListenerService callback
  → allow-listed metadata extraction (no title/body)
  → process-local EventChannel
  → AndroidPlatformAdapter parsing
  → Riverpod observation provider
  → NotificationObservationService (execute nothing)
  → Home displays sanitized event / matched rule
```

The app evaluates posted events against enabled rules but never calls
`RuleEnforcementService` or `submitEnforcementRequest`. Enforcement stays
reported as unsupported.

## Testing strategy

- Domain tests use constructed rules and a fixed `RuleContext`.
- Enforcement tests use `FakePlatformAdapter`; no device, notification access,
  or Bluetooth hardware is required.
- Repository tests use an in-memory Drift database plus a close/reopen file test
  for persistence.
- Widget tests override the repository and platform adapter so the app can launch
  in the test environment.
- Platform tests mock the MethodChannel and both EventChannels, including
  malformed payloads, safe stream errors, concurrent listeners, cancellation,
  re-subscription, and fresh status queries after connection changes.
- Lifecycle widget tests simulate app pause/resume and native connection changes;
  they verify the UI updates only after the refreshed status resolves.
- Kotlin unit tests cover event sanitization, notification-access component
  matching, status idempotence, and sink teardown. Android instrumentation tests
  run the access comparison against the real system setting and the payload
  allowlist on-device; manual grant/revoke and service rebinding remain required.
- On Windows, tests load `winsqlite3.dll`; Android uses `sqlite3_flutter_libs`.

## iOS boundary

iOS does not provide third-party apps a general API to inspect, suppress, or
rewrite notifications from other apps. The iOS adapter reports this explicitly.
Future iOS work may only use supported APIs (for example, extensions for
Quietdude's own notifications) and must continue to report partial support
honestly. The shared domain and platform contract are ready for a Swift adapter;
no dummy iOS code claims Android capabilities.
