# Notification enforcement feasibility

- **Milestone:** 4A, audit only
- **Audit date:** 2026-10-20
- **Scope:** Android public APIs available to an ordinary third-party app with notification-listener access.
- **Implementation status:** No enforcement is implemented. This document does not authorize or describe a completed enforcement feature.

## 1. Executive summary

Quietdude currently observes sanitized Android notification metadata. It does not hide, redact, silence, dismiss, or rewrite another app's notification.

The platform review supports these conclusions:

| Candidate | Ordinary-app feasibility | What it can actually do | Recommended capability status |
|---|---|---|---|
| Preview redaction | **No** | Nothing against another app's notification. `NotificationListenerService` exposes observation and removal, not content mutation. | `unsupported` |
| Notification dismissal | **Yes, after posting** | Remove an already-posted notification with its raw notification key. No restore and no pre-display guarantee. | `scaffolded` now; `partially_supported` only after implementation and device testing |
| Do Not Disturb / interruption filter | **Only with policy access** | Change a device-wide interruption policy or an app-associated automatic rule. It is not per-notification and is not equivalent to preview redaction. | `requires_permission`; defer implementation |
| User-guided settings | **Yes, guidance only** | Open a system settings screen for the user. It cannot change the setting on the user's behalf. | Separate settings-handoff model, not a rule action |
| Quietdude's own notifications | **Yes, own app only** | Control visibility, channels, and content of notifications Quietdude posts. This has no effect on other apps. | Out of scope for cross-app enforcement |

**Recommendation:** the only defensible first enforcement slice is **dismiss-after-arrival**, explicitly opt-in and explicitly described as removal after Android has posted the notification. It must not be labelled “hide previews.” If the product requirement is that sensitive content must never appear on screen or in the shade, ordinary Android apps cannot satisfy that requirement; the correct outcome is no enforcement feature, not a misleading approximation.

The best safe non-enforcement slice is user-guided settings: explain the limitation and let the user open the relevant system screen. That is guidance, not enforcement.

## 2. Current implementation facts

### Android surface

- The app targets SDK 36, has `minSdk 24`, and declares `QuietdudeNotificationListenerService` with `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE` (signature protection) and the `android.service.notification.NotificationListenerService` intent filter.
- Notification access is special access, not a runtime permission. The app opens `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS` only from a user action.
- The service receives `onNotificationPosted` and `onNotificationRemoved`, extracts an allow-listed metadata map, and drops the `StatusBarNotification` reference.
- The service does **not** call `cancelNotification`, `cancelNotifications`, `snoozeNotification`, `requestInterruptionFilter`, `setInterruptionFilter`, `updateNotificationChannel`, or `adjustNotification`.
- `PlatformBridge` remains a read-only capability and observation bridge; `submitEnforcementRequest` returns `unsupported`.
- `RuleEnforcementService` can build an enforcement request, but the Android adapter/bridge does not execute it.
- The manifest does not declare `ACCESS_NOTIFICATION_POLICY` and does not include `POST_NOTIFICATIONS`. The latter is not required to observe other apps' notifications.

### Data carried across the bridge

The Flutter payload contains only:

- event type (`posted` or `removed`);
- posting package;
- process-salted, truncated hash of the raw notification key;
- category, if present;
- posting timestamp;
- `hasText` (key presence only);
- group-summary flag.

It contains no title, body, text, sender, people/conversation data, bitmap, raw notification key, or raw extras. Events and connection status are memory-only and are not persisted or logged.

The raw key is critical for dismissal. It exists only in the native listener today and is deliberately not sent to Flutter. The current `eventId` is a one-way hash and cannot be used with `cancelNotification`.

### Existing domain model

`RuleActionKind` already contains:

- `hidePreviews` → `PlatformCapabilityId.previewRedaction`
- `silenceNotifications` → `PlatformCapabilityId.doNotDisturbControl`
- `dismissNotifications` → `PlatformCapabilityId.notificationDismissal`
- `discreetAlert` → `PlatformCapabilityId.discreetAlerts`

