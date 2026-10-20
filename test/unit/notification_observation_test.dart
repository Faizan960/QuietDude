import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/domain/conditions/rule_condition.dart';
import 'package:quietdude/domain/engine/notification_observation_service.dart';
import 'package:quietdude/domain/engine/rule_engine.dart';
import 'package:quietdude/domain/models/notification_listener.dart';

import '../fixtures/rule_fixtures.dart';

void main() {
  const engine = DefaultRuleEngine();
  const service = NotificationObservationService(engine: engine);

  SanitizedNotificationEvent event({
    NotificationEventType type = NotificationEventType.posted,
    String packageName = 'com.example.chat',
    DateTime? postedAt,
  }) {
    return SanitizedNotificationEvent(
      type: type,
      packageName: packageName,
      eventId: 'hashed-event-id',
      category: 'msg',
      postedAt: postedAt ?? DateTime.utc(2026, 1, 1, 23, 30),
      hasText: true,
      isGroupSummary: false,
    );
  }

  test('evaluates posted metadata against app-scoped rules', () {
    final rule = buildRule(
      name: 'Chat focus',
      conditions: [AppCondition(packageName: 'com.example.chat')],
    );

    final observation = service.observe(rules: [rule], event: event());

    expect(observation.evaluated, isTrue);
    expect(observation.plan?.rule?.id, rule.id);
    expect(observation.hasMatchingRule, isTrue);
  });

  test('notification source package takes precedence over foreground app', () {
    final observation = service.observe(
      rules: [
        buildRule(conditions: [AppCondition(packageName: 'com.example.chat')]),
      ],
      event: event(packageName: 'com.example.chat'),
    );

    expect(observation.plan?.rule, isNotNull);
  });

  test('removal events are observed but not evaluated', () {
    final observation = service.observe(
      rules: [buildRule()],
      event: event(type: NotificationEventType.removed),
    );

    expect(observation.evaluated, isFalse);
    expect(observation.plan, isNull);
    expect(observation.event.type, NotificationEventType.removed);
  });

  test('non-matching app rules produce an empty plan', () {
    final observation = service.observe(
      rules: [
        buildRule(conditions: [AppCondition(packageName: 'com.example.mail')]),
      ],
      event: event(),
    );

    expect(observation.evaluated, isTrue);
    expect(observation.hasMatchingRule, isFalse);
  });

  test(
    'time windows evaluate the sanitized instant as local wall-clock time',
    () {
      final localPostedAt = DateTime(2026, 1, 1, 23, 30);
      final observation = service.observe(
        rules: [
          buildRule(
            conditions: [
              TimeWindowCondition(
                window: TimeWindow(
                  startMinute: 23 * 60,
                  endMinute: 24 * 60 - 1,
                ),
              ),
            ],
          ),
        ],
        event: event(postedAt: localPostedAt.toUtc()),
      );

      expect(observation.evaluated, isTrue);
      expect(observation.hasMatchingRule, isTrue);
    },
  );
}
