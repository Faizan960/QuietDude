# Platform capabilities

Status values used by the app and documentation:

| Status | Meaning |
|---|---|
| Planned | Designed, not scaffolded. |
| Scaffolded | Interface or placeholder exists; no working enforcement. |
| Implemented | Working and verified on the target platform. |
| Requires permission | Supported only after explicit user authorization. |
| Partially supported | Works within documented OS/app-specific limits. |
| Unsupported | Not possible with supported public APIs. |

## Feature matrix

| Capability | Android | iOS | Notes |
|---|---|---|---|
| Local rule storage | Implemented | Implemented | Shared Drift schema, local only. |
| Deterministic rule evaluation | Implemented | Implemented | Shared Dart engine and policy. |
| Capability reporting | Implemented | Implemented | Android via Kotlin bridge; iOS static honest report. |
| Notification listener access | Implemented (observation) | Unsupported | Android special access; sanitized metadata only. iOS exposes no cross-app notification API. |
| Notification enforcement | Unsupported | Unsupported | No preview blocking, silencing, or dismissal is implemented. |
| Preview redaction | Scaffolded | Unsupported | Requires notification access on Android; not implemented. iOS can only alter Quietdude's own notifications via an extension. |
| Do Not Disturb / interruption filter | Requires permission | Unsupported | Android policy access required; iOS Focus modes are not controllable. |
| Notification dismissal | Requires permission | Unsupported | Android notification access plus version limits. |
| Keyword filtering | Scaffolded | Partially supported | Android depends on exposed notification text. iOS only for Quietdude-owned notifications. |
| Discreet urgent alerts | Planned | Planned | Could apply to Quietdude-owned notifications on iOS; system behavior on Android still needs design. |
| Location / geofence events | Planned | Planned | Requires explicit location permission; no location package installed. |
| BLE wearable proximity | Planned | Planned | Dependency installed; no scanning or permission request yet. |
| Background scheduling | Planned | Planned | Evaluate WorkManager/AlarmManager on Android and BGTaskScheduler on iOS before implementation. |

## Android status details

These are the values returned by `PlatformBridge.getCapabilities()` today:

| Capability id | Returned status | Reason |
|---|---|---|
| `notification_listener` | `implemented` when access is granted and connected; `unavailable` when granted but disconnected; `requires_permission` when not granted | Observation only. The detail states that enforcement is not implemented. |
| `preview_redaction` | `scaffolded` | No preview rewriting implemented. |
| `do_not_disturb_control` | `requires_permission`, or `scaffolded` when policy access is granted | No interruption-filter changes implemented. |
| `notification_dismissal` | `requires_permission` | No dismissal implemented. |
| `keyword_filtering` | `scaffolded` | Only metadata observation exists; text filtering is not implemented. |
| `discreet_alerts` | `planned` | Not designed or implemented. |
| `geofence_events` | `planned` | No location permission or geofencing code. |
| `wearable_proximity` | `planned` | No BLE scanning code. |

The Settings screen displays these values verbatim. It never shows an action as
active just because a rule matched. Home separately shows typed access and
connection labels (`Access granted`, `Access not granted`, `Listener connected`,
`Listener disconnected`, `Observation unavailable`) and an explicit
`Enforcement is not implemented yet` notice.

## Android versus iOS

- Android can expose notification metadata through a user-granted
  `NotificationListenerService`. Quietdude implements observation of sanitized
  metadata only; it does not modify notifications.
- Android interruption filters need `NotificationManager` policy access, which
  opens a system settings flow. Apps must not silently toggle it.
- Android notification dismissal is constrained by listener access, key lifetime,
  and OEM behavior. It is not a universal "block before display" mechanism.
- iOS gives ordinary third-party apps no API to observe or modify other apps'
  notifications. Notification Service Extensions can modify only notifications
  owned by the containing app. Any iOS UI must describe that limit.
- Focus mode, cross-app dismissal, and universal preview rewriting are not
  available to third-party iOS apps.
- Shared domain logic and platform contracts are platform-neutral, but enforcement
  capabilities are not.

## Verification expectations

Before changing a status to `Implemented`:

1. Verify behavior on a physical device for the stated Android/iOS version.
2. Add an automated test where the behavior can be isolated.
3. Record permission and OEM caveats in this file.
4. Confirm the UI's status string matches the actual result.
