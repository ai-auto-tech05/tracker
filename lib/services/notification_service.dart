/// Stub notification service. Wire up flutter_local_notifications
/// when you add the package to pubspec.yaml.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {
    // TODO: Initialize flutter_local_notifications
  }

  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required String time, // 'HH:mm'
  }) async {
    // TODO: Schedule daily notification at [time] for this habit
  }

  Future<void> cancelHabitReminder(int id) async {
    // TODO: Cancel notification with [id]
  }

  Future<void> showFocusComplete(String message) async {
    // TODO: Show immediate notification when focus session completes
  }

  Future<void> cancelAll() async {
    // TODO: Cancel all pending notifications
  }
}
