import 'dart:developer' as developer;

/// Structured diagnostics that never accept notification bodies, contact
/// details, message text, or other private content.
class DiagnosticLogger {
  const DiagnosticLogger(this.scope);

  final String scope;

  void debug(String event, [Map<String, Object?> fields = const {}]) {
    _log(event, fields, level: 500);
  }

  void warning(String event, [Map<String, Object?> fields = const {}]) {
    _log(event, fields, level: 900);
  }

  void _log(String event, Map<String, Object?> fields, {required int level}) {
    final suffix = fields.isEmpty
        ? ''
        : ' ${fields.entries.map((entry) => '${entry.key}=${entry.value}').join(' ')}';
    developer.log('$event$suffix', name: 'quietdude.$scope', level: level);
  }
}
