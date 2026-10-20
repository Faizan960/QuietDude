import '../actions/rule_action.dart';
import '../conditions/rule_condition.dart';
import 'rule_context.dart';
import 'rule_priority.dart';

class PrivacyRule {
  PrivacyRule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.priority,
    required this.conditions,
    required this.actions,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty.');
    }
    if (trimmedName.length > 80) {
      throw ArgumentError.value(
        name,
        'name',
        'Must be 80 characters or fewer.',
      );
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Must not be before createdAt.',
      );
    }
  }

  final String id;
  final String name;
  final bool enabled;
  final RulePriority priority;
  final List<RuleCondition> conditions;
  final List<RuleAction> actions;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => enabled && conditions.isNotEmpty && actions.isNotEmpty;

  int get specificity => conditions.length;

  bool matches(RuleContext context) {
    if (!enabled || conditions.isEmpty) {
      return false;
    }
    return conditions.every((condition) => condition.matches(context));
  }

  PrivacyRule copyWith({
    String? name,
    bool? enabled,
    RulePriority? priority,
    List<RuleCondition>? conditions,
    List<RuleAction>? actions,
    DateTime? updatedAt,
  }) {
    return PrivacyRule(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
