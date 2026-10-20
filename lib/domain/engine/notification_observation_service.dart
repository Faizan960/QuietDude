import '../models/notification_listener.dart';
import '../models/notification_observation.dart';
import '../models/privacy_rule.dart';
import '../models/rule_context.dart';
import 'rule_engine.dart';

/// Evaluates sanitized notification metadata against the existing rule engine.
///
/// This is an observation boundary only: it never submits an enforcement
/// request, mutates platform state, or retains notification content.
class NotificationObservationService {
  const NotificationObservationService({required this.engine});

  final RuleEngine engine;

  NotificationObservation observe({
    required List<PrivacyRule> rules,
    required SanitizedNotificationEvent event,
  }) {
    if (event.type != NotificationEventType.posted) {
      return NotificationObservation(
        event: event,
        evaluation: null,
        plan: null,
      );
    }

    final evaluation = engine.evaluate(
      rules: rules,
      context: RuleContext(
        now: event.postedAt.toLocal(),
        notificationSourcePackage: event.packageName,
      ),
    );

    return NotificationObservation(
      event: event,
      evaluation: evaluation,
      plan: engine.buildPlan(evaluation),
    );
  }
}
