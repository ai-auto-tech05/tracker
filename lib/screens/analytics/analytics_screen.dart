import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/habit_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/analytics/weekly_bar_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(analyticsProvider);
    final habits = ref.watch(habitProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Analytics'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                // ── Top KPI row ────────────────────────────────────────────
                _buildKpiRow(context, data),
                const SizedBox(height: 24),
                // ── Weekly Focus Chart ─────────────────────────────────────
                _buildChartCard(
                  context,
                  title: 'Focus Time (min)',
                  subtitle: 'Last 7 days',
                  child: WeeklyFocusChart(days: data.thisWeek.days),
                ),
                const SizedBox(height: 16),
                // ── Weekly Habit Completion ────────────────────────────────
                _buildChartCard(
                  context,
                  title: 'Habit Completion Rate',
                  subtitle: 'Last 7 days',
                  child: WeeklyHabitChart(days: data.thisWeek.days),
                ),
                const SizedBox(height: 24),
                // ── Weekly summary ─────────────────────────────────────────
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildWeeklySummary(context, data),
                const SizedBox(height: 24),
                // ── Habit streaks ──────────────────────────────────────────
                if (habits.isNotEmpty) ...[
                  Text(
                    'Habit Streaks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...habits.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HabitStreakRow(
                        habit: h,
                        rate: data.habitCompletionRates[h.id] ?? 0,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, AnalyticsData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _KpiCard(
          label: 'All-Time Focus',
          value: DateHelper.formatDuration(
              data.allTimeFocusMinutes),
          icon: Icons.timer_rounded,
          color: AppColors.primary,
        ),
        _KpiCard(
          label: 'Tasks Done',
          value: '${data.allTimeTasksCompleted}',
          icon: Icons.task_alt_rounded,
          color: AppColors.success,
        ),
        _KpiCard(
          label: 'App Streak',
          value: '${data.currentAppStreak}d',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.accent,
        ),
        _KpiCard(
          label: 'Best Streak',
          value: '${data.longestHabitStreak}d',
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(BuildContext context, AnalyticsData data) {
    final w = data.thisWeek;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Focus',
            value: DateHelper.formatDuration(w.totalFocusMinutes),
            icon: Icons.timer_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Tasks',
            value: '${w.totalTasksCompleted}',
            icon: Icons.check_box_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Habits',
            value: '${w.totalHabitsCompleted}',
            icon: Icons.loop_rounded,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Rate',
            value:
                '${(w.averageHabitRate * 100).toInt()}%',
            icon: Icons.bar_chart_rounded,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
              ),
              Text(
                label,
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _HabitStreakRow extends StatelessWidget {
  final HabitModel habit;
  final double rate;

  const _HabitStreakRow({required this.habit, required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(Icons.loop_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(rate * 100).toInt()}%',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor:
                        color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 11,
                        color: habit.currentStreak > 0
                            ? AppColors.accent
                            : AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      '${habit.currentStreak} day streak · best: ${habit.longestStreak}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
