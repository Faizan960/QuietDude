import '../../platform/contracts/platform_adapter.dart';
import '../models/privacy_rule.dart';
import '../models/rule_context.dart';
import '../models/rule_execution.dart';
import 'rule_engine.dart';

class RuleEnforcementService {
  const RuleEnforcementService({
    required this.engine,
    required this.platformAdapter,
  });

  final RuleEngine engine;
  final PlatformAdapter platformAdapter;

  Future<RuleExecutionResult> enforce({
    required List<PrivacyRule> rules,
    required RuleContext context,
  }) async {
    final evaluation = engine.evaluate(rules: rules, context: context);
    final plan = engine.buildPlan(evaluation);

    if (plan.isEmpty) {
      return RuleExecutionResult.notApplicable(ruleId: plan.rule?.id);
    }

    return platformAdapter.submitEnforcementRequest(
      EnforcementRequest(
        ruleId: plan.rule!.id,
        actions: plan.actions.map((action) => action.kind).toList(),
      ),
    );
  }
}