New rules are currently created with an always-match condition and a default `HidePreviewsAction`. That default is a product and documentation hazard until preview redaction has a real implementation, because “hide previews” is not a supported Android capability.

Current Android capability responses are:

| Capability id | Current status | Current detail |
|---|---|---|
| `notification_listener` | `implemented` when granted and connected; `unavailable` or `requires_permission` otherwise | Observation only |
| `preview_redaction` | `scaffolded` | Rewriting not implemented |
| `do_not_disturb_control` | `requires_permission`, or `scaffolded` when policy access exists | No interruption-filter change implemented |
| `notification_dismissal` | `requires_permission` | No dismissal implemented |
| `keyword_filtering` | `scaffolded` | No text filtering |
| `discreet_alerts` | `planned` | Not implemented |
| `geofence_events` | `planned` | No location implementation |
| `wearable_proximity` | `planned` | No BLE implementation |

The Settings and Home screens explicitly say enforcement is not implemented. Rules can match observed events, but a match only produces a plan; it does not mutate platform state.

### Observer status behavior

- Access and connection are separate values.
- A bound listener is treated as proof of granted access during a live regrant while `Settings.Secure` can lag.
- Connection changes arrive on a separate status stream.
- One 1.2-second reconciliation refresh runs after a connection transition; there is no periodic polling.
- Notification observation uses local wall-clock time for time-window rules.
- Removed events are observed but not evaluated.

### Verification already recorded

The M3 baseline files and tests were verified before this audit:

- `dart analyze`: clean.
- `flutter test`: 71 passing.
- Android JVM tests: 13 passing.
- Android instrumentation: 3 passing on an API 37 emulator.
- Debug APK built successfully; merged-manifest audit completed.
- Manual API 37 checks covered denied access, live grant/revoke/regrant, posted/removed events, background/foreground, force-stop/relaunch, reboot, and log/database privacy searches.
- Grant/revoke for manual checks was driven with ADB, not by independently exercising every Settings UI path.

This audit reran `dart analyze` (clean), `flutter test` (71 passing), and `:app:testDebugUnitTest` (successful). It did not rerun instrumentation or manual device actions because no device was connected. **No enforcement action has been tested because none is implemented.**

## 3. Candidate action comparison

### 3.1 Preview redaction

**Question:** Can an ordinary app with notification-listener access hide or redact another app's notification content after it is posted?

**Answer: No, not with a supported public NLS API.**

The public `NotificationListenerService` surface lets a listener:

- observe posted/removed notifications and ranking;
- read active or snoozed notifications;
- cancel or snooze notifications;
- request listener hints or an interruption filter;
- inspect or, only in restricted roles, update channels.

It does not expose a method that replaces, masks, or rewrites another package's notification text or views. `Notification.visibility` and `Notification.Builder.setPublicVersion` are properties/actions of the **posting app**. The system UI uses that visibility to decide what appears on a secure lock screen or during screen sharing; the listener cannot set another app's public version. Channel update/query methods are restricted to a companion device or the notification assistant, not an ordinary listener.

A separate system notification-assistant role can adjust some notifications before posting, but it is a `@SystemApi` role, not the public notification-listener toggle. It is not a viable ordinary-app path for Quietdude and must not be assumed in product copy or tests.

**Possible partial substitutes and their limits:**

- Cancel the notification after posting: removes it, may leave a visible flash/alert, cannot restore it.
- Ask the user to change the source app's notification settings: guidance only; Quietdude cannot do it.
- Change Quietdude's own notification visibility: affects only Quietdude-owned notifications.
- Change a device-wide or automatic DND policy: affects far more than one notification and is not content redaction.

**Conclusion:** `preview_redaction` is `unsupported` for this app. It must not be presented as scaffolded, planned for the next milestone, or the default rule action.

### 3.2 Notification dismissal

**Question:** Can the listener dismiss another app's notification, what authorization is needed, and is it reversible?

**Documented behavior:**

