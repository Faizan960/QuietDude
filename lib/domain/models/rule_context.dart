class RuleContext {
  const RuleContext({
    required this.now,
    this.foregroundAppPackage,
    this.wearableNearby = false,
  });

  final DateTime now;
  final String? foregroundAppPackage;
  final bool wearableNearby;
}
