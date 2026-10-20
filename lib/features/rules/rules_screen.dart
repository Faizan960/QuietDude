import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/rule_storage_exception.dart';
import '../../core/utilities/id_generator.dart';
import '../../domain/actions/rule_action.dart';
import '../../domain/conditions/rule_condition.dart';
import '../../domain/models/privacy_rule.dart';
import 'rule_editor_dialog.dart';
import 'widgets/rule_tile.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add rule'),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Rules could not be loaded.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyRules(onCreate: () => _openEditor(context, ref));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rule = items[index];
              return RuleTile(
                rule: rule,
                onEnabledChanged: (enabled) =>
                    _setEnabled(context, ref, rule, enabled),
                onEdit: () => _openEditor(context, ref, rule: rule),
                onDelete: () => _confirmDelete(context, ref, rule),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    PrivacyRule? rule,
  }) async {
    final draft = await showDialog<RuleDraft>(
      context: context,
      builder: (context) => RuleEditorDialog(rule: rule),
    );
    if (draft == null || !context.mounted) {
      return;
    }

    final now = DateTime.now().toUtc();
    final updated = rule == null
        ? PrivacyRule(
            id: generateRuleId(now: now),
            name: draft.name,
            enabled: draft.enabled,
            priority: draft.priority,
            conditions: const <RuleCondition>[AlwaysCondition()],
            actions: const <RuleAction>[HidePreviewsAction()],
            createdAt: now,
            updatedAt: now,
          )
        : rule.copyWith(
            name: draft.name,
            enabled: draft.enabled,
            priority: draft.priority,
            updatedAt: now,
          );

    await _persist(context, ref, updated);
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    PrivacyRule rule,
    bool enabled,
  ) async {
    await _persist(
      context,
      ref,
      rule.copyWith(enabled: enabled, updatedAt: DateTime.now().toUtc()),
    );
  }

  Future<void> _persist(
    BuildContext context,
    WidgetRef ref,
    PrivacyRule rule,
  ) async {
    try {
      await ref.read(ruleRepositoryProvider).upsert(rule);
    } on RuleStorageException {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The rule could not be saved.')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PrivacyRule rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete rule?'),
        content: Text('“${rule.name}” will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(ruleRepositoryProvider).delete(rule.id);
    } on RuleStorageException {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The rule could not be deleted.')),
      );
    }
  }
}

class _EmptyRules extends StatelessWidget {
  const _EmptyRules({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rule_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No rules yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Rules are stored locally on this device. Create one to define '
              'how Quietdude should behave once enforcement is available.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create a rule'),
            ),
          ],
        ),
      ),
    );
  }
}
