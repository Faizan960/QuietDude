import '../models/platform_capability.dart';

enum RuleActionKind {
  hidePreviews(
    'hide_previews',
    'Hide previews',
    PlatformCapabilityId.previewRedaction,
  ),
  silenceNotifications(
    'silence_notifications',
    'Silence notifications',
    PlatformCapabilityId.doNotDisturbControl,
  ),
  dismissNotifications(
    'dismiss_notifications',
    'Dismiss notifications',
    PlatformCapabilityId.notificationDismissal,
  ),
  discreetAlert(
    'discreet_alert',
    'Allow discreet alert',
    PlatformCapabilityId.discreetAlerts,
  );

  const RuleActionKind(this.wireName, this.label, this.requiredCapability);

  final String wireName;
  final String label;
  final PlatformCapabilityId requiredCapability;

  static RuleActionKind? fromWireName(String value) {
    for (final kind in RuleActionKind.values) {
      if (kind.wireName == value) {
        return kind;
      }
    }
    return null;
  }
}

sealed class RuleAction {
  const RuleAction();

  RuleActionKind get kind;
}

final class HidePreviewsAction extends RuleAction {
  const HidePreviewsAction();

  @override
  RuleActionKind get kind => RuleActionKind.hidePreviews;
}

final class SilenceNotificationsAction extends RuleAction {
  const SilenceNotificationsAction();

  @override
  RuleActionKind get kind => RuleActionKind.silenceNotifications;
}

final class DismissNotificationsAction extends RuleAction {
  const DismissNotificationsAction();

  @override
  RuleActionKind get kind => RuleActionKind.dismissNotifications;
}

final class DiscreetAlertAction extends RuleAction {
  const DiscreetAlertAction();

  @override
  RuleActionKind get kind => RuleActionKind.discreetAlert;
}
