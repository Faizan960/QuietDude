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
             ├── AndroidPlatformAdapter ──► MethodChannel ──► Kotlin
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
  `RuleExecutionResult`, `PlatformCapability`.
- `conditions/`: sealed `RuleCondition` variants and time-window semantics.
  Implemented: always, time window (including overnight), foreground app, and
  wearable-nearby flag.
- `actions/`: sealed `RuleAction` variants. Implemented: hide previews, silence
  notifications, dismiss notifications, discreet alert. Each action maps to the
  platform capability it would require.
- `policy/`: `RulePriorityPolicy` resolves matching rules.
- `engine/`: `DefaultRuleEngine` evaluates rules and builds an `ExecutionPlan`.
  `RuleEnforcementService` submits that plan to a `PlatformAdapter` and returns
  the platform's structured result.

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
settings access, and enforcement submission. Results are typed and include
`Applied`, `Partially applied`, `Unsupported`, `Permission required`, `Failed`,
and `Not applicable`. `contracts/platform_channel.dart` wraps `MethodChannel` and
`EventChannel` so platform errors are typed.

The Android adapter parses native capability maps and returns a conservative
fallback if the bridge is unavailable. The iOS adapter reports capabilities as
unsupported or planned without pretending Android behavior exists. The desktop
adapter reports planned capabilities only.

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
`com.example.notification_privacy/platform`. Methods:

- `getCapabilities`: returns read-only capability maps.
- `checkPermission`: reports notification-listener and DND policy access.
- `openSettings`: opens the relevant Android settings screen only after a user
  action.
- `submitEnforcementRequest`: always returns `unsupported` in this build.

No listener service, geofence, BLE scan, or enforcement code exists yet. The
manifest declares no special or runtime permissions.

## Testing strategy

- Domain tests use constructed rules and a fixed `RuleContext`.
- Enforcement tests use `FakePlatformAdapter`; no device, notification access,
  or Bluetooth hardware is required.
- Repository tests use an in-memory Drift database plus a close/reopen file test
  for persistence.
- Widget tests override the repository and platform adapter so the app can launch
  in the test environment.
- On Windows, tests load `winsqlite3.dll`; Android uses `sqlite3_flutter_libs`.

## iOS boundary

iOS does not provide third-party apps a general API to inspect, suppress, or
rewrite notifications from other apps. The iOS adapter reports this explicitly.
Future iOS work may only use supported APIs (for example, extensions for
Quietdude's own notifications) and must continue to report partial support
honestly. The shared domain and platform contract are ready for a Swift adapter;
no dummy iOS code claims Android capabilities.
