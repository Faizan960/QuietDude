import 'package:flutter/material.dart';

import '../../../domain/models/privacy_rule.dart';
import '../../../domain/models/rule_priority.dart';

class RuleDraft {
  const RuleDraft({
    required this.name,
    required this.enabled,
    required this.priority,
  });

  final String name;
  final bool enabled;
  final RulePriority priority;
}

class RuleEditorDialog extends StatefulWidget {
  const RuleEditorDialog({this.rule, super.key});

  final PrivacyRule? rule;

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _enabled;
  late RulePriority _priority;

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _enabled = widget.rule?.enabled ?? true;
    _priority = widget.rule?.priority ?? RulePriority.normal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      RuleDraft(
        name: _nameController.text.trim(),
        enabled: _enabled,
        priority: _priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEditing ? 'Edit rule' : 'New rule'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Rule name',
                  hintText: 'For example: Hide previews at work',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Enter a rule name.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RulePriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  for (final priority in RulePriority.values)
                    DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                Text(
                  'New rules start with an always-match condition and a '
                  'hide-previews action. Enforcement is not implemented yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
