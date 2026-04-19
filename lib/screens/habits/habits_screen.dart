import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/habits/habit_tile.dart';
import 'add_habit_sheet.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    final notifier = ref.read(habitProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Habits'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: () => _showAddHabit(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: habits.isEmpty
                ? SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.loop_rounded,
                      message:
                          'No habits yet.\nStart building one today.',
                      actionLabel: 'Add Habit',
                      onAction: () => _showAddHabit(context),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: _buildSummaryRow(
                                context, habits, notifier),
                          );
                        }
                        final habit = habits[i - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HabitTile(
                            habit: habit,
                            isCompletedToday:
                                notifier.isCompletedToday(habit.id),
                            onToggle: () =>
                                notifier.toggleCompletion(habit.id),
                            onTap: () =>
                                _showHabitOptions(context, ref, habit),
                          ),
                        );
                      },
                      childCount: habits.length + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, List<HabitModel> habits, HabitNotifier notifier) {
    final total = habits.length;
    final done = notifier.completedTodayCount;
    return Row(
      children: [
        _SummaryChip(
          label: 'Today',
          value: '$done / $total',
          icon: Icons.today_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        _SummaryChip(
          label: 'Best streak',
          value: habits.isEmpty
              ? '0'
              : '${habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b)}d',
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 10),
        _SummaryChip(
          label: 'Active',
          value: '$total',
          icon: Icons.loop_rounded,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }

  void _showAddHabit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddHabitSheet(),
    );
  }

  void _showHabitOptions(
      BuildContext context, WidgetRef ref, HabitModel habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitOptionsSheet(habit: habit, ref: ref),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  Text(
                    label,
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitOptionsSheet extends StatelessWidget {
  final HabitModel habit;
  final WidgetRef ref;

  const _HabitOptionsSheet({required this.habit, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl)),
      ),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 16),
          Text(habit.title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Habit'),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddHabitSheet(editingHabit: habit),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive Habit'),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              ref.read(habitProvider.notifier).archiveHabit(habit.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: Color(0xFFEF4444)),
            title: const Text('Delete Habit',
                style: TextStyle(color: Color(0xFFEF4444))),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              ref.read(habitProvider.notifier).deleteHabit(habit.id);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
