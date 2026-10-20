import '../engine/rule_engine.dart';
import 'notification_listener.dart';

class NotificationObservation {
  const NotificationObservation({
    required this.event,
    required this.evaluation,
    required this.plan,
  });

  final SanitizedNotificationEvent event;
  final RuleEvaluation? evaluation;
  final ExecutionPlan? plan;

  bool get evaluated => evaluation != null;

  bool get hasMatchingRule => plan != null && !plan!.isEmpty;
}