- `cancelNotification(String key)` was added in API 21 and is available on the app's `minSdk 24`.
- It tells the notification manager to dismiss one notification. The manager removes it and the listener receives `onNotificationRemoved`.
- The docs describe the intended use as a listener UI that lets the user dismiss notifications, similar to the notification panel.
- `cancelNotifications(String[] keys)` can dismiss multiple notifications; passing `null` dismisses all. Quietdude should not use the all-notifications form.
- There is no documented restore operation. `snoozeNotification` removes now and reposts later, but it is a different behavior and still not a preview guard.
- The API returns `void`; success must be inferred from removal callbacks or device tests, not from a return value.

**Authorization:** the listener must have notification access. No additional runtime permission is documented for `cancelNotification`.

**Timing and UX:** the notification has already been posted when the listener is informed. Cancellation can race with display and sound. A user may see or hear the notification before it disappears. The app may repost or update it. The raw key may become stale or change when the notification is updated.

**Engineering constraint:** cancellation requires the raw notification key, but the current bridge forwards only a salted hash. A future implementation must either:

1. keep an in-memory `eventId -> raw key` map in the native process with a short TTL and call cancellation natively, or
2. provide an opaque native handle to Flutter and keep the raw key native.

The raw key must not be logged, persisted, sent over the network, or stored in Drift.

**Conclusion:** technically feasible as a best-effort, after-post removal. It is **not** preview hiding and must not be described as such. Recommended status after implementation and testing: `partially_supported` (works within timing/lifetime limits) or a precisely defined `implemented` effect, but never `implemented` for “hide previews.”

### 3.3 Do Not Disturb / interruption filter

**Question:** Can Quietdude use DND APIs to silence matched notifications, and is that equivalent to preview redaction?

**Documented behavior:**

- `NotificationManager.setInterruptionFilter(int)` was added in API 23.
- It is available only when notification policy access is granted. `isNotificationPolicyAccessGranted()` is the check.
- Policy access is granted by the user through `Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`. The permission marker `ACCESS_NOTIFICATION_POLICY` is normal protection, but it does not itself grant policy access.
- Managed profiles cannot grant notification policy access.
- For apps targeting Android 15 / API 35 and above, most calls cannot modify the global interruption filter. The call instead activates or deactivates an `AutomaticZenRule` associated with the app, using the app's `NotificationManager.Policy`.
- `NotificationListenerService.requestInterruptionFilter()` is only a request; the host may refuse or another component may change the filter. For apps targeting API 35+, it also activates/deactivates the app-associated rule.
- DND is global or policy-wide, not a per-notification visibility control. It can suppress calls, alarms, and unrelated apps depending on policy.

**Why it is not equivalent:**

- It does not redact an individual notification's content.
- It can change device-wide behavior outside the matched event.
- It requires a second special access flow and manifest marker.
- It is not a safe automatic side effect of a rule; a stale or failed restore could leave the device quiet.
- It has materially different behavior for target-35+ apps on API 35+ devices, and on OEM builds.

**Conclusion:** technically possible only as an explicitly authorized, reversible, device-wide/rule-scoped feature. It is not a preview-redaction workaround and should be deferred. Do not request policy access or change device settings in Milestone 4A.

### 3.4 User-guided settings

**Question:** Can Quietdude help the user change the source app's notification behavior without enforcing anything itself?

**Documented options:**

- `Settings.ACTION_APP_NOTIFICATION_SETTINGS` (API 26) shows notification settings for one app; `EXTRA_APP_PACKAGE` supplies the package.
- `Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS` (API 30) shows the listener-access page for a `ComponentName`; `EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME` supplies it.
- `Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS` (API 23) shows the policy-access page.
- These are user-driven system screens. Opening them does not grant access or change settings, and no result is returned about what the user did.
- An OEM may not provide a matching activity; callers must handle `ActivityNotFoundException`/failure and provide an in-app explanation.

**Conclusion:** useful as an educational handoff, not as enforcement. It should be modeled as `settings_handoff`, not as a `RuleActionKind`, and must never claim the user's setting was changed.

### 3.5 Quietdude-owned notifications

Quietdude can control its own notification content, channel, visibility, and public version. That can be useful for a future “discreet alert” or status notification, but it has no effect on other apps' notifications and does not satisfy cross-app preview redaction or dismissal. It is outside this enforcement slice.

## 4. Authoritative API references

