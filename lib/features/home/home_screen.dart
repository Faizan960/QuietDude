import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models/privacy_rule.dart';
import '../permissions/widgets/capability_status_list.dart';

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
                    'Quietdude currently stores rules only. It does not read, '
                    'hide, silence, or dismiss notifications on this device.',
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
