import '../models/rule_context.dart';

class TimeWindow {
  TimeWindow({required this.startMinute, required this.endMinute}) {
    if (startMinute < 0 || startMinute > 1439) {
      throw ArgumentError.value(
        startMinute,
        'startMinute',
        'Must be between 0 and 1439.',
      );
    }
    if (endMinute < 0 || endMinute > 1439) {
      throw ArgumentError.value(
        endMinute,
        'endMinute',
        'Must be between 0 and 1439.',
      );
    }
  }

  final int startMinute;
  final int endMinute;

  bool get crossesMidnight => startMinute > endMinute;

  bool contains(DateTime time) {
    final minuteOfDay = time.hour * 60 + time.minute;
    if (startMinute == endMinute) {
      return true;
    }
    if (crossesMidnight) {
      return minuteOfDay >= startMinute || minuteOfDay < endMinute;
    }
    return minuteOfDay >= startMinute && minuteOfDay < endMinute;
  }
}

enum RuleConditionKind {
  always('always'),
  timeWindow('time_window'),
  app('app'),
  wearableNearby('wearable_nearby');

  const RuleConditionKind(this.wireName);

  final String wireName;

  static RuleConditionKind? fromWireName(String value) {
    for (final kind in RuleConditionKind.values) {
      if (kind.wireName == value) {
        return kind;
      }
    }
    return null;
  }
}

sealed class RuleCondition {
  const RuleCondition();

  RuleConditionKind get kind;

  bool matches(RuleContext context);
}

final class AlwaysCondition extends RuleCondition {
  const AlwaysCondition();

  @override
  RuleConditionKind get kind => RuleConditionKind.always;

  @override
  bool matches(RuleContext context) => true;
}

final class TimeWindowCondition extends RuleCondition {
  TimeWindowCondition({required this.window});

  final TimeWindow window;

  @override
  RuleConditionKind get kind => RuleConditionKind.timeWindow;

  @override
  bool matches(RuleContext context) => window.contains(context.now);
}

final class AppCondition extends RuleCondition {
  AppCondition({required this.packageName}) {
    if (packageName.trim().isEmpty) {
      throw ArgumentError.value(
        packageName,
        'packageName',
        'Must not be empty.',
      );
    }
  }

  final String packageName;

  @override
  RuleConditionKind get kind => RuleConditionKind.app;

  @override
  bool matches(RuleContext context) {
    final activePackage =
        context.notificationSourcePackage ?? context.foregroundAppPackage;
    return activePackage == packageName;
  }
}

final class WearableNearbyCondition extends RuleCondition {
  const WearableNearbyCondition();

  @override
  RuleConditionKind get kind => RuleConditionKind.wearableNearby;

  @override
  bool matches(RuleContext context) => context.wearableNearby;
}