All Android references below were reviewed on 2026-10-20. “Documented” means stated by the public API reference or official Android source. Engineering conclusions that still need device validation are identified in the surrounding text, not presented as documented guarantees.

| Reference | What it establishes | Classification |
|---|---|---|
| [NotificationListenerService](<https://developer.android.com/reference/android/service/notification/NotificationListenerService>) | Service receives calls when notifications are posted, removed, or reranked. Must be declared with `BIND_NOTIFICATION_LISTENER_SERVICE` and the service intent filter. Low-RAM devices on Android 10 and below cannot bind listeners; work-profile listeners are ignored by the system. | Documented |
| [onNotificationPosted](<https://developer.android.com/reference/android/service/notification/NotificationListenerService#onNotificationPosted(android.service.notification.StatusBarNotification)>) | Listener learns about new notifications “as they are posted.” No pre-post veto is documented. | Documented |
| [cancelNotification(String)](<https://developer.android.com/reference/android/service/notification/NotificationListenerService#cancelNotification(java.lang.String)>) | Dismisses a single notification; manager removes it and delivers `onNotificationRemoved`. Intended for user dismissal through the listener's UI. Added API 21. | Documented |
| [cancelNotifications(String[])](<https://developer.android.com/reference/android/service/notification/NotificationListenerService#cancelNotifications(java.lang.String[])>) | Dismisses multiple notifications; `null` dismisses all. Added API 21. | Documented |
| [snoozeNotification(String, long)](<https://developer.android.com/reference/android/service/notification/NotificationListenerService#snoozeNotification(java.lang.String,%20long)>) | Removes a notification for a duration and reposts it later. Added API 26. Not a redaction or permanent-dismissal API. | Documented |
| [getNotificationChannels(String, UserHandle)](<https://developer.android.com/reference/android/service/notification/NotificationListenerService#getNotificationChannels(java.lang.String,%20android.os.UserHandle)>) and [updateNotificationChannel](<https://developer.android.com/reference/android/service/notification/NotificationListenerService#updateNotificationChannel(java.lang.String,%20android.os.UserHandle,%20android.app.NotificationChannel)>) | Channel query/update exists, but the caller must have an associated companion device or be the notification assistant. Not an ordinary-listener preview-edit path. Added API 26. | Documented |
| [NotificationManager.setInterruptionFilter(int)](<https://developer.android.com/reference/android/app/NotificationManager#setInterruptionFilter(int)>) | Sets the interruption filter; only with policy access. For apps targeting API 35+, cannot modify the global filter and instead activates an app-associated `AutomaticZenRule`. Added API 23. | Documented |
| [NotificationManager.isNotificationPolicyAccessGranted()](<https://developer.android.com/reference/android/app/NotificationManager#isNotificationPolicyAccessGranted()>) | Checks policy access; access is requested through `ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`. Added API 23. | Documented |
| [Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS](<https://developer.android.com/reference/android/provider/Settings#ACTION_NOTIFICATION_LISTENER_SETTINGS>) | System screen for notification-listener access. Added API 22. | Documented |
| [Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS](<https://developer.android.com/reference/android/provider/Settings#ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS>) | System screen for one listener component, using `EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME`. Added API 30. | Documented |
| [Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS](<https://developer.android.com/reference/android/provider/Settings#ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS>) | System screen where users grant/deny policy access; managed profiles cannot grant it. Added API 23. | Documented |
| [Settings.ACTION_APP_NOTIFICATION_SETTINGS](<https://developer.android.com/reference/android/provider/Settings#ACTION_APP_NOTIFICATION_SETTINGS>) | System screen for one app's notification settings, using `EXTRA_APP_PACKAGE`. Added API 26. | Documented |
| [Manifest.permission.ACCESS_NOTIFICATION_POLICY](<https://developer.android.com/reference/android/Manifest.permission#ACCESS_NOTIFICATION_POLICY>) | Normal marker permission for apps that wish to access notification policy; not supported on managed profiles. It does not replace the user's policy-access grant. | Documented |
| [Notification.visibility](<https://developer.android.com/reference/android/app/Notification#visibility>) / [VISIBILITY_PRIVATE](<https://developer.android.com/reference/android/app/Notification#VISIBILITY_PRIVATE>) | Visibility controls how the system UI reveals the posting app's notification on secure lock screens and during screen sharing. `setPublicVersion` is a builder operation of the posting app. | Documented |
| [AOSP NotificationAssistantService](<https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/service/notification/NotificationAssistantService.java>) | A system notification-assistant service can modify some notification aspects before posting, but the class is `@SystemApi`, not a public third-party API. | Documented AOSP source; not a public SDK path |
| Current app source: `PlatformBridge.kt`, `QuietdudeNotificationListenerService.kt`, `NotificationEventSanitizer.kt` | No enforcement call is made; only allow-listed observation and unsupported enforcement responses exist. | Observed in repository |

**API-level notes for this app:** listener observation is API 18+, listener interruption-filter requests API 21+, cancellation API 21+, per-app notification settings API 26+, listener detail settings API 30+, and `NotificationManager` policy control API 23+ with the API 35 behavior change. The app's `minSdk 24` therefore supports the APIs, but supports the behaviors only under the documented authorization and restrictions.

**Negative finding on preview redaction:** a review of the public NLS method set found no method to replace or redact another package's notification content. This is a documented-API review conclusion, not a claim that no hidden/system API exists anywhere. A system assistant role exists but is not available through the ordinary listener path.

## 5. Required permissions and user authorization

| Access | Manifest / system requirement | User action | Current state | Caveats |
|---|---|---|---|---|
| Notification listener | Service declaration with `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`; no `<uses-permission>` for this special access | User enables Quietdude in notification-listener settings | Implemented for observation | Special access, broad; revocable; listener may disconnect; low-RAM Android 10-and-below and work-profile restrictions documented |
| DND / interruption filter | Normal `ACCESS_NOTIFICATION_POLICY` marker **and** policy access app-op through system settings | User grants policy access in the DND/Modes access screen | Not requested; no mutation | Managed profiles cannot grant; target API 35+ app-scoped automatic rule; global side effects; must be reversible |
| Post own notifications | `POST_NOTIFICATIONS` on Android 13+ if Quietdude posts its own notification | Runtime permission for Quietdude's own posts | Not requested | Does not grant access to other apps' notifications |
| Per-app notification settings handoff | No new permission; use the system intent | User changes the source app's settings | Not implemented | No result; OEM may not provide the activity; Quietdude cannot verify the change |
| Notification assistant role | `@SystemApi` assistant service/role | System-selected role, not the listener toggle | Not available/not targeted | Not a public third-party path; do not design around it |

The existing app correctly does not request any permission at launch. A notification-listener grant is not a runtime permission and cannot be granted by Quietdude itself. Opening settings is not authorization; the app must re-read status on resume and after connection changes.

## 6. Recommended capability contract

Reuse `PlatformCapabilityId`, `CapabilityStatus`, and the existing action identifiers rather than creating parallel enums. The current status vocabulary is usable, but its semantics need to be strict.

### 6.1 Status semantics

- `implemented`: the effect exists, has a test strategy, and has been verified on the claimed device/API range. Observation alone is not enforcement.
- `requires_permission`: the effect is implemented but is currently blocked by missing notification-listener or policy access. Do not use this for an effect that has no implementation.
- `partially_supported`: the effect exists but has a documented platform limit, such as after-post-only dismissal or lack of a pre-display guarantee.
- `scaffolded`: internal UI/contract work exists but no effect has landed. It must not be shown as a working capability.
- `planned`: roadmap only; no user-facing claim.
- `unavailable`: temporarily unusable (for example, access granted but listener disconnected), not “unsupported forever.”
- `unsupported`: no public API path for this app. This is the correct value for cross-app preview redaction.
- `unknown`/error: state could not be determined; fail closed.

### 6.2 Add contract data without duplicating capability IDs

A capability should expose the effect and its guarantees, not just a status string. Recommended fields for the existing `PlatformCapability` model:

```text
effect:          observe | dismiss_after_post | interruption_filter | settings_handoff | none
authorization:   none | notification_listener | notification_policy_access | manual_settings
timing:          observation_only | after_post | before_post | not_applicable
reversible:      boolean
guarantee:       documented | best_effort | guidance_only | none
detail:          user-facing, non-technical limit statement
```

The exact types can be Dart enums/classes; the important part is that “dismiss after post” cannot be serialized as “hide previews.”

### 6.3 Recommended statuses for existing IDs

| ID | Recommended status | Effect and wording |
|---|---|---|
| `notification_listener` | `implemented` when observing | “Notification access: observing sanitized metadata” |
| `preview_redaction` | `unsupported` | “Android does not let Quietdude change another app's notification content.” |
| `notification_dismissal` | `scaffolded` until built; then `partially_supported` | “Dismiss after arrival; the notification may already have appeared or alerted; cannot be restored.” |
| `do_not_disturb_control` | `requires_permission` only when implemented; otherwise `scaffolded`/`planned` | “Device-wide interruption filter; requires system access; not per-notification.” |
| `keyword_filtering` | `unsupported` under the current privacy model | Would require reading notification text; not in scope. |
| `discreet_alerts` | `unsupported` for other apps; own-app only if implemented | Cannot affect other apps' notifications. |
| `geofence_events` / `wearable_proximity` | `planned` | No implementation and no permission request. |

### 6.4 Action mapping rules

- `RuleActionKind.hidePreviews` must map to `previewRedaction` and remain non-executable while that capability is `unsupported`.
- `RuleActionKind.dismissNotifications` maps to `notificationDismissal`; it may become executable only after the native path and tests exist.
- `RuleActionKind.silenceNotifications` maps to DND; it must not be treated as equivalent to dismissal.
- `RuleActionKind.discreetAlert` is own-app notification behavior only.
- New rules must not default to an unsupported enforcement action. The current default `HidePreviewsAction` should be reconsidered in a later implementation milestone; this audit does not change it.
- A capability must not be made executable just because the user has notification access. It also needs a real effect and a testable implementation path.

### 6.5 UI wording rules

- Never say “hidden,” “blocked,” or “redacted” when the action is removal after posting. Say “dismissed after arrival.”
- State that a dismissed notification cannot be restored by Quietdude.
- State that a notification may be visible or audible before dismissal.
- State that DND affects the device, not just the matched notification.
- For settings handoffs, say “Open settings”; do not say “Quietdude changed this.”
- Do not use a check mark or “Implemented” for observation alone when the card is about enforcement.

## 7. Privacy and safety impact

### Preview redaction

No implementation path was found. Do not collect notification content to approximate it. A future keyword rule would require transient access to text, which is a larger privacy change than this milestone permits and must not be inferred from the existing sanitized event.

### Dismissal

Dismissal needs the raw notification key. The existing bridge intentionally does not send it to Flutter. A future implementation must:

- keep the key only in native memory, with a short TTL;
- map an opaque event handle to the key without persisting, logging, or transmitting it;
- clear the map on listener disconnect, process death, and timeout;
- avoid `cancelNotifications(null)` and broad cancellation;
- avoid repeated cancellation attempts that could affect reposted or unrelated notifications;
- report failure/unknown honestly when removal is not confirmed.

Dismissal can cause missed messages or alarms if the matching logic is wrong. A user must explicitly opt in and be able to disable the rule. “Dismiss” is destructive and not reversible.

### DND

DND can suppress calls, alarms, and unrelated notifications. It must never be toggled silently, must be user-authorized, must be restored on rule exit/failure, and must be documented as device-wide. A stale DND state is a safety issue, not just a UX issue.

### Settings guidance

Opening a system settings screen exposes the package name of the source app to the system UI but stores no new data. The app must not claim success or read back a changed setting unless a documented query supports it.

### General retention

No new database columns or content logging are justified by this audit. Do not add notification content, raw keys, package history, or DND state to Drift. The latest observed package remains memory-only, as today.

## 8. Test strategy and device matrix

Passing existing tests does not validate enforcement. The current 71 Flutter tests, 13 JVM tests, and 3 API 37 instrumentation tests cover observation, status, sanitization, policy, and privacy boundaries only.

### 8.1 Test layers

| Layer | Required coverage |
|---|---|
| Dart unit | Capability status/effect mapping; unsupported vs unavailable; settings-handoff result handling; UI copy for after-post dismissal; no enforcement call when capability is unsupported |
| Dart widget | “Dismiss after arrival” wording; no “hidden” claim; settings handoff does not change access state; default rule action is not presented as working |
| Kotlin JVM | No native enforcement exists yet; future tests should cover key-map TTL, event-handle lookup, disconnect cleanup, and rejection of stale keys without reading content |
| Android instrumentation | Requires a manually granted listener. Post a test notification from a test package, observe posted event, request cancellation by handle, verify `onNotificationRemoved`; verify no broad cancel; verify disconnect/revocation fails closed |
| Manual system UI | Grant/revoke/regrant through Settings; background/foreground; force-stop; reboot; multi-user/work profile; OEM settings availability; DND grant/denial and restoration |
| Privacy audit | Search app logs and database for test title/body/raw key; confirm only allow-listed metadata and operation markers; confirm no event queue |

### 8.2 Matrix

`Observed` means the M3/M4A evidence actually covers it. `Not tested` must not be described as passing.

| Environment | Observation | Dismissal | DND | Settings handoff |
|---|---|---|---|---|
| API 24 (minSdk) | Not tested | Not implemented | Not implemented | Per-app settings unavailable before API 26 |
| API 26 | Not tested | Not implemented | Policy API available | App notification settings available |
| API 30 | Not tested | Not implemented | Policy API | Listener detail settings available |
| API 33 | Not tested | Not implemented | Policy API | Available |
| API 35 | Not tested | Not implemented | Global-filter restriction/app rule | Available |
| API 36 (target) | Not tested | Not implemented | Not implemented | Not tested |
| API 37 emulator | Observed (M3) | Not implemented | Not implemented | Not tested |
| Physical device/OEM | Not tested | Not tested | Not tested | Not tested |
| Work profile / managed profile | Not tested; documented listener/DND restrictions | Not tested | Policy access cannot be granted | Not tested |
| Low-RAM Android 10 or below | Documented as unsupported by platform | Not tested | N/A | N/A |

### 8.3 Required device-state cases for any future dismissal slice

- access denied at startup;
- access granted with listener connected;
- access granted but listener disconnected;
- revoke while the app is running;
- regrant without reinstall;
- app foreground, background, force-stopped, and relaunched;
- process death and reboot;
- multiple source apps and multiple notifications;
- group summary, ongoing, and high-priority/alarm-like notifications (behavior must be recorded, not assumed);
- user cancellation racing with the rule;
- source app repost/update after cancellation;
- key expiry/stale handle;
- cancellation not confirmed by `onNotificationRemoved`;
- API 24/25 callback differences (removal reason is API 26+);
- OEM build with a modified notification stack.

### 8.4 DND and settings testing constraints

- Do not automate policy changes in production tests. Grant/denial is a user/system action; use explicit test setup or ADB only in controlled test environments and record that fact.
- Test DND denied, granted, revoked, managed profile, API 35+ automatic-rule behavior, and restoration.
- Test settings intents for `ActivityNotFoundException` and OEM absence; verify that opening a screen does not optimistically change local capability state.
- Never let a test read or record notification title/body.

## 9. Recommended first enforcement slice

**Recommendation:** implement **dismiss-after-arrival only**, and only if the product explicitly accepts that the notification may be visible/audible before removal and cannot be restored.

This is the narrowest technically defensible enforcement behavior found. It should not be implemented in Milestone 4A; this section defines the candidate for a later milestone.

### 9.1 Scope

- Capability: `notificationDismissal`.
- Action: `dismissNotifications`.
- Trigger: an explicitly enabled user rule matching only currently available sanitized metadata (for example, source app and time window).
- No keyword/content matching in the first slice.
- No DND, no preview rewrite, no settings change, no own-notification behavior.
- No default action on newly created rules. A rule must explicitly opt in.

### 9.2 Native implementation boundary

1. Native listener receives `StatusBarNotification` and sanitizes the event as today.
2. Native keeps `eventId -> raw key` in a short-lived in-memory map; it does not send the raw key to Flutter.
3. Flutter evaluates the sanitized event and returns a dismissal request containing the opaque event handle, not the raw key.
4. Native validates handle, access, and TTL, then calls `cancelNotification(key)` once.
5. Native correlates `onNotificationRemoved` and reports confirmation; if no confirmation arrives, report `unknown`/`failed`, never `applied`.
6. Clear the map on disconnect, process death, and timeout.

No raw key, notification content, or package history may enter Drift, logs, analytics, or network calls.

### 9.3 Product and UI requirements

- Label: “Dismiss after arrival.”
- Explanation: “Android may show or alert this notification before Quietdude removes it. Quietdude cannot restore it.”
- No “hide,” “block,” or “redact” wording.
- Explicit opt-in per rule and easy disable.
- Show failure/unknown separately from success.
- Never cancel all notifications or retry indefinitely.
- Re-check notification access and connection before each attempt.

### 9.4 Acceptance criteria

- At least one instrumented device test proves a test notification is removed after posting and that removal is confirmed.
- Tests cover API 24, 26, 33, 35, and 36, plus at least one physical OEM device.
- Revocation, disconnect, stale handle, and process death fail closed.
- No test or log contains notification content or a raw key.
- UI accurately says the notification may have appeared first and cannot be restored.
- No other capability is marked executable as part of this slice.

### 9.5 Decision point

If the product requirement is “the user must never see or hear the sensitive content,” **do not ship this slice**. The platform does not provide an ordinary-app pre-display redaction path. The honest alternative is user-guided settings or no cross-app enforcement.

## 10. Non-goals and unresolved questions

### Non-goals

- Implementing enforcement, changing runtime behavior, changing database schema, adding permissions, or changing dependencies in this milestone.
- Cross-app preview redaction or text rewriting.
- Automatic DND or policy-access requests.
- Keyword filtering over notification text.
- Accessibility-service or device-owner/notification-assistant workarounds.
- Silent cancellation, broad `cancelAllNotifications`, or hidden background enforcement.
- Claiming Android API 36 or physical-device coverage without running it.
- Changing UI or capability values as part of this audit.

### Unresolved questions

1. **Cancellation reliability/timing on API 36 and OEM builds:** do notifications visibly flash or alert before removal, and how consistently is removal confirmed?
2. **Ongoing/group/alarm-like notifications:** does `cancelNotification` behave consistently, or do these require explicit product exclusions?
3. **Key lifetime and repost behavior:** how often does a source app update or repost with a new key after cancellation?
4. **API 24/25 callback shape:** removal confirmation must not depend on the API 26+ reason overload.
5. **API 35+ DND behavior:** exact app-associated `AutomaticZenRule` behavior and restoration semantics on target 36 need device testing.
6. **`ACCESS_NOTIFICATION_POLICY` marker behavior:** the manifest currently lacks it; confirm the required declaration and app-op interaction before any DND implementation.
7. **Settings intent availability:** whether per-app notification settings and listener-detail screens exist consistently on OEM devices.
8. **Work profile/low-RAM behavior:** document limits around listener binding and DND access.
9. **Notification assistant role:** the `@SystemApi` assistant can adjust before posting, but no public third-party path or user-grantable Quietdude role has been established. Treat it as unavailable unless separately proven.
10. **API 37:** observed only as an emulator environment; it is not the target and does not establish API 36 behavior.
11. **Physical device:** no physical device was available for this audit. The matrix remains a plan, not a claim of coverage.

## Verification note

This audit changed documentation only. It did not implement enforcement, modify runtime code, request permissions, alter the database schema, add dependencies, or generate a prototype.

Checks run for this audit:

- `dart analyze`: no issues.
- `flutter test`: 71 passing.
- `.\android\gradlew.bat -p android :app:testDebugUnitTest`: successful.
- `git diff --check`: no whitespace errors; Git emitted expected line-ending warnings.
- Instrumentation/manual device checks: not rerun; no device was connected. The previously recorded M3 API 37 results remain the only device evidence.
