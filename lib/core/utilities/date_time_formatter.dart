import 'package:intl/intl.dart';

String formatRuleTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  return DateFormat.yMMMd().add_jm().format(local);
}
