import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/focus_session_model.dart';
import '../../providers/focus_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/focus/timer_ring.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final user = ref.watch(userProvider);
    final notifier = ref.read(focusProvider.notifier);

    // Sync user-configured durations into focus state on first build
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setDurations(
          focusMinutes: user.defaultFocusDurationMinutes,
          shortBreakMinutes: user.defaultShortBreakMinutes,
          longBreakMinutes: user.defaultLongBreakMinutes,
        );
      });
    }

    final timerColor = _colorForType(state.sessionType);
    final isIdle = state.timerState == TimerState.idle;
    final isRunning = state.timerState == TimerState.running;
    final isPaused = state.timerState == TimerState.paused;
    final isFinished = state.timerState == TimerState.finished;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Focus'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                // Session type selector
                if (isIdle || isFinished)
                  _buildTypeSelector(context, state, notifier),
                const SizedBox(height: 32),
                // Timer ring
                Center(
                  child: TimerRing(
                    progress: isIdle ? 0.0 : state.progress,
                    remainingSeconds: isIdle
                        ? state.totalDurationSeconds
                        : state.remainingSeconds,
                    color: timerColor,
                    size: 260,
                    label: state.sessionType.label.toUpperCase(),
                    isRunning: isRunning,
                  ),
                ),
                const SizedBox(height: 40),
                // Session complete banner
                if (isFinished)
                  _buildCompleteBanner(context, state)
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 16),
                // Controls
                _buildControls(
                  context,
                  state: state,
                  notifier: notifier,
                  isRunning: isRunning,
                  isPaused: isPaused,
                  isIdle: isIdle,
                  isFinished: isFinished,
                  timerColor: timerColor,
                ),
                const SizedBox(height: 32),
                // Today stats
                _buildTodayStats(context, state),
                const SizedBox(height: 24),
                // Task link
                if (isIdle)
                  _buildTaskLink(context, ref, state, notifier),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(
      BuildContext context, FocusState state, FocusNotifier notifier) {
    final types = [
      (SessionType.focus, 'Focus'),
      (SessionType.shortBreak, 'Short Break'),
      (SessionType.longBreak, 'Long Break'),
    ];

    return Row(
      children: types.map((entry) {
        final (type, label) = entry;
        final isSelected = state.sessionType == type;
        final color = _colorForType(type);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => notifier.setSessionType(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected ? color : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMd),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color: isSelected
                            ? color
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompleteBanner(BuildContext context, FocusState state) {
    return AppCard(
      color: AppColors.successSurface,
      border: Border.all(
          color: AppColors.success.withOpacity(0.3)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.sessionType == SessionType.focus
                      ? 'Focus session complete!'
                      : 'Break complete!',
                  style:
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.success,
                          ),
                ),
                Text(
                  state.sessionType == SessionType.focus
                      ? 'Well done. Time for a break.'
                      : 'Ready to focus again?',
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context, {
    required FocusState state,
    required FocusNotifier notifier,
    required bool isRunning,
    required bool isPaused,
    required bool isIdle,
    required bool isFinished,
    required Color timerColor,
  }) {
    if (isIdle || isFinished) {
      return PrimaryButton(
        label: isFinished ? 'Start Next Session' : 'Start Focus',
        onTap: () {
          if (isFinished) notifier.resetTimer();
          notifier.startSession();
        },
        color: timerColor,
        icon: const Icon(Icons.play_arrow_rounded,
            color: Colors.white, size: 20),
      );
    }

    return Row(
      children: [
        if (isPaused)
          Expanded(
            child: PrimaryButton(
              label: 'Resume',
              onTap: notifier.resumeSession,
              color: timerColor,
              icon: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20),
            ),
          )
        else
          Expanded(
            child: PrimaryButton(
              label: 'Pause',
              onTap: notifier.pauseSession,
              color: timerColor.withOpacity(0.8),
              icon: const Icon(Icons.pause_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        const SizedBox(width: 12),
        SizedBox(
          width: AppDimensions.buttonHeight,
          height: AppDimensions.buttonHeight,
          child: OutlinedButton(
            onPressed: notifier.stopSession,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd),
              ),
            ),
            child: const Icon(Icons.stop_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(BuildContext context, FocusState state) {
    final todayKey =
        DateHelper.toStorageKey(DateHelper.today);
    final todaySessions = state.sessions
        .where((s) =>
            s.isCompleted &&
            s.sessionType == SessionType.focus &&
            DateHelper.toStorageKey(s.startTime) == todayKey)
        .toList();
    final todayMinutes = todaySessions.fold(
        0, (sum, s) => sum + s.actualDurationMinutes);

    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${todaySessions.length}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sessions Today',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                          color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  DateHelper.formatDuration(todayMinutes),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Focus Time',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                          color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${state.sessionsCompleted}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This Round',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                          color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskLink(BuildContext context, WidgetRef ref,
      FocusState state, FocusNotifier notifier) {
    final tasks = ref.watch(taskProvider);
    final activeTasks =
        tasks.where((t) => !t.isCompleted).toList();
    final linked = state.linkedTaskId != null
        ? activeTasks.where((t) => t.id == state.linkedTaskId).firstOrNull
        : null;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus on',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (linked != null)
            Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    linked.title,
                    style:
                        Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => notifier.setLinkedTask(null),
                  child: const Icon(Icons.close_rounded,
                      size: 16,
                      color: AppColors.textTertiary),
                ),
              ],
            )
          else
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: null,
                hint: const Text('Link to a task (optional)'),
                isExpanded: true,
                items: activeTasks
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          t.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) => notifier.setLinkedTask(id),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppColors.primary;
      case SessionType.shortBreak:
        return AppColors.success;
      case SessionType.longBreak:
        return const Color(0xFF7C3AED);
    }
  }
}
