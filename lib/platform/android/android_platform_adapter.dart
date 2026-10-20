import '../../core/logging/diagnostic_logger.dart';
import '../../domain/models/platform_capability.dart';
import '../../domain/models/rule_execution.dart';
import '../contracts/platform_adapter.dart';
import '../contracts/platform_channel.dart';

class AndroidPlatformAdapter implements PlatformAdapter {
  AndroidPlatformAdapter({
    PlatformChannel? channel,
    DiagnosticLogger logger = const DiagnosticLogger('platform/android'),
  }) : _channel = channel ?? PlatformChannel(),
       _logger = logger;

  final PlatformChannel _channel;
  final DiagnosticLogger _logger;

  @override
  Future<List<PlatformCapability>> getCapabilities() async {
    try {
      final raw = await _channel.invokeListMethod('getCapabilities');
      if (raw == null) {
        return _unavailableCapabilities;
      }
      final parsed = raw
          .whereType<Map<Object?, Object?>>()
          .map(_parseCapability)
          .whereType<PlatformCapability>()
          .toList(growable: false);
      return parsed.isEmpty ? _unavailableCapabilities : parsed;
    } on PlatformChannelException catch (error) {
      _logger.warning('capabilities_unavailable', {'reason': error.operation});
      return _unavailableCapabilities;
    }
  }

  @override
  Future<PermissionState> checkPermission(PlatformPermission permission) async {
    try {
      final result = await _channel.invokeMethod('checkPermission', {
        'permission': permission.wireName,
      });
      if (result is Map && result['state'] is String) {
        return PermissionState.fromWireName(result['state'] as String);
      }
      return PermissionState.unknown;
    } on PlatformChannelException catch (error) {
      _logger.warning('permission_check_failed', {'reason': error.operation});
      return PermissionState.unknown;
    }
  }

  @override
  Future<bool> requestSettingsAccess(PlatformPermission permission) async {
    try {
      final result = await _channel.invokeMethod('openSettings', {
        'permission': permission.wireName,
      });
      return result == true;
    } on PlatformChannelException catch (error) {
      _logger.warning('settings_access_failed', {'reason': error.operation});
      return false;
    }
  }

  @override
  Future<RuleExecutionResult> submitEnforcementRequest(
    EnforcementRequest request,
  ) async {
    try {
      final result = await _channel.invokeMethod('submitEnforcementRequest', {
        'ruleId': request.ruleId,
        'actions': request.actions.map((action) => action.wireName).toList(),
      });
      if (result is Map) {
        return _parseExecutionResult(result, request);
      }
      return _failedResult(request, 'Malformed native response.');
    } on PlatformChannelException catch (error) {
      _logger.warning('enforcement_failed', {'reason': error.operation});
      return _failedResult(request, 'Native enforcement bridge unavailable.');
    }
  }

  PlatformCapability? _parseCapability(Map<Object?, Object?> raw) {
    final id = raw['id'];
    final status = raw['status'];
    final detail = raw['detail'];
    if (id is! String || status is! String) {
      return null;
    }
    final capabilityId = PlatformCapabilityId.fromWireName(id);
    if (capabilityId == null) {
      return null;
    }
    return PlatformCapability(
      id: capabilityId,
      status: CapabilityStatus.fromWireName(status),
      detail: detail is String ? detail : 'No detail provided.',
    );
  }

  RuleExecutionResult _parseExecutionResult(
    Map<Object?, Object?> raw,
    EnforcementRequest request,
  ) {
    final status = switch (raw['status']) {
      'applied' => RuleExecutionStatus.applied,
      'partially_applied' => RuleExecutionStatus.partiallyApplied,
      'unsupported' => RuleExecutionStatus.unsupported,
      'permission_required' => RuleExecutionStatus.permissionRequired,
      _ => RuleExecutionStatus.failed,
    };
    final message = raw['message'];
    return RuleExecutionResult(
      status: status,
      ruleId: request.ruleId,
      appliedActions: status.isSuccess ? request.actions : const [],
      skippedActions: status.isSuccess ? const [] : request.actions,
      message: message is String ? message : null,
    );
  }

  RuleExecutionResult _failedResult(
    EnforcementRequest request,
    String message,
  ) {
    return RuleExecutionResult(
      status: RuleExecutionStatus.failed,
      ruleId: request.ruleId,
      appliedActions: const [],
      skippedActions: request.actions,
      message: message,
    );
  }

  List<PlatformCapability> get _unavailableCapabilities {
    return PlatformCapabilityId.values
        .map((id) {
          return PlatformCapability(
            id: id,
            status: CapabilityStatus.planned,
            detail: 'Capability information is unavailable in this build.',
          );
        })
        .toList(growable: false);
  }
}
