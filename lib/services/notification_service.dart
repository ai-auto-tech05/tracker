import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'tracker_reminders';
  static const _channelName = 'Tracker Reminders';
  static const _channelDesc = 'Habit reminders and daily check-ins';

  static const _focusId = 0;
  static const _checkInId = 1;
  static const _dailyScheduledId = 2;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));

    // HIGH importance channel → triggers heads-up (banner) overlay on Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'tracker',
        ),
      );

  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required String time, // 'HH:mm'
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'Habit Reminder',
      'Time for your habit: $habitName',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelHabitReminder(int id) => _plugin.cancel(id);

  Future<void> showFocusComplete(String message) => _plugin.show(
        _focusId,
        'Focus Session Complete',
        message,
        _details,
      );

  Future<void> showDailyCheckIn({
    required int pendingTasks,
    required int pendingHabits,
  }) {
    final String body;
    if (pendingTasks == 0 && pendingHabits == 0) {
      body = 'Amazing! All tasks and habits done for today.';
    } else if (pendingTasks == 0) {
      body =
          'Tasks all done! $pendingHabits habit${pendingHabits > 1 ? 's' : ''} still to go.';
    } else if (pendingHabits == 0) {
      body =
          'Habits done! $pendingTasks task${pendingTasks > 1 ? 's' : ''} remaining.';
    } else {
      body =
          '$pendingTasks task${pendingTasks > 1 ? 's' : ''} and $pendingHabits habit${pendingHabits > 1 ? 's' : ''} remaining today.';
    }

    return _plugin.show(
      _checkInId,
      "How's your day going?",
      body,
      _details,
    );
  }

  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyScheduledId,
      "How's your day going?",
      'Have you completed your tasks and habits today?',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
