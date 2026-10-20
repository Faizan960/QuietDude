# Quietdude

**Your notifications. Your rules.**

Quietdude is a privacy-first Android application for defining independent rules
that describe how notifications should behave in different situations. This
repository currently contains the scaffold: local rule storage, a deterministic
rule engine, a typed platform boundary, a minimal Kotlin capability bridge, and
the initial Flutter UI.

Real notification enforcement is **not implemented** in this phase. Quietdude
does not read, hide, silence, dismiss, or rewrite notifications yet.

## What is implemented

- Material 3 Flutter application with Home, Rules, and Settings screens.
- Riverpod state wiring and `go_router` navigation.
- Typed domain models for rules, conditions, actions, priorities, execution
  results, and platform capabilities.
- Deterministic rule evaluation with documented conflict resolution.
- Local SQLite persistence through Drift, behind a `RuleRepository` abstraction.
- Typed platform adapter contract with Android and iOS implementations.
- Minimal Kotlin `MethodChannel` bridge that reports capabilities and opens
  supported settings screens when the user asks.
- Unit, repository/persistence, and widget tests with fake platform adapters.

## What is deliberately not implemented

- `NotificationListenerService` or any notification interception.
- Do Not Disturb / interruption-filter changes.
- Notification dismissal.
- Geofencing or location collection.
- BLE wearable-proximity detection.
- Backend, accounts, analytics, advertising, or cloud sync.
- Universal notification control on iOS (not possible for third-party apps).

See [docs/platform_capabilities.md](docs/platform_capabilities.md) for the
capability matrix and [docs/privacy_model.md](docs/privacy_model.md) for the
data model.

## Prerequisites

- Flutter 3.38.5 (stable) with Dart 3.10.4
- Android SDK 36 and JDK 21 (Android Studio's bundled JBR works)
- Android device or emulator running Android 7.0 (API 24) or newer
- Xcode on macOS for the future iOS target

Check the toolchain with:

```bash
flutter --version
flutter doctor -v
```

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Drift generated files (`lib/data/database/app_database.g.dart`) are committed, but
regenerate them after changing the database schema.

## Run

```bash
flutter devices
flutter run -d <device-id>
```

The application launches without requesting notification access, location,
Bluetooth, or any other special permission. Capability reporting is read-only.

## Test and verify

```bash
dart format .
dart analyze
flutter test
flutter build apk --debug
```

The persistence tests use an in-memory SQLite database. On Windows, the Dart VM
does not bundle SQLite, so `test/fixtures/sqlite_test_setup.dart` loads the
system `winsqlite3.dll` for tests only. On Android, SQLite is supplied by
`sqlite3_flutter_libs`.

## Dependency notes

Versions are resolved from the installed Flutter SDK:

- `drift` and `drift_dev` are pinned to `2.30.1`, and `sqlite3` to `2.6.0`.
  Newer `drift_dev` releases require `analyzer` 13, which requires Dart 3.11.
  Flutter 3.38.5 pins Dart 3.10.4 and `meta` 1.17.0, so the newest Drift
  generator cannot resolve against this SDK.
- `sqlite3_flutter_libs` 0.5.40 matches the `sqlite3` 2.x dependency line.
  It becomes obsolete only after migrating to `sqlite3` 3.x native assets.
- `flutter_blue_plus` is installed for the future wearable-proximity phase but
  is not used at runtime yet. Its Android manifest intentionally declares no
  Bluetooth permissions, so this scaffold requests none.

Do not run `flutter pub upgrade --major-versions` without re-validating the
Drift/analyzer combination against the current Flutter SDK.

## Provisional identifiers

Replace these before any public release:

- Android application ID / namespace: `com.example.notification_privacy`
  (`android/app/build.gradle.kts`)
- iOS bundle identifier: `com.example.notificationprivacy`
  (`ios/Runner.xcodeproj/project.pbxproj`)
- Dart package name: `quietdude` (`pubspec.yaml`)

## Project structure

```text
lib/
├── app/          application shell, router, theme, Riverpod providers
├── core/         errors, sanitized logging, utilities
├── data/         Drift database and repository implementations
├── domain/       models, conditions, actions, policy, rule engine
├── features/     home, rules, permissions widgets, settings
└── platform/     typed contracts plus Android/iOS/desktop adapters
```

Domain code has no Flutter widget or Android implementation dependency. See
[docs/architecture.md](docs/architecture.md) for the layering and execution flow.

## Documentation

- [Architecture](docs/architecture.md)
- [Platform capabilities](docs/platform_capabilities.md)
- [Permissions](docs/permissions.md)
- [Privacy model](docs/privacy_model.md)
- [Android native integration plan](docs/android_native_plan.md)

## Known limitations

- Rules created in the UI support name, enabled state, and priority. New rules
  receive a default always-match condition and hide-previews action; condition
  and action editing is a later milestone.
- The rule engine and platform adapter are wired for tests, but the app does not
  automatically submit enforcement requests yet.
- Android notification access and Do Not Disturb policy access are special
  user-granted access. They may be revoked at any time and vary by OEM/version.
- iOS cannot inspect another app's notifications. Future iOS work must report
  partial or unsupported capabilities honestly and can only alter Quietdude's
  own notifications.
- No backend, accounts, analytics, or advertising SDKs are included.

## Next milestone

Prove notification access and supported system-interruption controls on a
physical Android device:

1. Add a minimal `NotificationListenerService` behind explicit user consent.
2. Report granted access accurately and handle revocation.
3. Redact previews for a narrowly scoped, user-selected app set without storing
   notification content.
4. Validate Do Not Disturb / interruption-filter behavior, including restoration
   and version/OEM constraints.
5. Add instrumentation or manual test notes for each supported action before the
   UI labels any action as implemented.
