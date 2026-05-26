import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../navigation/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/app_notification_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/tasks/task_tile.dart';
import '../../widgets/habits/habit_tile.dart';
import '../../widgets/dashboard/shame_meter_card.dart';
import '../../widgets/dashboard/ghost_competitor_card.dart';
import '../tasks/edit_task_screen.dart';

// Tracks the last date the daily progress banner was shown (once per day)
final _bannerShownDateProvider = StateProvider<String?>((ref) => null);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowBanner());
  }

  void _maybeShowBanner() {
    if (!mounted) return;

    final today = DateHelper.toStorageKey(DateHelper.today);
    final lastShown = ref.read(_bannerShownDateProvider);
    if (lastShown == today) return;
    ref.read(_bannerShownDateProvider.notifier).state = today;

    final tasks = ref.read(todayTasksProvider);
    final habits = ref.read(todayHabitsProvider);
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    final pendingHabits =
        habits.where((h) => h.completionHistory[today] != true).length;

    final String message;
    if (pendingTasks == 0 && pendingHabits == 0) {
      message = "You've completed everything today. Great work!";
    } else if (pendingTasks == 0) {
      message =
          "Tasks all done! $pendingHabits habit${pendingHabits > 1 ? 's' : ''} left today.";
    } else if (pendingHabits == 0) {
      message =
          "Habits done! $pendingTasks task${pendingTasks > 1 ? 's' : ''} remaining.";
    } else {
      message =
          "$pendingTasks task${pendingTasks > 1 ? 's' : ''} · $pendingHabits habit${pendingHabits > 1 ? 's' : ''} left today. Keep going!";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: pendingTasks > 0
            ? SnackBarAction(
                label: 'Tasks',
                onPressed: () => context.go(AppRoutes.tasks),
              )
            : pendingHabits > 0
                ? SnackBarAction(
                    label: 'Habits',
                    onPressed: () => context.go(AppRoutes.habits),
                  )
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final todayHabits = ref.watch(todayHabitsProvider);
    final focusState = ref.watch(focusProvider);
    final taskNotifier = ref.read(taskProvider.notifier);
    final habitNotifier = ref.read(habitProvider.notifier);

    final today = DateHelper.toStorageKey(DateHelper.today);
    final completedTasks = todayTasks.where((t) => t.isCompleted).length;
    final completedHabits = todayHabits
        .where((h) => h.completionHistory[today] == true)
        .length;
    final appStreak = habitNotifier.appStreakDays;
    final focusMinutes = focusState.sessions
        .where((s) =>
            s.isCompleted &&
            DateHelper.toStorageKey(s.startTime) ==
                DateHelper.toStorageKey(DateHelper.today))
        .fold(0, (sum, s) => sum + s.actualDurationMinutes);

    final totalItems =
        (todayTasks.length + todayHabits.length).clamp(1, double.infinity);
    final completedItems = (completedTasks + completedHabits);
    final overallProgress = completedItems / totalItems;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user?.name ?? 'there'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),
                // ── Streak banner ──────────────────────────────────────────
                if (appStreak > 0)
                  _buildStreakBanner(context, appStreak),
                const SizedBox(height: 16),
                // ── Shame Meter ────────────────────────────────────────────
                const ShameMeterCard(),
                const SizedBox(height: 16),
                // ── Progress card ──────────────────────────────────────────
                _buildProgressCard(
                  context,
                  completedTasks: completedTasks,
                  totalTasks: todayTasks.length,
                  completedHabits: completedHabits,
                  totalHabits: todayHabits.length,
                  focusMinutes: focusMinutes,
                  overallProgress: overallProgress,
                ),
                const SizedBox(height: 24),
                // ── Quick action cards ─────────────────────────────────────
                _buildQuickActions(context),
                const SizedBox(height: 24),
                // ── Ghost Competitor ───────────────────────────────────────
                const GhostCompetitorCard(),
                const SizedBox(height: 24),
                // ── Today's Tasks ──────────────────────────────────────────
                SectionHeader(
                  title: "Today's Tasks",
                  actionLabel: 'View All',
                  onAction: () => context.go(AppRoutes.tasks),
                ),
                const SizedBox(height: 12),
                if (todayTasks.isEmpty)
                  EmptyState(
                    icon: Icons.check_box_outline_blank_rounded,
                    message: 'No tasks for today.\nAll clear!',
                    actionLabel: 'Add Task',
                    onAction: () => context.go(AppRoutes.tasks),
                  )
                else
                  ...todayTasks
                      .take(4)
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TaskTile(
                            task: task,
                            onToggle: () =>
                                taskNotifier.toggleComplete(task.id),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditTaskScreen(task: task),
                                fullscreenDialog: true,
                              ),
                            ),
                            onDelete: () =>
                                taskNotifier.deleteTask(task.id),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                // ── Today's Habits ─────────────────────────────────────────
                SectionHeader(
                  title: "Today's Habits",
                  actionLabel: 'View All',
                  onAction: () => context.go(AppRoutes.habits),
                ),
                const SizedBox(height: 12),
                if (todayHabits.isEmpty)
                  EmptyState(
                    icon: Icons.loop_rounded,
                    message:
                        'No habits yet.\nBuild your first one.',
                    actionLabel: 'Add Habit',
                    onAction: () => context.go(AppRoutes.habits),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: todayHabits
                          .take(5)
                          .map((h) {
                            final isComplete =
                                h.completionHistory[today] == true;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: HabitCheckRow(
                                habit: h,
                                isCompleted: isComplete,
                                onToggle: () =>
                                    habitNotifier.toggleCompletion(h.id),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateHelper.greetingForTime()}, $name',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            DateHelper.formatDateFull(DateTime.now()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      actions: [
        _NotifBellButton(),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go(AppRoutes.settings),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStreakBanner(BuildContext context, int streak) {
    return GradientCard(
      colors: [
        const Color(0xFFF59E0B),
        const Color(0xFFF97316),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day streak',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                ),
                Text(
                  streak == 1
                      ? 'Keep it up! You just started.'
                      : 'Incredible consistency. Keep going!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '🔥',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required int completedTasks,
    required int totalTasks,
    required int completedHabits,
    required int totalHabits,
    required int focusMinutes,
    required double overallProgress,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Progress",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${(overallProgress * 100).toInt()}%',
                style:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: overallProgress.clamp(0.0, 1.0),
            backgroundColor: AppColors.primarySurface,
            progressColor: AppColors.primary,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(
                icon: Icons.check_box_rounded,
                color: AppColors.primary,
                label: 'Tasks',
                value: '$completedTasks/$totalTasks',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.loop_rounded,
                color: AppColors.success,
                label: 'Habits',
                value: '$completedHabits/$totalHabits',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.timer_rounded,
                color: AppColors.accent,
                label: 'Focus',
                value: DateHelper.formatDuration(focusMinutes),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.timer_rounded,
            label: 'Start Focus',
            color: AppColors.primary,
            bgColor: AppColors.primarySurface,
            onTap: () => context.go(AppRoutes.focus),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_task_rounded,
            label: 'Add Task',
            color: AppColors.success,
            bgColor: AppColors.successSurface,
            onTap: () => context.go(AppRoutes.tasks),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
            onTap: () => context.go(AppRoutes.analytics),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
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
      ),
    );
  }
}

// ─── Notification bell with unread badge ──────────────────────────────────────

class _NotifBellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotifCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.go(AppRoutes.notifications),
          color: AppColors.textSecondary,
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
