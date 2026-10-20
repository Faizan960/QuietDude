import '../../domain/actions/rule_action.dart';
import '../../domain/models/platform_capability.dart';
import '../../domain/models/rule_execution.dart';

enum PlatformPermission {
  notificationListener('notification_listener'),
  doNotDisturbAccess('do_not_disturb_access'),
  location('location'),
  bluetooth('bluetooth');

  const PlatformPermission(this.wireName);

  final String wireName;

  static PlatformPermission? fromWireName(String value) {
    for (final permission in PlatformPermission.values) {
      if (permission.wireName == value) {
        return permission;
      }
    }
    return null;
  }
}

enum PermissionState {
  granted,
  denied,
  notApplicable,
  unknown;

  static PermissionState fromWireName(String value) {
    return switch (value) {
      'granted' => PermissionState.granted,
      'denied' => PermissionState.denied,
      'not_applicable' => PermissionState.notApplicable,
      _ => PermissionState.unknown,
    };
  }
}

class EnforcementRequest {
  const EnforcementRequest({required this.ruleId, required this.actions});

  final String ruleId;
  final List<RuleActionKind> actions;
}

abstract interface class PlatformAdapter {
  Future<List<PlatformCapability>> getCapabilities();

  Future<PermissionState> checkPermission(PlatformPermission permission);

  Future<bool> requestSettingsAccess(PlatformPermission permission);

  Future<RuleExecutionResult> submitEnforcementRequest(
    EnforcementRequest request,
  );
}
