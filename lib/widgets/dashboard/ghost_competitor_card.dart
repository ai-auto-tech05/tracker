import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/chaos_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/task_provider.dart';

class GhostCompetitorCard extends ConsumerWidget {
  const GhostCompetitorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alex = ref.watch(alexStatsProvider);
    final today = DateHelper.toStorageKey(DateHelper.today);

    // User stats for today
    final userTasksDone = ref.watch(taskProvider).where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return DateHelper.isSameDay(t.completedAt!, DateHelper.today);
    }).length;

    final userHabitsDone = ref.watch(habitProvider)
        .where((h) => h.completionHistory[today] == true)
        .length;

    final userFocusMin = ref.watch(focusProvider).sessions.where((s) {
      return s.isCompleted &&
          DateHelper.toStorageKey(s.startTime) == today;
    }).fold(0, (sum, s) => sum + s.actualDurationMinutes);

    final userWins = [
      userTasksDone > alex.tasksCompleted,
      userHabitsDone > alex.habitsCompleted,
      userFocusMin > alex.focusMinutes,
    ].where((w) => w).length;

    final taunt = _taunt(userWins, alex);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B),
            const Color(0xFF2D1B69),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  color: Colors.white60, size: 16),
              const SizedBox(width: 6),
              Text(
                'vs Alex',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  userWins >= 2 ? '🏆 You win' : '😬 Alex wins',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats rows
          _StatRow(
            label: 'Tasks',
            you: userTasksDone,
            alex: alex.tasksCompleted,
            icon: Icons.check_box_rounded,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Habits',
            you: userHabitsDone,
            alex: alex.habitsCompleted,
            icon: Icons.loop_rounded,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Focus',
            you: userFocusMin,
            alex: alex.focusMinutes,
            icon: Icons.timer_rounded,
            suffix: 'min',
          ),
          const SizedBox(height: 14),
          // Taunt
          Text(
            taunt,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08, end: 0);
  }

  static String _taunt(int userWins, AlexStats alex) {
    if (userWins == 3) {
      return "Okay fine, you're better than Alex today. Don't make it weird.";
    }
    if (userWins == 2) {
      return "Leading in 2 out of 3. Alex is pretending not to care.";
    }
    if (userWins == 1) {
      return "You beat Alex in exactly one category. He's not worried.";
    }
    return "Alex has ${alex.tasksCompleted} tasks done. He also doesn't procrastinate.";
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int you;
  final int alex;
  final IconData icon;
  final String suffix;

  const _StatRow({
    required this.label,
    required this.you,
    required this.alex,
    required this.icon,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final total = (you + alex).clamp(1, double.infinity).toDouble();
    final youFrac = (you / total).clamp(0.0, 1.0);
    final alexFrac = (alex / total).clamp(0.0, 1.0);
    final youWins = you >= alex;

    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white60,
                ),
          ),
        ),
        // You bar
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$you${suffix.isNotEmpty ? ' $suffix' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: youWins
                          ? const Color(0xFF34D399)
                          : Colors.white60,
                      fontWeight: youWins
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 60,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(color: Colors.white12),
                      FractionallySizedBox(
                        widthFactor: youFrac,
                        child: Container(
                          color: youWins
                              ? const Color(0xFF34D399)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('vs',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white30,
                  )),
        ),
        // Alex bar
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(color: Colors.white12),
                      FractionallySizedBox(
                        widthFactor: alexFrac,
                        child: Container(
                          color: !youWins
                              ? const Color(0xFFF87171)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$alex${suffix.isNotEmpty ? ' $suffix' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: !youWins
                          ? const Color(0xFFF87171)
                          : Colors.white60,
                      fontWeight: !youWins
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
