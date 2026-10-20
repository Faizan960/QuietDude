import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/drift_rule_repository.dart';
import '../data/repositories/rule_repository.dart';
import '../domain/engine/rule_engine.dart';
import '../domain/engine/rule_enforcement_service.dart';
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

final ruleEngineProvider = Provider<RuleEngine>((ref) {
  return const DefaultRuleEngine();
});

final ruleEnforcementServiceProvider = Provider<RuleEnforcementService>((ref) {
  return RuleEnforcementService(
    engine: ref.watch(ruleEngineProvider),
    platformAdapter: ref.watch(platformAdapterProvider),
  );
});
