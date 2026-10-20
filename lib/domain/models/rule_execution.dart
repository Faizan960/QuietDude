import '../actions/rule_action.dart';

enum RuleExecutionStatus {
  applied('Applied'),
  partiallyApplied('Partially applied'),
  unsupported('Unsupported'),
  permissionRequired('Permission required'),
  failed('Failed'),
  notApplicable('Not applicable');

  const RuleExecutionStatus(this.label);

  final String label;

  bool get isSuccess {
    return this == RuleExecutionStatus.applied ||
        this == RuleExecutionStatus.partiallyApplied;
  }
}

class RuleExecutionResult {
  const RuleExecutionResult({
    required this.status,
    required this.appliedActions,
    required this.skippedActions,
    this.ruleId,
    this.message,
  });

  final RuleExecutionStatus status;
  final String? ruleId;
  final List<RuleActionKind> appliedActions;
  final List<RuleActionKind> skippedActions;
  final String? message;

  factory RuleExecutionResult.notApplicable({
    String? ruleId,
    String message = 'No enabled rule matches the current context.',
  }) {
    return RuleExecutionResult(
      status: RuleExecutionStatus.notApplicable,
      ruleId: ruleId,
      appliedActions: const [],
      skippedActions: const [],
      message: message,
    );
  }
}
