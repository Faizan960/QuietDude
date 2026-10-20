import '../domain/actions/rule_action.dart';
import '../domain/models/platform_capability.dart';
import '../domain/models/rule_execution.dart';
import 'contracts/platform_adapter.dart';

class UnsupportedPlatformAdapter implements PlatformAdapter {
  const UnsupportedPlatformAdapter({required this.platformLabel});

  final String platformLabel;

  @override
  Future<List<PlatformCapability>> getCapabilities() async {
    return PlatformCapabilityId.values
        .map((id) {
          return PlatformCapability(
            id: id,
            status: CapabilityStatus.planned,
            detail: 'Not available on $platformLabel in the Android-first MVP.',
          );
        })
        .toList(growable: false);
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
  Future<RuleExecutionResult> submitEnforcementRequest(
    EnforcementRequest request,
  ) async {
    return RuleExecutionResult(
      status: RuleExecutionStatus.unsupported,
      ruleId: request.ruleId,
      appliedActions: const [],
      skippedActions: List<RuleActionKind>.unmodifiable(request.actions),
      message: 'Enforcement is not available on $platformLabel.',
    );
  }
}
