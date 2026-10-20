class RuleContext {
  const RuleContext({
    required this.now,
    this.foregroundAppPackage,
    this.notificationSourcePackage,
    this.wearableNearby = false,
  });

  final DateTime now;
  final String? foregroundAppPackage;

  /// The app that posted the notification being observed. When present it takes
  /// precedence over [foregroundAppPackage] for app-scoped rule conditions.
  final String? notificationSourcePackage;
  final bool wearableNearby;
}
