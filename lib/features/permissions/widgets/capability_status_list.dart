import 'package:flutter/material.dart';

import '../../../domain/models/platform_capability.dart';

class CapabilityStatusList extends StatelessWidget {
  const CapabilityStatusList({
    required this.capabilities,
    this.maxItems,
    super.key,
  });

  final List<PlatformCapability> capabilities;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final visible = maxItems == null
        ? capabilities
        : capabilities.take(maxItems!).toList(growable: false);
    return Column(
      children: [
        for (final capability in visible)
          _CapabilityRow(capability: capability),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.capability});

  final PlatformCapability capability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconFor(capability.status),
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(capability.id.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    capability.detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CapabilityStatusChip(status: capability.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(CapabilityStatus status) {
    return switch (status) {
      CapabilityStatus.implemented => Icons.check_circle_outline,
      CapabilityStatus.partiallySupported => Icons.contrast,
      CapabilityStatus.requiresPermission => Icons.lock_outline,
      CapabilityStatus.scaffolded => Icons.construction_outlined,
      CapabilityStatus.unavailable => Icons.link_off,
      CapabilityStatus.planned => Icons.schedule_outlined,
      CapabilityStatus.unsupported => Icons.block_outlined,
    };
  }
}

class CapabilityStatusChip extends StatelessWidget {
  const CapabilityStatusChip({required this.status, super.key});

  final CapabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      CapabilityStatus.implemented => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      CapabilityStatus.partiallySupported => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      CapabilityStatus.requiresPermission => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      CapabilityStatus.scaffolded => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      CapabilityStatus.unavailable => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      CapabilityStatus.planned => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      CapabilityStatus.unsupported => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
