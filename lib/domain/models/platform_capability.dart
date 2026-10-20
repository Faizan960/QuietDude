enum PlatformCapabilityId {
  notificationListener('notification_listener', 'Notification access'),
  previewRedaction('preview_redaction', 'Preview redaction'),
  doNotDisturbControl('do_not_disturb_control', 'Do Not Disturb control'),
  notificationDismissal('notification_dismissal', 'Notification dismissal'),
  keywordFiltering('keyword_filtering', 'Keyword filtering'),
  discreetAlerts('discreet_alerts', 'Discreet urgent alerts'),
  geofenceEvents('geofence_events', 'Location / geofence events'),
  wearableProximity('wearable_proximity', 'Wearable proximity');

  const PlatformCapabilityId(this.wireName, this.label);

  final String wireName;
  final String label;

  static PlatformCapabilityId? fromWireName(String value) {
    for (final capability in PlatformCapabilityId.values) {
      if (capability.wireName == value) {
        return capability;
      }
    }
    return null;
  }
}

enum CapabilityStatus {
  planned('planned', 'Planned'),
  scaffolded('scaffolded', 'Scaffolded'),
  implemented('implemented', 'Implemented'),
  requiresPermission('requires_permission', 'Requires permission'),
  partiallySupported('partially_supported', 'Partially supported'),
  unavailable('unavailable', 'Unavailable'),
  unsupported('unsupported', 'Unsupported');

  const CapabilityStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  bool get isExecutable {
    return this == CapabilityStatus.implemented ||
        this == CapabilityStatus.partiallySupported;
  }

  static CapabilityStatus fromWireName(String value) {
    for (final status in CapabilityStatus.values) {
      if (status.wireName == value) {
        return status;
      }
    }
    return CapabilityStatus.planned;
  }
}

class PlatformCapability {
  const PlatformCapability({
    required this.id,
    required this.status,
    required this.detail,
  });

  final PlatformCapabilityId id;
  final CapabilityStatus status;
  final String detail;

  bool get isExecutable => status.isExecutable;
}
