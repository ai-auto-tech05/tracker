import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../core/utils/date_helper.dart';

/// Pushes task + habit data to the native shared storage so both the
/// Android AppWidgets and the iOS WidgetKit extensions can read it.
///
/// Two separate widget names are registered:
///  - [_taskWidgetAndroid]  / [_taskWidgetIOS]
///  - [_habitWidgetAndroid] / [_habitWidgetIOS]
class WidgetUpdateService {
  // ── Widget names ──────────────────────────────────────────────────────────

  static const _taskWidgetAndroid  = 'TrackerTaskWidgetReceiver';
  static const _habitWidgetAndroid = 'TrackerHabitWidgetReceiver';
  static const _taskWidgetIOS      = 'TrackerTaskWidget';
  static const _habitWidgetIOS     = 'TrackerHabitWidget';

  /// App group ID used by both the main app and the iOS widget extension.
  static const _appGroupId = 'group.com.example.tracker';

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  // ── Public entry-point ────────────────────────────────────────────────────

  static Future<void> update({
    required List<TaskModel> tasks,
    required List<HabitModel> habits,
  }) async {
    try {
      // Write all data first, then trigger both widgets.
      await Future.wait([
        _writeTasks(tasks),
        _writeHabits(habits),
        HomeWidget.saveWidgetData<String>(
          'last_updated',
          DateFormat('h:mm a').format(DateTime.now()),
        ),
      ]);

      // Update both widgets independently — ignore individual failures.
      await Future.wait([
        HomeWidget.updateWidget(
          androidName: _taskWidgetAndroid,
          iOSName: _taskWidgetIOS,
          qualifiedAndroidName: 'com.example.tracker.$_taskWidgetAndroid',
        ).catchError((_) {}),
        HomeWidget.updateWidget(
          androidName: _habitWidgetAndroid,
          iOSName: _habitWidgetIOS,
          qualifiedAndroidName: 'com.example.tracker.$_habitWidgetAndroid',
        ).catchError((_) {}),
      ]);
    } catch (_) {
      // Widget updates are best-effort — never crash the app.
    }
  }

  // ── Tasks (top 4 by due date) ─────────────────────────────────────────────

  static Future<void> _writeTasks(List<TaskModel> tasks) async {
    final sorted = _sortedActiveTasks(tasks);
    final top    = sorted.take(4).toList();

    await HomeWidget.saveWidgetData<int>('task_count', top.length);

    for (int i = 0; i < 4; i++) {
      final key = 'task_${i + 1}';
      if (i < top.length) {
        final t = top[i];
        await Future.wait([
          HomeWidget.saveWidgetData<bool>('${key}_visible', true),
          HomeWidget.saveWidgetData<String>('${key}_title',   t.title),
          HomeWidget.saveWidgetData<String>('${key}_due',     _formatDue(t.dueDate)),
          HomeWidget.saveWidgetData<bool>('${key}_overdue', t.isOverdue),
        ]);
      } else {
        await HomeWidget.saveWidgetData<bool>('${key}_visible', false);
      }
    }
  }

  /// Overdue/today first (ascending date), then future, then undated.
  static List<TaskModel> _sortedActiveTasks(List<TaskModel> all) {
    final active = all.where((t) => !t.isCompleted && !t.isBuried).toList();
    final withDue = active.where((t) => t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final noDue = active.where((t) => t.dueDate == null).toList();
    return [...withDue, ...noDue];
  }

  static String _formatDue(DateTime? due) {
    if (due == null) return 'No date';
    final today    = DateHelper.today;
    final tomorrow = today.add(const Duration(days: 1));
    if (due.isBefore(today) && !DateHelper.isSameDay(due, today)) return 'Overdue';
    if (DateHelper.isSameDay(due, today))    return 'Today';
    if (DateHelper.isSameDay(due, tomorrow)) return 'Tomorrow';
    return DateFormat('MMM d').format(due);
  }

  // ── Habits (top 5, sorted by streak desc) ────────────────────────────────

  static Future<void> _writeHabits(List<HabitModel> habits) async {
    final sorted = [...habits]
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    final top   = sorted.take(5).toList();
    final today = DateHelper.toStorageKey(DateTime.now());

    await HomeWidget.saveWidgetData<int>('habit_count', top.length);

    for (int i = 0; i < 5; i++) {
      final key = 'habit_${i + 1}';
      if (i < top.length) {
        final h         = top[i];
        final doneToday = h.completionHistory[today] == true;
        await Future.wait([
          HomeWidget.saveWidgetData<bool>('${key}_visible', true),
          HomeWidget.saveWidgetData<String>('${key}_name',   h.title),
          HomeWidget.saveWidgetData<int>('${key}_streak', h.currentStreak),
          HomeWidget.saveWidgetData<bool>('${key}_done',  doneToday),
        ]);
      } else {
        await HomeWidget.saveWidgetData<bool>('${key}_visible', false);
      }
    }
  }
}
