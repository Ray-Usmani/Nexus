import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  Future<void> applyPreferences({
    required bool dailyEnabled,
    required bool weeklyEnabled,
  }) async {
    if (!_initialized) await init();

    if (dailyEnabled) {
      try {
        await scheduleDailyReminder(hour: 20, minute: 0);
      } catch (e, stack) {
        debugPrint('Daily reminder scheduling failed: $e');
        debugPrint('$stack');
      }
    } else {
      await cancelDailyReminder();
    }

    if (weeklyEnabled) {
      try {
        await scheduleWeeklySummary();
      } catch (e, stack) {
        debugPrint('Weekly summary scheduling failed: $e');
        debugPrint('$stack');
      }
    } else {
      await cancelWeeklySummary();
    }
  }

  Future<void> cancelDailyReminder() => _plugin.cancel(1);

  Future<void> cancelWeeklySummary() => _plugin.cancel(2);

  static const _fallbackTimeZone = 'Asia/Karachi';

  Future<void> _configureLocalTimezone() async {
    String timeZoneName = _fallbackTimeZone;

    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('Timezone: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      return;
    } catch (e, stack) {
      debugPrint('Timezone setup failed for $timeZoneName: $e');
      debugPrint('$stack');
    }

    for (final fallback in [_fallbackTimeZone, 'UTC']) {
      try {
        debugPrint('Timezone fallback: $fallback');
        tz.setLocalLocation(
          fallback == 'UTC' ? tz.UTC : tz.getLocation(fallback),
        );
        return;
      } catch (e, stack) {
        debugPrint('Timezone fallback failed for $fallback: $e');
        debugPrint('$stack');
      }
    }
  }

  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _plugin.zonedSchedule(
      1,
      'Log today\'s expenses',
      'Take 5 seconds to record what you spent today.',
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily reminders', importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWeeklySummary() async {
    var scheduled = _nextInstance(9, 0);
    while (scheduled.weekday != DateTime.monday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      2,
      'Weekly budget review',
      'Check your spending trends and budget health.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('weekly', 'Weekly summary', importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> showOverspendAlert(String category) async {
    await _plugin.show(
      3,
      'Over budget: $category',
      'You have exceeded the planned amount for this envelope.',
      const NotificationDetails(
        android: AndroidNotificationDetails('alerts', 'Budget alerts', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
}
