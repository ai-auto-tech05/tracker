import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_helper.dart';
import 'task_provider.dart';
import 'habit_provider.dart';

// ─── Shame Meter (0–100) ──────────────────────────────────────────────────────
// 100 = everything incomplete; 0 = everything done

final shameMeterProvider = Provider<int>((ref) {
  final today = DateHelper.toStorageKey(DateHelper.today);
  final tasks = ref.watch(todayTasksProvider);
  final habits = ref.watch(todayHabitsProvider);

  final totalItems = tasks.length + habits.length;
  if (totalItems == 0) return 0;

  final incompleteTasks = tasks.where((t) => !t.isCompleted).length;
  final incompleteHabits =
      habits.where((h) => h.completionHistory[today] != true).length;

  return ((incompleteTasks + incompleteHabits) / totalItems * 100)
      .round()
      .clamp(0, 100);
});

// ─── Alex — Ghost Competitor ──────────────────────────────────────────────────
// Seeded by date so Alex's stats are stable within a day.

class AlexStats {
  final int tasksCompleted;
  final int habitsCompleted;
  final int focusMinutes;

  const AlexStats({
    required this.tasksCompleted,
    required this.habitsCompleted,
    required this.focusMinutes,
  });
}

final alexStatsProvider = Provider<AlexStats>((ref) {
  final now = DateTime.now();
  // Stable seed per calendar day
  final seed = now.year * 10000 + now.month * 100 + now.day;
  final rng = Random(seed);
  return AlexStats(
    tasksCompleted: 2 + rng.nextInt(4),   // 2–5
    habitsCompleted: 3 + rng.nextInt(4),   // 3–6
    focusMinutes: 20 + rng.nextInt(70),    // 20–90
  );
});

// ─── Sarcastic copy bank ──────────────────────────────────────────────────────

const sarcasticHeadsUpMessages = [
  ('Friendly reminder', "Alex finished 3 tasks already. You've opened the app 4 times."),
  ('Productivity check', "Your task list is looking... ambitious. How's that working out?"),
  ('Just checking in', "You set a focus goal. Bold choice for someone who hasn't started."),
  ('Cool story bro', "Another day, another 47 things on the list, zero done."),
  ('Update', "Alex completed his habits. You completed a scroll session."),
  ('Heads up', "That overdue task from Tuesday says hi."),
  ('No pressure', "But your streak dies in a few hours. Sleep well!"),
  ('Fun fact', "The average person spends 2.5 hours deciding what to do first."),
  ('News flash', "Your 'I'll do it later' is now 'I'll do it next week'."),
  ('Gentle nudge', "You have 0 completed tasks today. Alex has 4. Just vibes."),
];

const gentleHeadsUpMessages = [
  ('Hey there', "Just a small reminder — one task at a time is totally fine."),
  ('You got this', "Even five minutes of focus adds up. Start small."),
  ('Check in', "How are the habits going today? No pressure, just wondering."),
  ('Reminder', "Progress > perfection. Even partial counts."),
  ('A thought', "Resting is part of the process too. But maybe after one task?"),
];

const brutalHeadsUpMessages = [
  ('Unacceptable', "Zero tasks completed. Fix that. Now."),
  ('Wake up', "Alex is lapping you. This is embarrassing."),
  ('Reality', "You've been 'about to start' for 3 hours."),
  ('No more excuses', "The task won't do itself. Go."),
  ('Fact', "At this rate, you'll finish in approximately never."),
];

List<(String, String)> messagesForStyle(String style) {
  return switch (style) {
    'gentle' => gentleHeadsUpMessages,
    'brutal' => brutalHeadsUpMessages,
    _ => sarcasticHeadsUpMessages,
  };
}
