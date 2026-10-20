import '../actions/rule_action.dart';
import '../models/privacy_rule.dart';
import '../models/rule_context.dart';
import '../policy/rule_priority_policy.dart';

class RuleEvaluation {
  const RuleEvaluation({
    required this.context,
    required this.evaluatedRules,
    required this.resolution,
  });

  final RuleContext context;
  final List<PrivacyRule> evaluatedRules;
  final RuleResolution resolution;

  List<PrivacyRule> get matchedRules => resolution.matchedRules;
}

class ExecutionPlan {
  const ExecutionPlan({
    required this.rule,
    required this.actions,
    required this.suppressedRules,
  });

  final PrivacyRule? rule;
  final List<RuleAction> actions;
  final List<PrivacyRule> suppressedRules;

  bool get isEmpty => rule == null || actions.isEmpty;
}

abstract interface class RuleEngine {
  RuleEvaluation evaluate({
    required List<PrivacyRule> rules,
    required RuleContext context,
  });

  ExecutionPlan buildPlan(RuleEvaluation evaluation);
}

class DefaultRuleEngine implements RuleEngine {
  const DefaultRuleEngine({this.policy = const RulePriorityPolicy()});

  final RulePriorityPolicy policy;

  @override
  RuleEvaluation evaluate({
    required List<PrivacyRule> rules,
    required RuleContext context,
  }) {
    final resolution = policy.resolve(rules: rules, context: context);
    return RuleEvaluation(
      context: context,
      evaluatedRules: List.unmodifiable(rules),
      resolution: resolution,
    );
  }

  @override
  ExecutionPlan buildPlan(RuleEvaluation evaluation) {
    final winner = evaluation.resolution.winningRule;
    return ExecutionPlan(
      rule: winner,
      actions: winner == null ? const [] : List.unmodifiable(winner.actions),
      suppressedRules: evaluation.resolution.suppressedRules,
    );
  }
}
