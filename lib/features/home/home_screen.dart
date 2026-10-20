import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utilities/date_time_formatter.dart';
import '../../domain/models/notification_listener.dart';
import '../../domain/models/notification_observation.dart';
import '../../domain/models/privacy_rule.dart';
import '../permissions/widgets/capability_status_list.dart';
import '../permissions/widgets/notification_access_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rules = ref.watch(rulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quietdude'),
        actions: [
          IconButton(
            tooltip: 'Open settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Your notifications. Your rules.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create independent privacy rules and see exactly what this '
            'device can support.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const _EnforcementNotice(),
          const SizedBox(height: 16),
          const NotificationAccessCard(),
          const SizedBox(height: 16),
          const _LastObservationCard(),
          const SizedBox(height: 16),
          _RulesOverview(rules: rules),
          const SizedBox(height: 16),
          _CapabilitiesOverview(theme: theme),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/rules'),
            icon: const Icon(Icons.rule_outlined),
            label: const Text('Manage rules'),
          ),
        ],
      ),
    );
  }
}

class _EnforcementNotice extends StatelessWidget {
  const _EnforcementNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enforcement is not implemented yet',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quietdude can observe sanitized notification metadata and '
                    'evaluate rules against it. It does not hide, silence, '
                    'dismiss, or rewrite notifications on this device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastObservationCard extends ConsumerWidget {
  const _LastObservationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final observation = ref.watch(lastNotificationObservationProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last observed event', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            observation.when(
              loading: () => Text(
                'Waiting for a notification event. No title or body is read.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              error: (error, stackTrace) => Text(
                'Notification event stream is unavailable.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (latest) => _ObservationDetails(observation: latest),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationDetails extends StatelessWidget {
  const _ObservationDetails({required this.observation});

  final NotificationObservation observation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = observation.event;
    final eventLabel = event.type == NotificationEventType.posted
        ? 'Posted'
        : 'Removed';
    final plan = observation.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$eventLabel by ${event.packageName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          formatRuleTimestamp(event.postedAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (event.hasText) ...[
          const SizedBox(height: 4),
          Text(
            'Notification text was present. Its content was not read or stored.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (observation.evaluated) ...[
          const SizedBox(height: 6),
          if (plan != null && !plan.isEmpty)
            Text(
              'Rule matched: ${plan.rule!.name}. Enforcement is not implemented.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              'No enabled rule matched this event.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class _RulesOverview extends StatelessWidget {
  const _RulesOverview({required this.rules});

  final AsyncValue<List<PrivacyRule>> rules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rule overview',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => GoRouter.of(context).push('/rules'),
                  child: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            rules.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(
                'Rules could not be loaded.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (items) {
                final enabled = items.where((rule) => rule.enabled).length;
                if (items.isEmpty) {
                  return Text(
                    'No rules yet. Create your first rule to get started.',
                    style: theme.textTheme.bodyMedium,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items.length} rule${items.length == 1 ? '' : 's'} · '
                      '$enabled enabled',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final rule in items.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              rule.enabled
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rule.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilitiesOverview extends ConsumerWidget {
  const _CapabilitiesOverview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(platformCapabilitiesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Device capabilities',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => GoRouter.of(context).push('/settings'),
                  child: const Text('Details'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            capabilities.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(
                'Capability status is unavailable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (items) =>
                  CapabilityStatusList(capabilities: items, maxItems: 3),
            ),
          ],
        ),
      ),
    );
  }
}
