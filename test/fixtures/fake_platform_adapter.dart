import 'package:quietdude/domain/actions/rule_action.dart';
import 'package:quietdude/domain/models/platform_capability.dart';
import 'package:quietdude/domain/models/rule_execution.dart';
import 'package:quietdude/platform/contracts/platform_adapter.dart';

class FakePlatformAdapter implements PlatformAdapter {
  FakePlatformAdapter({
    this.capabilities = const [
      PlatformCapability(
        id: PlatformCapabilityId.notificationListener,
        status: CapabilityStatus.requiresPermission,
        detail: 'Notification access has not been granted.',
      ),
      PlatformCapability(
        id: PlatformCapabilityId.discreetAlerts,
        status: CapabilityStatus.planned,
        detail: 'Not implemented.',
      ),
    ],
    this.enforcementResult,
    this.permissionState = PermissionState.denied,
    this.settingsAccessGranted = false,
  });

  final List<PlatformCapability> capabilities;
  final RuleExecutionResult? enforcementResult;
  final PermissionState permissionState;
  final bool settingsAccessGranted;

  int enforcementRequests = 0;
  EnforcementRequest? lastRequest;

  @override
  Future<List<PlatformCapability>> getCapabilities() async => capabilities;

  @override
  Future<PermissionState> checkPermission(PlatformPermission permission) async {
    return permissionState;
  }

  @override
  Future<bool> requestSettingsAccess(PlatformPermission permission) async {
    return settingsAccessGranted;
  }

  @override
  Future<RuleExecutionResult> submitEnforcementRequest(
    EnforcementRequest request,
  ) async {
    enforcementRequests++;
    lastRequest = request;
    return enforcementResult ??
        RuleExecutionResult(
          status: RuleExecutionStatus.unsupported,
          ruleId: request.ruleId,
          appliedActions: const [],
          skippedActions: List<RuleActionKind>.unmodifiable(request.actions),
          message: 'Enforcement is not implemented in this build.',
        );
  }
}
