import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/notification_listener.dart';

class NotificationAccessCard extends ConsumerWidget {
  const NotificationAccessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(notificationListenerStatusProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification access', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Notification access lets Quietdude observe sanitized metadata '
              'from notifications. It does not let Quietdude hide, silence, '
              'dismiss, or rewrite notifications yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            status.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => _StatusMessage(
                icon: Icons.error_outline,
                message: 'Access status is unavailable.',
              ),
              data: (listenerStatus) => _AccessDetails(
                status: listenerStatus,
                onOpenSettings: () => _openSettings(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(platformAdapterProvider)
        .openNotificationListenerSettings();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Android notification access settings could not be opened.',
          ),
        ),
      );
    }
  }
}

class _AccessDetails extends StatelessWidget {
  const _AccessDetails({required this.status, required this.onOpenSettings});

  final NotificationListenerStatus status;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusMessage(
          icon: _accessIcon(status.access),
          message: status.access.label,
        ),
        const SizedBox(height: 6),
        _StatusMessage(
          icon: _connectionIcon(status.connection),
          message: status.connection.label,
        ),
        if (status.access == NotificationAccessStatus.notGranted) ...[
          const SizedBox(height: 8),
          Text(
            'Android grants notification access as special access in system '
            'settings. Opening settings does not grant it automatically, and '
            'you can revoke it at any time.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (status.access == NotificationAccessStatus.granted &&
            status.connection != NotificationConnectionStatus.connected) ...[
          const SizedBox(height: 8),
          Text(
            'Access is granted, but the listener is not connected. Android '
            'normally reconnects it; if it stays disconnected, reopen the '
            'system settings and toggle access.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (status.access == NotificationAccessStatus.unsupported) ...[
          const SizedBox(height: 8),
          Text(
            'This platform does not expose other apps\' notifications to '
            'third-party applications.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (status.access == NotificationAccessStatus.error) ...[
          const SizedBox(height: 8),
          Text(
            'Quietdude could not read notification access status. Try again.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (status.isSupported) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open notification access settings'),
          ),
        ],
      ],
    );
  }

  IconData _accessIcon(NotificationAccessStatus status) {
    return switch (status) {
      NotificationAccessStatus.granted => Icons.check_circle_outline,
      NotificationAccessStatus.notGranted => Icons.lock_outline,
      NotificationAccessStatus.unsupported => Icons.block_outlined,
      NotificationAccessStatus.error => Icons.error_outline,
    };
  }

  IconData _connectionIcon(NotificationConnectionStatus status) {
    return switch (status) {
      NotificationConnectionStatus.connected => Icons.sensors,
      NotificationConnectionStatus.disconnected => Icons.sensors_off,
      NotificationConnectionStatus.unavailable => Icons.link_off,
      NotificationConnectionStatus.unknown => Icons.help_outline,
    };
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(message, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
