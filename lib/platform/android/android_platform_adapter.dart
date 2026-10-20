import '../../core/logging/diagnostic_logger.dart';
import '../../domain/models/notification_listener.dart';
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
  Stream<SanitizedNotificationEvent>? _notificationEventStream;
  Stream<NotificationConnectionStatus>? _connectionStatusStream;

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
  Future<NotificationListenerStatus> getNotificationListenerStatus() async {
    try {
      final result = await _channel.invokeMethod(
        'getNotificationListenerStatus',
      );
      if (result is! Map || result['access'] is! String) {
        return const NotificationListenerStatus.error();
      }
      final connection = result['connection'];
      return NotificationListenerStatus(
        access: NotificationAccessStatus.fromWireName(
          result['access'] as String,
        ),
        connection: connection is String
            ? NotificationConnectionStatus.fromWireName(connection)
            : NotificationConnectionStatus.unknown,
      );
    } on PlatformChannelException catch (error) {
      _logger.warning('listener_status_failed', {'reason': error.operation});
      return const NotificationListenerStatus.error();
    }
  }

  @override
  Future<bool> openNotificationListenerSettings() async {
    try {
      final result = await _channel.invokeMethod(
        'openNotificationListenerSettings',
      );
      return result == true;
    } on PlatformChannelException catch (error) {
      _logger.warning('listener_settings_failed', {'reason': error.operation});
      return false;
    }
  }

  @override
  Stream<SanitizedNotificationEvent> get notificationEvents {
    return _notificationEventStream ??= _channel.events
        .map(_parseNotificationEvent)
        .where((event) {
          if (event == null) {
            _logger.warning('notification_event_malformed');
          }
          return event != null;
        })
        .cast<SanitizedNotificationEvent>()
        .handleError((error, stackTrace) {
          _logger.warning('notification_event_stream_failed');
          throw const NotificationEventStreamException();
        });
  }

  @override
  Stream<NotificationConnectionStatus> get notificationConnectionEvents {
    return _connectionStatusStream ??= _channel.listenerStatusEvents
        .map(_parseConnectionStatus)
        .where((status) => status != null)
        .cast<NotificationConnectionStatus>()
        .handleError((error, stackTrace) {
          _logger.warning('listener_status_stream_failed');
        });
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

  NotificationConnectionStatus? _parseConnectionStatus(Object? raw) {
    if (raw is! Map || raw['connection'] is! String) {
      return null;
    }
    final status = NotificationConnectionStatus.fromWireName(
      raw['connection'] as String,
    );
    return status == NotificationConnectionStatus.unknown ? null : status;
  }

  SanitizedNotificationEvent? _parseNotificationEvent(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final type = raw['type'];
    final packageName = raw['package'];
    final eventId = raw['eventId'];
    final postedAt = raw['postedAt'];
    if (type is! String ||
        packageName is! String ||
        packageName.trim().isEmpty ||
        eventId is! String ||
        eventId.trim().isEmpty ||
        postedAt is! num ||
        postedAt <= 0) {
      return null;
    }

    final eventType = NotificationEventType.fromWireName(type);
    if (eventType == null) {
      return null;
    }

    final category = raw['category'];
    final milliseconds = postedAt.toInt();
    try {
      return SanitizedNotificationEvent(
        type: eventType,
        packageName: packageName,
        eventId: eventId,
        category: category is String && category.isNotEmpty ? category : null,
        postedAt: DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: true,
        ),
        hasText: raw['hasText'] == true,
        isGroupSummary: raw['isGroupSummary'] == true,
      );
    } catch (_) {
      return null;
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
