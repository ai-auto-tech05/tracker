import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../core/utils/date_helper.dart';

/// Pushes task + habit data into the shared native storage so both the
/// Android AppWidget and the iOS WidgetKit extension can read it.
class WidgetUpdateService {
  static const String _androidWidgetName = 'TrackerWidgetReceiver';
  static const String _iosWidgetName = 'TrackerWidget';
  static const String _appGroupId = 'group.com.example.tracker';

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    // Required for iOS so HomeWidget uses the shared App Group container.
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  // ── Public update entry-point ─────────────────────────────────────────────

  static Future<void> update({
    required List<TaskModel> tasks,
    required List<HabitModel> habits,
  }) async {
    try {
      await Future.wait([
        _writeTasks(tasks),
        _writeHabits(habits),
        HomeWidget.saveWidgetData<String>(
          'last_updated',
          DateFormat('h:mm a').format(DateTime.now()),
        ),
      ]);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
        qualifiedAndroidName:
            'com.example.tracker.$_androidWidgetName',
      );
    } catch (_) {
      // Silently ignore — widget update is best-effort.
    }
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  static Future<void> _writeTasks(List<TaskModel> tasks) async {
    final sorted = _sortedActiveTasks(tasks);
    final top = sorted.take(4).toList();

    await HomeWidget.saveWidgetData<int>('task_count', top.length);

    for (int i = 0; i < 4; i++) {
      final key = 'task_${i + 1}';
      if (i < top.length) {
        final t = top[i];
        await Future.wait([
          HomeWidget.saveWidgetData<bool>('${key}_visible', true),
          HomeWidget.saveWidgetData<String>('${key}_title', t.title),
          HomeWidget.saveWidgetData<String>(
              '${key}_due', _formatDue(t.dueDate)),
          HomeWidget.saveWidgetData<bool>('${key}_overdue', t.isOverdue),
        ]);
      } else {
        await HomeWidget.saveWidgetData<bool>('${key}_visible', false);
      }
    }
  }

  /// Tasks with due dates first (ascending), then undated tasks, all active.
  static List<TaskModel> _sortedActiveTasks(List<TaskModel> all) {
    final active =
        all.where((t) => !t.isCompleted && !t.isBuried).toList();

    // Overdue + today first, then by date, then undated
    final withDue = active.where((t) => t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final withoutDue = active.where((t) => t.dueDate == null).toList();

    return [...withDue, ...withoutDue];
  }

  static String _formatDue(DateTime? due) {
    if (due == null) return 'No date';
    final today = DateHelper.today;
    final tomorrow = today.add(const Duration(days: 1));
    if (due.isBefore(today) &&
        !DateHelper.isSameDay(due, today)) return 'Overdue';
    if (DateHelper.isSameDay(due, today)) return 'Today';
    if (DateHelper.isSameDay(due, tomorrow)) return 'Tomorrow';
    return DateFormat('MMM d').format(due);
  }

  // ── Habits ────────────────────────────────────────────────────────────────

  static Future<void> _writeHabits(List<HabitModel> habits) async {
    // Sort by streak desc, then show top 3
    final sorted = [...habits]
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    final top = sorted.take(3).toList();
    final today = DateHelper.toStorageKey(DateTime.now());

    await HomeWidget.saveWidgetData<int>('habit_count', top.length);

    for (int i = 0; i < 3; i++) {
      final key = 'habit_${i + 1}';
      if (i < top.length) {
        final h = top[i];
        final doneToday = h.completionHistory[today] == true;
        await Future.wait([
          HomeWidget.saveWidgetData<bool>('${key}_visible', true),
          HomeWidget.saveWidgetData<String>('${key}_name', h.title),
          HomeWidget.saveWidgetData<int>('${key}_streak', h.currentStreak),
          HomeWidget.saveWidgetData<bool>('${key}_done', doneToday),
        ]);
      } else {
        await HomeWidget.saveWidgetData<bool>('${key}_visible', false);
      }
    }
  }
}
