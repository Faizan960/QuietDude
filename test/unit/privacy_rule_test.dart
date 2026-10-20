import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/conditions/rule_condition.dart';
import 'package:quietdude/domain/models/privacy_rule.dart';
import 'package:quietdude/domain/models/rule_context.dart';
import 'package:quietdude/domain/models/rule_priority.dart';

import '../fixtures/rule_fixtures.dart';

void main() {
  group('PrivacyRule construction', () {
    test('accepts valid values and exposes them', () {
      final rule = buildRule(name: 'Hide previews at work');

      expect(rule.id, 'rule-1');
      expect(rule.name, 'Hide previews at work');
      expect(rule.priority, RulePriority.normal);
      expect(rule.conditions, hasLength(1));
      expect(rule.actions, hasLength(1));
      expect(rule.isActive, isTrue);
    });

    test('rejects an empty identifier', () {
      expect(() => buildRule(id: '   '), throwsArgumentError);
    });

    test('rejects an empty or whitespace-only name', () {
      expect(() => buildRule(name: '   '), throwsArgumentError);
    });

    test('rejects names longer than 80 characters', () {
      expect(() => buildRule(name: 'a' * 81), throwsArgumentError);
    });

    test('rejects an update timestamp before creation', () {
      expect(
        () => PrivacyRule(
          id: 'rule-1',
          name: 'Rule',
          enabled: true,
          priority: RulePriority.normal,
          conditions: const [AlwaysCondition()],
          actions: const [HidePreviewsAction()],
          createdAt: DateTime.utc(2026, 2, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('PrivacyRule enable and disable behavior', () {
    test('a disabled rule never matches', () {
      final rule = buildRule(enabled: false);
      final context = RuleContext(now: DateTime.utc(2026, 1, 1, 12));

      expect(rule.matches(context), isFalse);
    });

    test('an enabled rule with matching conditions matches', () {
      final rule = buildRule();
      final context = RuleContext(now: DateTime.utc(2026, 1, 1, 12));

      expect(rule.matches(context), isTrue);
    });

    test('copyWith toggles enabled while preserving identity and rules', () {
      final rule = buildRule();
      final disabled = rule.copyWith(
        enabled: false,
        updatedAt: DateTime.utc(2026, 1, 3),
      );

      expect(disabled.enabled, isFalse);
      expect(disabled.id, rule.id);
      expect(disabled.name, rule.name);
      expect(disabled.conditions, same(rule.conditions));
      expect(disabled.actions, same(rule.actions));
      expect(disabled.updatedAt, DateTime.utc(2026, 1, 3));
    });

    test('a rule without actions is not considered active', () {
      final rule = buildRule(actions: const []);
      expect(rule.isActive, isFalse);
    });

    test('a rule without conditions never matches', () {
      final rule = buildRule(conditions: const []);
      final context = RuleContext(now: DateTime.utc(2026, 1, 1, 12));

      expect(rule.matches(context), isFalse);
      expect(rule.isActive, isFalse);
    });
  });

  group('Condition evaluation', () {
    test('time window handles daytime ranges', () {
      final condition = TimeWindowCondition(
        window: TimeWindow(startMinute: 9 * 60, endMinute: 17 * 60),
      );

      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 9))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 16, 59))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 17))),
        isFalse,
      );
    });

    test('time window handles ranges across midnight', () {
      final condition = TimeWindowCondition(
        window: TimeWindow(startMinute: 22 * 60, endMinute: 6 * 60),
      );

      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 23))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 5))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 12))),
        isFalse,
      );
    });

    test('time window starts inclusively and ends exclusively', () {
      final condition = TimeWindowCondition(
        window: TimeWindow(startMinute: 9 * 60, endMinute: 17 * 60),
      );

      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 8, 59))),
        isFalse,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 9))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 16, 59))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 17))),
        isFalse,
      );
    });

    test('cross-midnight boundaries are start-inclusive and end-exclusive', () {
      final condition = TimeWindowCondition(
        window: TimeWindow(startMinute: 22 * 60, endMinute: 6 * 60),
      );

      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 21, 59))),
        isFalse,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 22))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 2, 5, 59))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 2, 6))),
        isFalse,
      );
    });

    test('equal endpoints retain all-day compatibility semantics', () {
      final condition = TimeWindowCondition(
        window: TimeWindow(startMinute: 0, endMinute: 0),
      );

      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1))),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1, 23, 59))),
        isTrue,
      );
    });

    test('time window uses the supplied local wall-clock fields', () {
      final condition = TimeWindowCondition(
        window: TimeWindow(startMinute: 9 * 60, endMinute: 17 * 60),
      );
      final local = DateTime(2026, 3, 8, 9, 15);

      expect(condition.matches(RuleContext(now: local)), isTrue);
    });

    test('time window rejects out-of-range or incomplete bounds', () {
      expect(
        () => TimeWindow(startMinute: -1, endMinute: 60),
        throwsArgumentError,
      );
      expect(
        () => TimeWindow(startMinute: 0, endMinute: 1440),
        throwsArgumentError,
      );
      expect(
        () => TimeWindow(startMinute: 1440, endMinute: 0),
        throwsArgumentError,
      );
    });

    test('app condition compares the foreground package', () {
      final condition = AppCondition(packageName: 'com.example.chat');

      expect(
        condition.matches(
          RuleContext(
            now: DateTime.utc(2026, 1, 1),
            foregroundAppPackage: 'com.example.chat',
          ),
        ),
        isTrue,
      );
      expect(
        condition.matches(
          RuleContext(
            now: DateTime.utc(2026, 1, 1),
            foregroundAppPackage: 'com.example.mail',
          ),
        ),
        isFalse,
      );
    });

    test('wearable condition follows the context flag', () {
      const condition = WearableNearbyCondition();

      expect(
        condition.matches(
          RuleContext(now: DateTime.utc(2026, 1, 1), wearableNearby: true),
        ),
        isTrue,
      );
      expect(
        condition.matches(RuleContext(now: DateTime.utc(2026, 1, 1))),
        isFalse,
      );
    });
  });
}
