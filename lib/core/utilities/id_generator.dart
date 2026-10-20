import 'dart:math';

String generateRuleId({DateTime? now}) {
  final timestamp = (now ?? DateTime.now()).toUtc().microsecondsSinceEpoch;
  final random = Random.secure().nextInt(0xFFFFFFFF);
  final suffix = random.toRadixString(16).padLeft(8, '0');
  return 'rule_${timestamp}_$suffix';
}
