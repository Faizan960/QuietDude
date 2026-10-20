import 'package:drift/drift.dart';

import '../../core/errors/rule_storage_exception.dart';
import '../../core/logging/diagnostic_logger.dart';
import '../../domain/actions/rule_action.dart';
import '../../domain/conditions/rule_condition.dart';
import '../../domain/models/privacy_rule.dart';
import '../../domain/models/rule_priority.dart';
import '../database/app_database.dart';
import 'rule_repository.dart';

class DriftRuleRepository implements RuleRepository {
  DriftRuleRepository(
    this._database, {
    DiagnosticLogger logger = const DiagnosticLogger('data/rules'),
  }) : _logger = logger;

  final AppDatabase _database;
  final DiagnosticLogger _logger;

  @override
  Stream<List<PrivacyRule>> watchRules() {
    final query = _database.select(_database.privacyRules)
      ..orderBy([
        (table) => OrderingTerm.desc(table.priorityRank),
        (table) => OrderingTerm.desc(table.updatedAt),
      ]);
    return query.watch().asyncMap((rows) async {
      final rules = <PrivacyRule>[];
      for (final row in rows) {
        final rule = await _loadRule(row);
        if (rule != null) {
          rules.add(rule);
        }
      }
      return rules;
    });
  }

  @override
  Future<List<PrivacyRule>> getRules() async {
    final query = _database.select(_database.privacyRules)
      ..orderBy([
        (table) => OrderingTerm.desc(table.priorityRank),
        (table) => OrderingTerm.desc(table.updatedAt),
      ]);
    final rows = await query.get();
    final rules = <PrivacyRule>[];
    for (final row in rows) {
      final rule = await _loadRule(row);
      if (rule != null) {
        rules.add(rule);
      }
    }
    return rules;
  }

  @override
  Future<PrivacyRule?> findById(String id) async {
    final query = _database.select(_database.privacyRules)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _loadRule(row);
  }

  @override
  Future<void> upsert(PrivacyRule rule) async {
    try {
      await _database.transaction(() async {
        await _database
            .into(_database.privacyRules)
            .insertOnConflictUpdate(
              PrivacyRulesCompanion.insert(
                id: rule.id,
                name: rule.name.trim(),
                enabled: Value(rule.enabled),
                priorityRank: rule.priority.rank,
                createdAt: rule.createdAt.toUtc(),
                updatedAt: rule.updatedAt.toUtc(),
              ),
            );

        await (_database.delete(
          _database.ruleConditionRows,
        )..where((table) => table.ruleId.equals(rule.id))).go();
        await (_database.delete(
          _database.ruleActionRows,
        )..where((table) => table.ruleId.equals(rule.id))).go();

        for (var index = 0; index < rule.conditions.length; index++) {
          final condition = rule.conditions[index];
          await _database
              .into(_database.ruleConditionRows)
              .insert(
                RuleConditionRowsCompanion.insert(
                  id: '${rule.id}:condition:$index',
                  ruleId: rule.id,
                  kind: condition.kind.wireName,
                  startMinute: Value(_startMinuteFor(condition)),
                  endMinute: Value(_endMinuteFor(condition)),
                  value: Value(_valueFor(condition)),
                ),
              );
        }

        for (var index = 0; index < rule.actions.length; index++) {
          final action = rule.actions[index];
          await _database
              .into(_database.ruleActionRows)
              .insert(
                RuleActionRowsCompanion.insert(
                  id: '${rule.id}:action:$index',
                  ruleId: rule.id,
                  kind: action.kind.wireName,
                ),
              );
        }
      });
    } on Exception catch (error) {
      _logger.warning('rule_upsert_failed', {'ruleId': rule.id});
      throw RuleStorageException('upsert', error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_database.delete(
        _database.privacyRules,
      )..where((table) => table.id.equals(id))).go();
    } on Exception catch (error) {
      _logger.warning('rule_delete_failed', {'ruleId': id});
      throw RuleStorageException('delete', error);
    }
  }

  Future<PrivacyRule?> _loadRule(PrivacyRuleRow row) async {
    final conditionRows =
        await (_database.select(_database.ruleConditionRows)
              ..where((table) => table.ruleId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.id)]))
            .get();
    final actionRows =
        await (_database.select(_database.ruleActionRows)
              ..where((table) => table.ruleId.equals(row.id))
              ..orderBy([(table) => OrderingTerm.asc(table.id)]))
            .get();

    final conditions = <RuleCondition>[];
    for (final conditionRow in conditionRows) {
      final condition = _conditionFromRow(conditionRow);
      if (condition == null) {
        _logger.warning('unknown_condition_skipped', {'ruleId': row.id});
        continue;
      }
      conditions.add(condition);
    }

    final actions = <RuleAction>[];
    for (final actionRow in actionRows) {
      final action = _actionFromRow(actionRow);
      if (action == null) {
        _logger.warning('unknown_action_skipped', {'ruleId': row.id});
        continue;
      }
      actions.add(action);
    }

    try {
      return PrivacyRule(
        id: row.id,
        name: row.name,
        enabled: row.enabled,
        priority: RulePriority.fromRank(row.priorityRank),
        conditions: List.unmodifiable(conditions),
        actions: List.unmodifiable(actions),
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );
    } on ArgumentError {
      _logger.warning('invalid_rule_row_skipped', {'ruleId': row.id});
      return null;
    }
  }

  RuleCondition? _conditionFromRow(RuleConditionRow row) {
    final kind = RuleConditionKind.fromWireName(row.kind);
    if (kind == null) {
      return null;
    }
    return switch (kind) {
      RuleConditionKind.always => const AlwaysCondition(),
      RuleConditionKind.timeWindow =>
        row.startMinute == null || row.endMinute == null
            ? null
            : TimeWindowCondition(
                window: TimeWindow(
                  startMinute: row.startMinute!,
                  endMinute: row.endMinute!,
                ),
              ),
      RuleConditionKind.app =>
        row.value == null || row.value!.isEmpty
            ? null
            : AppCondition(packageName: row.value!),
      RuleConditionKind.wearableNearby => const WearableNearbyCondition(),
    };
  }

  RuleAction? _actionFromRow(RuleActionRow row) {
    final kind = RuleActionKind.fromWireName(row.kind);
    return switch (kind) {
      RuleActionKind.hidePreviews => const HidePreviewsAction(),
      RuleActionKind.silenceNotifications => const SilenceNotificationsAction(),
      RuleActionKind.dismissNotifications => const DismissNotificationsAction(),
      RuleActionKind.discreetAlert => const DiscreetAlertAction(),
      null => null,
    };
  }

  int? _startMinuteFor(RuleCondition condition) {
    return condition is TimeWindowCondition
        ? condition.window.startMinute
        : null;
  }

  int? _endMinuteFor(RuleCondition condition) {
    return condition is TimeWindowCondition ? condition.window.endMinute : null;
  }

  String? _valueFor(RuleCondition condition) {
    return condition is AppCondition ? condition.packageName : null;
  }
}
