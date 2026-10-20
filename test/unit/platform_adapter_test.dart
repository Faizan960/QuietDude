import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/models/notification_listener.dart';
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

    test('parses typed notification listener status', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getNotificationListenerStatus');
        return {'access': 'granted', 'connection': 'connected'};
      });

      final status = await adapter.getNotificationListenerStatus();

      expect(status.access, NotificationAccessStatus.granted);
      expect(status.connection, NotificationConnectionStatus.connected);
      expect(status.canObserve, isTrue);
    });

    test(
      'treats malformed or unavailable listener status as an error',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          return {'connection': 'connected'};
        });

        var status = await adapter.getNotificationListenerStatus();
        expect(status.access, NotificationAccessStatus.error);
        expect(status.connection, NotificationConnectionStatus.unavailable);

        messenger.setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });

        status = await adapter.getNotificationListenerStatus();
        expect(status.access, NotificationAccessStatus.error);
        expect(status.canObserve, isFalse);
      },
    );

    test('returns an error when the plugin is missing', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw MissingPluginException('No implementation found.');
      });

      final status = await adapter.getNotificationListenerStatus();

      expect(status.access, NotificationAccessStatus.error);
      expect(await adapter.openNotificationListenerSettings(), isFalse);
    });

    test(
      'opens notification listener settings through the typed bridge',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'openNotificationListenerSettings');
          return true;
        });

        expect(await adapter.openNotificationListenerSettings(), isTrue);
      },
    );

    test('reports failed settings launch without changing access', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => false);

      expect(await adapter.openNotificationListenerSettings(), isFalse);
    });
  });

  group('Notification event stream', () {
    const methodChannel = MethodChannel('quietdude.test/event-methods');
    const eventChannel = EventChannel('quietdude.test/events');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late MockStreamHandlerEventSink eventSink;
    late AndroidPlatformAdapter adapter;
    var cancelCount = 0;
    var listenCount = 0;

    setUp(() {
      cancelCount = 0;
      listenCount = 0;
      adapter = AndroidPlatformAdapter(
        channel: PlatformChannel(
          methodChannel: methodChannel,
          eventChannel: eventChannel,
        ),
      );
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            listenCount++;
            eventSink = events;
          },
          onCancel: (arguments) {
            cancelCount++;
          },
        ),
      );
    });

    tearDown(() {
      messenger.setMockStreamHandler(eventChannel, null);
    });

    test('parses sanitized posted and removed events', () async {
      final events = <SanitizedNotificationEvent>[];
      final subscription = adapter.notificationEvents.listen(events.add);
      await Future<void>.delayed(Duration.zero);

      eventSink.success({
        'type': 'posted',
        'package': 'com.example.chat',
        'eventId': 'hashed-id',
        'category': 'msg',
        'postedAt': 1700000000000,
        'hasText': true,
        'isGroupSummary': false,
      });
      eventSink.success({
        'type': 'removed',
        'package': 'com.example.mail',
        'eventId': 'hashed-id-2',
        'category': null,
        'postedAt': 1700000001000,
        'hasText': false,
        'isGroupSummary': true,
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events.first.type, NotificationEventType.posted);
      expect(events.first.packageName, 'com.example.chat');
      expect(events.first.category, 'msg');
      expect(events.first.hasText, isTrue);
      expect(events.last.type, NotificationEventType.removed);
      expect(events.last.isGroupSummary, isTrue);

      await subscription.cancel();
    });

    test('ignores malformed payloads and missing required fields', () async {
      final events = <SanitizedNotificationEvent>[];
      final subscription = adapter.notificationEvents.listen(events.add);
      await Future<void>.delayed(Duration.zero);

      eventSink.success({'type': 'posted'});
      eventSink.success({
        'type': 'unknown',
        'package': 'com.example.chat',
        'eventId': 'id',
        'postedAt': 1,
      });
      eventSink.success({
        'type': 'posted',
        'package': 'com.example.chat',
        'eventId': 'id',
        'postedAt': 1,
      });
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.eventId, 'id');

      await subscription.cancel();
    });

    test('reports stream errors without forwarding native details', () async {
      final expectation = expectLater(
        adapter.notificationEvents,
        emitsError(
          isA<NotificationEventStreamException>().having(
            (error) => error.toString(),
            'message',
            isNot(contains('listener unavailable')),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      eventSink.error(code: 'native_error', message: 'listener unavailable');

      await expectation;
    });

    test(
      'shares one native subscription across concurrent listeners',
      () async {
        final first = <SanitizedNotificationEvent>[];
        final second = <SanitizedNotificationEvent>[];
        final firstSubscription = adapter.notificationEvents.listen(first.add);
        final secondSubscription = adapter.notificationEvents.listen(
          second.add,
        );
        await Future<void>.delayed(Duration.zero);

        eventSink.success({
          'type': 'posted',
          'package': 'com.example.chat',
          'eventId': 'hashed-id',
          'postedAt': 1700000000000,
        });
        await Future<void>.delayed(Duration.zero);

        expect(listenCount, 1);
        expect(first, hasLength(1));
        expect(second, hasLength(1));
        expect(first.single.eventId, second.single.eventId);

        await firstSubscription.cancel();
        await secondSubscription.cancel();
        await Future<void>.delayed(Duration.zero);

        expect(cancelCount, 1);
      },
    );

    test('re-subscribes after the last listener is cancelled', () async {
      final first = <SanitizedNotificationEvent>[];
      final firstSubscription = adapter.notificationEvents.listen(first.add);
      await Future<void>.delayed(Duration.zero);

      await firstSubscription.cancel();
      await Future<void>.delayed(Duration.zero);

      final second = <SanitizedNotificationEvent>[];
      final secondSubscription = adapter.notificationEvents.listen(second.add);
      await Future<void>.delayed(Duration.zero);
      eventSink.success({
        'type': 'removed',
        'package': 'com.example.chat',
        'eventId': 'hashed-id-2',
        'postedAt': 1700000001000,
      });
      await Future<void>.delayed(Duration.zero);

      expect(listenCount, 2);
      expect(first, isEmpty);
      expect(second.single.type, NotificationEventType.removed);

      await secondSubscription.cancel();
    });

    test(
      'cancels the native subscription when the last listener leaves',
      () async {
        final subscription = adapter.notificationEvents.listen((_) {});
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();
        await Future<void>.delayed(Duration.zero);

        expect(cancelCount, 1);
      },
    );
  });

  group('Listener connection status stream', () {
    const methodChannel = MethodChannel('quietdude.test/status-methods');
    const eventChannel = EventChannel('quietdude.test/events');
    const statusChannel = EventChannel('quietdude.test/listener-status');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late MockStreamHandlerEventSink statusSink;
    late AndroidPlatformAdapter adapter;

    setUp(() {
      adapter = AndroidPlatformAdapter(
        channel: PlatformChannel(
          methodChannel: methodChannel,
          eventChannel: eventChannel,
          listenerStatusEventChannel: statusChannel,
        ),
      );
      messenger.setMockStreamHandler(
        statusChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            statusSink = events;
          },
        ),
      );
    });

    tearDown(() {
      messenger.setMockStreamHandler(statusChannel, null);
    });

    test('parses typed connection changes', () async {
      final statuses = <NotificationConnectionStatus>[];
      final subscription = adapter.notificationConnectionEvents.listen(
        statuses.add,
      );
      await Future<void>.delayed(Duration.zero);

      statusSink.success({'connection': 'connected'});
      statusSink.success({'connection': 'disconnected'});
      statusSink.success({'connection': 'unexpected'});
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [
        NotificationConnectionStatus.connected,
        NotificationConnectionStatus.disconnected,
      ]);

      await subscription.cancel();
    });

    test('ignores malformed connection payloads', () async {
      final statuses = <NotificationConnectionStatus>[];
      final subscription = adapter.notificationConnectionEvents.listen(
        statuses.add,
      );
      await Future<void>.delayed(Duration.zero);

      statusSink.success({'connection': 'unexpected'});
      statusSink.success({'other': 'connected'});
      statusSink.success(null);
      statusSink.success({'connection': 'connected'});
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [NotificationConnectionStatus.connected]);

      await subscription.cancel();
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
      final listenerStatus = await adapter.getNotificationListenerStatus();
      expect(listenerStatus.access, NotificationAccessStatus.unsupported);
      expect(await adapter.openNotificationListenerSettings(), isFalse);
      expect(await adapter.notificationEvents.isEmpty, isTrue);
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
