import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/drift_rule_repository.dart';
import '../data/repositories/rule_repository.dart';
import '../domain/engine/notification_observation_service.dart';
import '../domain/engine/rule_engine.dart';
import '../domain/engine/rule_enforcement_service.dart';
import '../domain/models/notification_listener.dart';
import '../domain/models/notification_observation.dart';
import '../domain/models/platform_capability.dart';
import '../domain/models/privacy_rule.dart';
import '../platform/android/android_platform_adapter.dart';
import '../platform/contracts/platform_adapter.dart';
import '../platform/ios/ios_platform_adapter.dart';
import '../platform/unsupported_platform_adapter.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final ruleRepositoryProvider = Provider<RuleRepository>((ref) {
  return DriftRuleRepository(ref.watch(databaseProvider));
});

final rulesProvider = StreamProvider<List<PrivacyRule>>((ref) {
  return ref.watch(ruleRepositoryProvider).watchRules();
});

final platformAdapterProvider = Provider<PlatformAdapter>((ref) {
  if (kIsWeb) {
    return const UnsupportedPlatformAdapter(platformLabel: 'the web');
  }
  if (Platform.isAndroid) {
    return AndroidPlatformAdapter();
  }
  if (Platform.isIOS) {
    return const IosPlatformAdapter();
  }
  return const UnsupportedPlatformAdapter(platformLabel: 'desktop');
});

final platformCapabilitiesProvider = FutureProvider<List<PlatformCapability>>((
  ref,
) {
  return ref.watch(platformAdapterProvider).getCapabilities();
});

final notificationListenerStatusProvider =
    FutureProvider<NotificationListenerStatus>((ref) {
      return ref.watch(platformAdapterProvider).getNotificationListenerStatus();
    });

final notificationEventsProvider = StreamProvider<SanitizedNotificationEvent>((
  ref,
) {
  return ref.watch(platformAdapterProvider).notificationEvents;
});

final notificationConnectionStatusProvider =
    StreamProvider<NotificationConnectionStatus>((ref) {
      return ref.watch(platformAdapterProvider).notificationConnectionEvents;
    });

final ruleEngineProvider = Provider<RuleEngine>((ref) {
  return const DefaultRuleEngine();
});

final notificationObservationServiceProvider =
    Provider<NotificationObservationService>((ref) {
      return NotificationObservationService(
        engine: ref.watch(ruleEngineProvider),
      );
    });

final lastNotificationObservationProvider =
    StreamProvider<NotificationObservation>((ref) {
      final rules =
          ref.watch(rulesProvider).asData?.value ?? const <PrivacyRule>[];
      final service = ref.watch(notificationObservationServiceProvider);
      return ref
          .watch(platformAdapterProvider)
          .notificationEvents
          .map((event) => service.observe(rules: rules, event: event));
    });

final ruleEnforcementServiceProvider = Provider<RuleEnforcementService>((ref) {
  return RuleEnforcementService(
    engine: ref.watch(ruleEngineProvider),
    platformAdapter: ref.watch(platformAdapterProvider),
  );
});
