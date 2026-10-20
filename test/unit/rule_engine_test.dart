import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/conditions/rule_condition.dart';
import 'package:quietdude/domain/engine/rule_engine.dart';
import 'package:quietdude/domain/engine/rule_enforcement_service.dart';
import 'package:quietdude/domain/models/rule_context.dart';
import 'package:quietdude/domain/models/rule_execution.dart';
import 'package:quietdude/domain/models/rule_priority.dart';

import '../fixtures/fake_platform_adapter.dart';
import '../fixtures/rule_fixtures.dart';

void main() {
  const engine = DefaultRuleEngine();
  final context = RuleContext(
    now: DateTime.utc(2026, 1, 1, 23, 30),
    foregroundAppPackage: 'com.example.chat',
    wearableNearby: true,
  );

  group('Deterministic rule evaluation', () {
    test('matches condition combinations against the context', () {
      final matching = buildRule(
        id: 'matching',
        conditions: [
          TimeWindowCondition(
            window: TimeWindow(startMinute: 22 * 60, endMinute: 6 * 60),
          ),
          AppCondition(packageName: 'com.example.chat'),
          const WearableNearbyCondition(),
        ],
      );
      final nonMatching = buildRule(
        id: 'non-matching',
        conditions: [AppCondition(packageName: 'com.example.mail')],
      );

      final evaluation = engine.evaluate(
        rules: [matching, nonMatching],
        context: context,
      );

      expect(evaluation.matchedRules.map((rule) => rule.id), ['matching']);
    });

    test('produces the same result for the same input', () {
      final rules = [
        buildRule(id: 'a', priority: RulePriority.normal),
        buildRule(id: 'b', priority: RulePriority.high),
      ];

      final first = engine.evaluate(rules: rules, context: context);
      final second = engine.evaluate(rules: rules, context: context);

      expect(
        first.matchedRules.map((rule) => rule.id).toList(),
        second.matchedRules.map((rule) => rule.id).toList(),
      );
      expect(first.resolution.winningRule?.id, 'b');
    });

    test('notification source package takes precedence for app conditions', () {
      final sourceRule = buildRule(
        id: 'source',
        conditions: [AppCondition(packageName: 'com.example.mail')],
      );
      final foregroundRule = buildRule(
        id: 'foreground',
        conditions: [AppCondition(packageName: 'com.example.chat')],
      );
      final notificationContext = RuleContext(
        now: context.now,
        foregroundAppPackage: 'com.example.chat',
        notificationSourcePackage: 'com.example.mail',
      );

      final evaluation = engine.evaluate(
        rules: [sourceRule, foregroundRule],
        context: notificationContext,
      );

      expect(evaluation.matchedRules.map((rule) => rule.id), ['source']);
    });

    test('ignores disabled rules', () {
      final evaluation = engine.evaluate(
        rules: [
          buildRule(enabled: false),
          buildRule(id: 'rule-2'),
        ],
        context: context,
      );

      expect(evaluation.matchedRules.map((rule) => rule.id), ['rule-2']);
    });
  });

  group('Priority ordering and conflict resolution', () {
    test('higher priority wins regardless of order', () {
      final rules = [
        buildRule(id: 'normal', priority: RulePriority.normal),
        buildRule(id: 'critical', priority: RulePriority.critical),
        buildRule(id: 'high', priority: RulePriority.high),
      ];

      final resolution = engine
          .evaluate(rules: rules, context: context)
          .resolution;

      expect(resolution.winningRule?.id, 'critical');
      expect(resolution.suppressedRules.map((rule) => rule.id).toList(), [
        'high',
        'normal',
      ]);
    });

    test('equal priority is broken by specificity', () {
      final general = buildRule(id: 'general');
      final specific = buildRule(
        id: 'specific',
        conditions: const [AlwaysCondition(), WearableNearbyCondition()],
      );

      final evaluation = engine.evaluate(
        rules: [general, specific],
        context: context,
      );

      expect(evaluation.resolution.winningRule?.id, 'specific');
    });

    test('equal priority and specificity is broken by recency', () {
      final older = buildRule(id: 'older', updatedAt: DateTime.utc(2026, 1, 2));
      final newer = buildRule(id: 'newer', updatedAt: DateTime.utc(2026, 1, 3));

      final evaluation = engine.evaluate(
        rules: [older, newer],
        context: context,
      );

      expect(evaluation.resolution.winningRule?.id, 'newer');
    });

    test('full ties are broken by stable rule identifier', () {
      final ruleB = buildRule(id: 'rule-b');
      final ruleA = buildRule(id: 'rule-a');

      final evaluation = engine.evaluate(
        rules: [ruleB, ruleA],
        context: context,
      );

      expect(evaluation.resolution.winningRule?.id, 'rule-a');
    });

    test('buildPlan uses the winning rule actions', () {
      final winner = buildRule(
        id: 'winner',
        priority: RulePriority.high,
        actions: const [HidePreviewsAction(), SilenceNotificationsAction()],
      );
      final loser = buildRule(
        id: 'loser',
        actions: const [DismissNotificationsAction()],
      );

      final evaluation = engine.evaluate(
        rules: [loser, winner],
        context: context,
      );
      final plan = engine.buildPlan(evaluation);

      expect(plan.rule?.id, 'winner');
      expect(plan.actions.map((action) => action.kind), [
        RuleActionKind.hidePreviews,
        RuleActionKind.silenceNotifications,
      ]);
      expect(plan.suppressedRules.map((rule) => rule.id), ['loser']);
      expect(plan.isEmpty, isFalse);
    });

    test('an empty plan is produced when nothing matches', () {
      final evaluation = engine.evaluate(
        rules: [
          buildRule(
            conditions: [AppCondition(packageName: 'com.example.mail')],
          ),
        ],
        context: context,
      );

      expect(engine.buildPlan(evaluation).isEmpty, isTrue);
    });
  });

  group('Enforcement boundary', () {
    test(
      'an unsupported platform reports unsupported without claiming success',
      () async {
        final adapter = FakePlatformAdapter();
        final service = RuleEnforcementService(
          engine: engine,
          platformAdapter: adapter,
        );

        final result = await service.enforce(
          rules: [buildRule()],
          context: context,
        );

        expect(result.status, RuleExecutionStatus.unsupported);
        expect(result.status.isSuccess, isFalse);
        expect(result.appliedActions, isEmpty);
        expect(result.skippedActions, [RuleActionKind.hidePreviews]);
        expect(adapter.enforcementRequests, 1);
        expect(adapter.lastRequest?.ruleId, 'rule-1');
      },
    );

    test('a permission-required result is preserved', () async {
      final adapter = FakePlatformAdapter(
        enforcementResult: const RuleExecutionResult(
          status: RuleExecutionStatus.permissionRequired,
          ruleId: 'rule-1',
          appliedActions: [],
          skippedActions: [RuleActionKind.hidePreviews],
          message: 'Notification access is required.',
        ),
      );
      final service = RuleEnforcementService(
        engine: engine,
        platformAdapter: adapter,
      );

      final result = await service.enforce(
        rules: [buildRule()],
        context: context,
      );

      expect(result.status, RuleExecutionStatus.permissionRequired);
      expect(result.status.isSuccess, isFalse);
    });

    test('no enforcement request is sent when no rule matches', () async {
      final adapter = FakePlatformAdapter();
      final service = RuleEnforcementService(
        engine: engine,
        platformAdapter: adapter,
      );

      final result = await service.enforce(
        rules: [buildRule(enabled: false)],
        context: context,
      );

      expect(result.status, RuleExecutionStatus.notApplicable);
      expect(adapter.enforcementRequests, 0);
    });
  });
}
