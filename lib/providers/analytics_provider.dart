import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_helper.dart';
import '../core/utils/streak_calculator.dart';
import '../models/focus_session_model.dart';
import '../models/habit_model.dart';
import 'task_provider.dart';
import 'habit_provider.dart';
import 'focus_provider.dart';

class WeeklyStats {
  final List<DayStats> days; // 7 items, Mon–Sun
  final int totalFocusMinutes;
  final int totalTasksCompleted;
  final int totalHabitsCompleted;
  final double averageHabitRate;

  const WeeklyStats({
    required this.days,
    required this.totalFocusMinutes,
    required this.totalTasksCompleted,
    required this.totalHabitsCompleted,
    required this.averageHabitRate,
  });
}

class DayStats {
  final DateTime date;
  final int focusMinutes;
  final int tasksCompleted;
  final int habitsCompleted;
  final int habitsTotal;

  const DayStats({
    required this.date,
    required this.focusMinutes,
    required this.tasksCompleted,
    required this.habitsCompleted,
    required this.habitsTotal,
  });

  double get habitRate =>
      habitsTotal == 0 ? 0.0 : habitsCompleted / habitsTotal;
}

class AnalyticsData {
  final WeeklyStats thisWeek;
  final int longestHabitStreak;
  final int currentAppStreak;
  final int allTimeFocusMinutes;
  final int allTimeTasksCompleted;
  final double overallHabitRate; // last 30 days
  final Map<String, double> habitCompletionRates; // habitId → rate

  const AnalyticsData({
    required this.thisWeek,
    required this.longestHabitStreak,
    required this.currentAppStreak,
    required this.allTimeFocusMinutes,
    required this.allTimeTasksCompleted,
    required this.overallHabitRate,
    required this.habitCompletionRates,
  });
}

final analyticsProvider = Provider<AnalyticsData>((ref) {
  final tasks = ref.watch(taskProvider);
  final habits = ref.watch(habitProvider);
  final focusState = ref.watch(focusProvider);

  // ── This week's days (Mon through today) ──────────────────────────────
  final today = DateHelper.today;
  final last7 = DateHelper.lastNDays(7);

  final dayStats = last7.map((day) {
    final dayKey = DateHelper.toStorageKey(day);

    final focusMins = focusState.sessions
        .where((s) =>
            s.isCompleted &&
            s.sessionType == SessionType.focus &&
            DateHelper.toStorageKey(s.startTime) == dayKey)
        .fold(0, (sum, s) => sum + s.actualDurationMinutes);

    final tasksComplete = tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return DateHelper.isSameDay(t.completedAt!, day);
    }).length;

    final dailyHabits =
        habits.where((h) => h.frequency == HabitFrequency.daily).toList();
    final habitsComplete =
        dailyHabits.where((h) => h.completionHistory[dayKey] == true).length;

    return DayStats(
      date: day,
      focusMinutes: focusMins,
      tasksCompleted: tasksComplete,
      habitsCompleted: habitsComplete,
      habitsTotal: dailyHabits.length,
    );
  }).toList();

  final weeklyStats = WeeklyStats(
    days: dayStats,
    totalFocusMinutes:
        dayStats.fold(0, (s, d) => s + d.focusMinutes),
    totalTasksCompleted:
        dayStats.fold(0, (s, d) => s + d.tasksCompleted),
    totalHabitsCompleted:
        dayStats.fold(0, (s, d) => s + d.habitsCompleted),
    averageHabitRate: dayStats.isEmpty
        ? 0
        : dayStats.map((d) => d.habitRate).reduce((a, b) => a + b) /
            dayStats.length,
  );

  // ── All-time stats ─────────────────────────────────────────────────────
  final allTimeFocus = focusState.sessions
      .where((s) => s.isCompleted && s.sessionType == SessionType.focus)
      .fold(0, (sum, s) => sum + s.actualDurationMinutes);

  final allTimeTasksDone = tasks.where((t) => t.isCompleted).length;

  final longestHabitStreak = habits.isEmpty
      ? 0
      : habits
          .map((h) => h.longestStreak)
          .reduce((a, b) => a > b ? a : b);

  // ── Per-habit completion rates (last 30 days) ─────────────────────────
  final habitRates = <String, double>{};
  for (final h in habits) {
    habitRates[h.id] =
        StreakCalculator.completionRate(h.completionHistory, days: 30);
  }

  final overallRate = habitRates.isEmpty
      ? 0.0
      : habitRates.values.reduce((a, b) => a + b) / habitRates.length;

  // ── App streak ────────────────────────────────────────────────────────
  final appStreak = habits.isEmpty
      ? 0
      : ref.read(habitProvider.notifier).appStreakDays;

  return AnalyticsData(
    thisWeek: weeklyStats,
    longestHabitStreak: longestHabitStreak,
    currentAppStreak: appStreak,
    allTimeFocusMinutes: allTimeFocus,
    allTimeTasksCompleted: allTimeTasksDone,
    overallHabitRate: overallRate,
    habitCompletionRates: habitRates,
  );
});
