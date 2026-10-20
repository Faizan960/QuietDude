enum NotificationAccessStatus {
  granted('granted', 'Access granted'),
  notGranted('not_granted', 'Access not granted'),
  unsupported('unsupported', 'Observation unavailable'),
  error('error', 'Access status unavailable');

  const NotificationAccessStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static NotificationAccessStatus fromWireName(String value) {
    return switch (value) {
      'granted' => NotificationAccessStatus.granted,
      'not_granted' => NotificationAccessStatus.notGranted,
      'unsupported' => NotificationAccessStatus.unsupported,
      _ => NotificationAccessStatus.error,
    };
  }
}

enum NotificationConnectionStatus {
  connected('connected', 'Listener connected'),
  disconnected('disconnected', 'Listener disconnected'),
  unavailable('unavailable', 'Observation unavailable'),
  unknown('unknown', 'Connection status unavailable');

  const NotificationConnectionStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static NotificationConnectionStatus fromWireName(String value) {
    return switch (value) {
      'connected' => NotificationConnectionStatus.connected,
      'disconnected' => NotificationConnectionStatus.disconnected,
      'unavailable' => NotificationConnectionStatus.unavailable,
      _ => NotificationConnectionStatus.unknown,
    };
  }
}

class NotificationListenerStatus {
  const NotificationListenerStatus({
    required this.access,
    required this.connection,
  });

  const NotificationListenerStatus.unsupported()
    : access = NotificationAccessStatus.unsupported,
      connection = NotificationConnectionStatus.unavailable;

  const NotificationListenerStatus.error()
    : access = NotificationAccessStatus.error,
      connection = NotificationConnectionStatus.unavailable;

  final NotificationAccessStatus access;
  final NotificationConnectionStatus connection;

  bool get canObserve {
    return access == NotificationAccessStatus.granted &&
        connection == NotificationConnectionStatus.connected;
  }

  bool get isSupported => access != NotificationAccessStatus.unsupported;
}

enum NotificationEventType {
  posted('posted'),
  removed('removed');

  const NotificationEventType(this.wireName);

  final String wireName;

  static NotificationEventType? fromWireName(String value) {
    for (final type in NotificationEventType.values) {
      if (type.wireName == value) {
        return type;
      }
    }
    return null;
  }
}

/// Sanitized notification metadata. This model intentionally has no title,
/// body, text, sender, conversation, or raw notification-key fields.
class SanitizedNotificationEvent {
  const SanitizedNotificationEvent({
    required this.type,
    required this.packageName,
    required this.eventId,
    required this.category,
    required this.postedAt,
    required this.hasText,
    required this.isGroupSummary,
  });

  final NotificationEventType type;
  final String packageName;
  final String eventId;
  final String? category;
  final DateTime postedAt;
  final bool hasText;
  final bool isGroupSummary;
}

class NotificationEventStreamException implements Exception {
  const NotificationEventStreamException();

  @override
  String toString() => 'NotificationEventStreamException';
}
