import '../models/privacy_rule.dart';
import '../models/rule_context.dart';

class RuleResolution {
  const RuleResolution({
    required this.context,
    required this.matchedRules,
    required this.suppressedRules,
    this.winningRule,
  });

  final RuleContext context;
  final List<PrivacyRule> matchedRules;
  final List<PrivacyRule> suppressedRules;
  final PrivacyRule? winningRule;

  bool get hasMatch => winningRule != null;
}

class RulePriorityPolicy {
  const RulePriorityPolicy();

  RuleResolution resolve({
    required Iterable<PrivacyRule> rules,
    required RuleContext context,
  }) {
    final matchedRules =
        rules.where((rule) => rule.matches(context)).toList(growable: false)
          ..sort(_compare);

    if (matchedRules.isEmpty) {
      return RuleResolution(
        context: context,
        matchedRules: const [],
        suppressedRules: const [],
      );
    }

    return RuleResolution(
      context: context,
      matchedRules: matchedRules,
      winningRule: matchedRules.first,
      suppressedRules: matchedRules.skip(1).toList(growable: false),
    );
  }

  int _compare(PrivacyRule a, PrivacyRule b) {
    final priorityOrder = b.priority.rank.compareTo(a.priority.rank);
    if (priorityOrder != 0) {
      return priorityOrder;
    }

    final specificityOrder = b.specificity.compareTo(a.specificity);
    if (specificityOrder != 0) {
      return specificityOrder;
    }

    final recencyOrder = b.updatedAt.compareTo(a.updatedAt);
    if (recencyOrder != 0) {
      return recencyOrder;
    }

    return a.id.compareTo(b.id);
  }
}
