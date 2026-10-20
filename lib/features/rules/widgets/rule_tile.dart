import 'package:flutter/material.dart';

import '../../../core/utilities/date_time_formatter.dart';
import '../../../domain/models/privacy_rule.dart';

class RuleTile extends StatelessWidget {
  const RuleTile({
    required this.rule,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final PrivacyRule rule;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = rule.actions.isEmpty
        ? 'No actions configured'
        : rule.actions.map((action) => action.kind.label).join(', ');
    final conditions = rule.conditions.isEmpty
        ? 'No conditions'
        : '${rule.conditions.length} condition'
              '${rule.conditions.length == 1 ? '' : 's'}';
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(rule.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rule.priority.label} priority · $conditions',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    actions,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${formatRuleTimestamp(rule.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Switch(value: rule.enabled, onChanged: onEnabledChanged),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onEdit, child: const Text('Edit')),
                TextButton(
                  onPressed: onDelete,
                  child: Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
