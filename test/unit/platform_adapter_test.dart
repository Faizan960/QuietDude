import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/models/platform_capability.dart';
import 'package:quietdude/domain/models/rule_execution.dart';
import 'package:quietdude/platform/android/android_platform_adapter.dart';
import 'package:quietdude/platform/contracts/platform_adapter.dart';
import 'package:quietdude/platform/contracts/platform_channel.dart';
import 'package:quietdude/platform/ios/ios_platform_adapter.dart';
import 'package:quietdude/platform/unsupported_platform_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android platform adapter', () {
    const channel = MethodChannel('quietdude.test/platform');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late AndroidPlatformAdapter adapter;

    setUp(() {
      adapter = AndroidPlatformAdapter(
        channel: PlatformChannel(methodChannel: channel),
      );
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test(
      'parses structured capability responses and ignores unknown ids',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getCapabilities');
          return [
            {
              'id': 'notification_listener',
              'status': 'requires_permission',
              'detail': 'Notification access has not been granted.',
            },
            {
              'id': 'do_not_disturb_control',
              'status': 'scaffolded',
              'detail': 'Not implemented.',
            },
            {
              'id': 'future_capability',
              'status': 'planned',
              'detail': 'Unknown to this app version.',
            },
          ];
        });

        final capabilities = await adapter.getCapabilities();

        expect(capabilities, hasLength(2));
        expect(
          capabilities.first.id,
          PlatformCapabilityId.notificationListener,
        );
        expect(capabilities.first.status, CapabilityStatus.requiresPermission);
        expect(capabilities.last.id, PlatformCapabilityId.doNotDisturbControl);
      },
    );

    test(
      'returns conservative capabilities when the bridge is missing',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async => null);

        final capabilities = await adapter.getCapabilities();

        expect(capabilities, hasLength(PlatformCapabilityId.values.length));
        expect(
          capabilities.every((capability) => !capability.isExecutable),
          isTrue,
        );
      },
    );

    test('parses a permission response', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'checkPermission');
        expect(call.arguments, {'permission': 'notification_listener'});
        return {'state': 'granted'};
      });

      final state = await adapter.checkPermission(
        PlatformPermission.notificationListener,
      );

      expect(state, PermissionState.granted);
    });

    test('reports unsupported enforcement without claiming success', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'submitEnforcementRequest');
        return {'status': 'unsupported', 'message': 'Not implemented.'};
      });

      final result = await adapter.submitEnforcementRequest(
        const EnforcementRequest(
          ruleId: 'rule-1',
          actions: [RuleActionKind.hidePreviews],
        ),
      );

      expect(result.status, RuleExecutionStatus.unsupported);
      expect(result.appliedActions, isEmpty);
      expect(result.skippedActions, [RuleActionKind.hidePreviews]);
    });
  });

  group('iOS and unsupported adapters', () {
    test('iOS never claims cross-app notification control', () async {
      const adapter = IosPlatformAdapter();

      final capabilities = await adapter.getCapabilities();
      final listener = capabilities.firstWhere(
        (capability) =>
            capability.id == PlatformCapabilityId.notificationListener,
      );
      final dismissal = capabilities.firstWhere(
        (capability) =>
            capability.id == PlatformCapabilityId.notificationDismissal,
      );

      expect(listener.status, CapabilityStatus.unsupported);
      expect(dismissal.status, CapabilityStatus.unsupported);
      expect(
        capabilities.any(
          (capability) => capability.status == CapabilityStatus.implemented,
        ),
        isFalse,
      );
    });

    test('iOS reports unsupported enforcement', () async {
      const adapter = IosPlatformAdapter();

      final result = await adapter.submitEnforcementRequest(
        const EnforcementRequest(
          ruleId: 'rule-1',
          actions: [RuleActionKind.hidePreviews],
        ),
      );

      expect(result.status, RuleExecutionStatus.unsupported);
      expect(result.status.isSuccess, isFalse);
    });

    test('desktop adapter reports planned capabilities only', () async {
      const adapter = UnsupportedPlatformAdapter(platformLabel: 'desktop');

      final capabilities = await adapter.getCapabilities();

      expect(
        capabilities.every(
          (capability) => capability.status == CapabilityStatus.planned,
        ),
        isTrue,
      );
    });
  });
}
