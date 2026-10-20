import '../../domain/actions/rule_action.dart';
import '../../domain/models/notification_listener.dart';
import '../../domain/models/platform_capability.dart';
import '../../domain/models/rule_execution.dart';
import '../contracts/platform_adapter.dart';

class IosPlatformAdapter implements PlatformAdapter {
  const IosPlatformAdapter();

  @override
  Future<List<PlatformCapability>> getCapabilities() async {
    return const [
      PlatformCapability(
        id: PlatformCapabilityId.notificationListener,
        status: CapabilityStatus.unsupported,
        detail:
            'iOS does not expose other applications\' notifications to third-party apps.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.previewRedaction,
        status: CapabilityStatus.unsupported,
        detail:
            'Cross-app notification rewriting is not possible on iOS. A future '
            'Notification Service Extension could only alter Quietdude\'s own notifications.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.doNotDisturbControl,
        status: CapabilityStatus.unsupported,
        detail: 'Focus modes cannot be controlled by a third-party app.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.notificationDismissal,
        status: CapabilityStatus.unsupported,
        detail:
            'Other applications\' delivered notifications cannot be dismissed.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.keywordFiltering,
        status: CapabilityStatus.partiallySupported,
        detail:
            'Only Quietdude\'s own notifications can be filtered by an app extension; '
            'this is not universal interception.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.discreetAlerts,
        status: CapabilityStatus.planned,
        detail: 'Planned for Quietdude-owned notifications only.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.geofenceEvents,
        status: CapabilityStatus.planned,
        detail:
            'Core Location region monitoring is planned but not implemented.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.wearableProximity,
        status: CapabilityStatus.planned,
        detail: 'Core Bluetooth proximity is planned but not implemented.',
      ),
    ];
  }

  @override
  Future<PermissionState> checkPermission(PlatformPermission permission) async {
    return PermissionState.notApplicable;
  }

  @override
  Future<bool> requestSettingsAccess(PlatformPermission permission) async {
    return false;
  }

  @override
  Future<NotificationListenerStatus> getNotificationListenerStatus() async {
    return const NotificationListenerStatus.unsupported();
  }

  @override
  Future<bool> openNotificationListenerSettings() async {
    return false;
  }

  @override
  Stream<SanitizedNotificationEvent> get notificationEvents {
    return const Stream<SanitizedNotificationEvent>.empty();
  }

  @override
  Stream<NotificationConnectionStatus> get notificationConnectionEvents {
    return const Stream<NotificationConnectionStatus>.empty();
  }

  @override
  Future<RuleExecutionResult> submitEnforcementRequest(
    EnforcementRequest request,
  ) async {
    return RuleExecutionResult(
      status: RuleExecutionStatus.unsupported,
      ruleId: request.ruleId,
      appliedActions: const [],
      skippedActions: List<RuleActionKind>.unmodifiable(request.actions),
      message:
          'Notification enforcement is not supported on iOS for third-party apps.',
    );
  }
}
