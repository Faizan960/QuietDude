import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/conditions/rule_condition.dart';
import 'package:quietdude/domain/models/privacy_rule.dart';
import 'package:quietdude/domain/models/rule_priority.dart';

final testCreatedAt = DateTime.utc(2026, 1, 1);
final testUpdatedAt = DateTime.utc(2026, 1, 2);

PrivacyRule buildRule({
  String id = 'rule-1',
  String name = 'Hide previews',
  bool enabled = true,
  RulePriority priority = RulePriority.normal,
  List<RuleCondition> conditions = const <RuleCondition>[AlwaysCondition()],
  List<RuleAction> actions = const <RuleAction>[HidePreviewsAction()],
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return PrivacyRule(
    id: id,
    name: name,
    enabled: enabled,
    priority: priority,
    conditions: conditions,
    actions: actions,
    createdAt: createdAt ?? testCreatedAt,
    updatedAt: updatedAt ?? testUpdatedAt,
  );
}
