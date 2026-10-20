import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quietdude/data/database/app_database.dart';
import 'package:quietdude/data/repositories/drift_rule_repository.dart';
import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/conditions/rule_condition.dart';
import 'package:quietdude/domain/models/rule_priority.dart';

import '../fixtures/rule_fixtures.dart';
import '../fixtures/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  late AppDatabase database;
  late DriftRuleRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftRuleRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('RuleRepository CRUD', () {
    test('create and read a rule with typed conditions and actions', () async {
      final rule = buildRule(
        name: 'Work focus',
        priority: RulePriority.high,
        conditions: [
          TimeWindowCondition(
            window: TimeWindow(startMinute: 9 * 60, endMinute: 17 * 60),
          ),
          AppCondition(packageName: 'com.example.chat'),
          const WearableNearbyCondition(),
        ],
        actions: const [HidePreviewsAction(), SilenceNotificationsAction()],
      );

      await repository.upsert(rule);

      final stored = await repository.findById(rule.id);
      expect(stored, isNotNull);
      expect(stored!.name, 'Work focus');
      expect(stored.enabled, isTrue);
      expect(stored.priority, RulePriority.high);
      expect(stored.createdAt, rule.createdAt);
      expect(stored.updatedAt, rule.updatedAt);
      expect(stored.conditions, hasLength(3));
      expect(stored.conditions[0], isA<TimeWindowCondition>());
      expect(
        (stored.conditions[0] as TimeWindowCondition).window.startMinute,
        9 * 60,
      );
      expect(stored.conditions[1], isA<AppCondition>());
      expect(
        (stored.conditions[1] as AppCondition).packageName,
        'com.example.chat',
      );
      expect(stored.conditions[2], isA<WearableNearbyCondition>());
      expect(stored.actions.map((action) => action.kind), [
        RuleActionKind.hidePreviews,
        RuleActionKind.silenceNotifications,
      ]);
    });

    test('update replaces fields and child rows', () async {
      final original = buildRule();
      await repository.upsert(original);

      final updated = original.copyWith(
        name: 'Updated rule',
        enabled: false,
        priority: RulePriority.critical,
        conditions: [AppCondition(packageName: 'com.example.mail')],
        actions: const [DismissNotificationsAction()],
        updatedAt: DateTime.utc(2026, 3, 1),
      );
      await repository.upsert(updated);

      final stored = await repository.findById(original.id);
      expect(stored, isNotNull);
      expect(stored!.name, 'Updated rule');
      expect(stored.enabled, isFalse);
      expect(stored.priority, RulePriority.critical);
      expect(stored.conditions, hasLength(1));
      expect(stored.conditions.single, isA<AppCondition>());
      expect(stored.actions, hasLength(1));
      expect(stored.actions.single.kind, RuleActionKind.dismissNotifications);
    });

    test('lists rules ordered by priority', () async {
      await repository.upsert(buildRule(id: 'low', priority: RulePriority.low));
      await repository.upsert(
        buildRule(id: 'critical', priority: RulePriority.critical),
      );
      await repository.upsert(
        buildRule(id: 'normal', priority: RulePriority.normal),
      );

      final rules = await repository.getRules();

      expect(rules.map((rule) => rule.id), ['critical', 'normal', 'low']);
    });

    test('delete removes the rule and its child rows', () async {
      final rule = buildRule();
      await repository.upsert(rule);

      await repository.delete(rule.id);

      expect(await repository.findById(rule.id), isNull);
      expect(await repository.getRules(), isEmpty);
      final conditionRows = await database
          .select(database.ruleConditionRows)
          .get();
      final actionRows = await database.select(database.ruleActionRows).get();
      expect(conditionRows, isEmpty);
      expect(actionRows, isEmpty);
    });
  });

  group('Database persistence', () {
    test('rules survive closing and reopening the database file', () async {
      final directory = await Directory.systemTemp.createTemp(
        'quietdude_persistence',
      );
      final file = File(p.join(directory.path, 'rules.sqlite'));
      final rule = buildRule(name: 'Persisted rule');

      final firstDatabase = AppDatabase(NativeDatabase(file));
      try {
        await DriftRuleRepository(firstDatabase).upsert(rule);
      } finally {
        await firstDatabase.close();
      }

      final secondDatabase = AppDatabase(NativeDatabase(file));
      try {
        final rules = await DriftRuleRepository(secondDatabase).getRules();
        expect(rules, hasLength(1));
        expect(rules.single.id, rule.id);
        expect(rules.single.name, 'Persisted rule');
      } finally {
        await secondDatabase.close();
        await directory.delete(recursive: true);
      }
    });
  });
}
