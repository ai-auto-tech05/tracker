import 'date_helper.dart';

class StreakCalculator {
  StreakCalculator._();

  /// Computes current streak from a set of completion dates (stored as 'yyyy-MM-dd' keys).
  /// A streak breaks if any day (going backwards from today) is missing.
  static int computeCurrentStreak(Map<String, bool> completionHistory) {
    int streak = 0;
    DateTime cursor = DateHelper.today;

    while (true) {
      final key = DateHelper.toStorageKey(cursor);
      if (completionHistory[key] == true) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Computes longest ever streak from completion history.
  static int computeLongestStreak(Map<String, bool> completionHistory) {
    if (completionHistory.isEmpty) return 0;

    final dates = completionHistory.entries
        .where((e) => e.value)
        .map((e) => DateHelper.fromStorageKey(e.key))
        .whereType<DateTime>()
        .toList()
      ..sort();

    if (dates.isEmpty) return 0;

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }
    return maxStreak;
  }

  /// App-level daily streak: increments if the user completes at least
  /// [minHabits] habits and [minTasks] tasks today.
  static int computeAppStreak({
    required Map<String, bool> dailyCheckIns,
  }) {
    return computeCurrentStreak(dailyCheckIns);
  }

  /// Returns the last 7 days as booleans (was habit completed each day?).
  static List<bool> last7DaysCompletion(Map<String, bool> completionHistory) {
    return DateHelper.lastNDays(7)
        .map((d) => completionHistory[DateHelper.toStorageKey(d)] == true)
        .toList();
  }

  /// Completion rate over last [days] days (0.0 – 1.0).
  static double completionRate(Map<String, bool> history, {int days = 30}) {
    final range = DateHelper.lastNDays(days);
    if (range.isEmpty) return 0.0;
    final completed = range
        .where((d) => history[DateHelper.toStorageKey(d)] == true)
        .length;
    return completed / range.length;
  }
}
