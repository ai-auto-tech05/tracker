import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/tasks/task_tile.dart';
import '../../widgets/tasks/task_funeral_tile.dart';
import 'add_task_sheet.dart';
import 'edit_task_screen.dart';

enum _TaskFilter { all, today, upcoming, done, overdue }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.today;

  List<TaskModel> _applyFilter(List<TaskModel> all) {
    final notifier = ref.read(taskProvider.notifier);
    switch (_filter) {
      case _TaskFilter.all:
        return all.where((t) => !t.isCompleted).toList();
      case _TaskFilter.today:
        return notifier.todayTasks;
      case _TaskFilter.upcoming:
        return notifier.upcomingTasks;
      case _TaskFilter.done:
        return notifier.completedTasks;
      case _TaskFilter.overdue:
        return notifier.overdueTasks;
    }
  }

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }

  Future<void> _openEdit(TaskModel task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: task),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final filtered = _applyFilter(tasks);
    final notifier = ref.read(taskProvider.notifier);
    final overdueCount = notifier.overdueTasks.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Tasks'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: _showAddTask,
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
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(_TaskFilter.today, 'Today'),
                      const SizedBox(width: 8),
                      _filterChip(_TaskFilter.all, 'All'),
                      const SizedBox(width: 8),
                      _filterChip(_TaskFilter.upcoming, 'Upcoming'),
                      const SizedBox(width: 8),
                      _filterChip(
                        _TaskFilter.overdue,
                        overdueCount > 0
                            ? 'Overdue ($overdueCount)'
                            : 'Overdue',
                        badgeColor:
                            overdueCount > 0 ? AppColors.error : null,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(_TaskFilter.done, 'Done'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Task list
                if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.task_alt_rounded,
                    message: _emptyMessage(),
                    actionLabel: 'Add Task',
                    onAction: _showAddTask,
                  )
                else
                  ...filtered.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskTile(
                        task: task,
                        onToggle: () =>
                            notifier.toggleComplete(task.id),
                        onTap: () => _openEdit(task),
                        onDelete: () => _confirmDelete(task),
                      ),
                    ),
                  ),
                // ── Task Graveyard ─────────────────────────────────────────
                _GraveyardSection(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    _TaskFilter filter,
    String label, {
    Color? badgeColor,
  }) {
    final isActive = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: badgeColor != null && !isActive
                ? badgeColor.withOpacity(0.4)
                : (isActive ? AppColors.primary : AppColors.divider),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isActive
                    ? Colors.white
                    : (badgeColor ?? AppColors.textSecondary),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case _TaskFilter.today:
        return "No tasks for today.\nYou're all caught up!";
      case _TaskFilter.all:
        return 'No active tasks.\nAdd your first task.';
      case _TaskFilter.upcoming:
        return 'Nothing upcoming.\nPlan ahead!';
      case _TaskFilter.overdue:
        return 'No overdue tasks.\nGreat work!';
      case _TaskFilter.done:
        return 'Nothing completed yet.\nGet started!';
    }
  }

  void _confirmDelete(TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove task?'),
        content: Text('"${task.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(taskProvider.notifier).buryTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task sent to the graveyard. RIP.'),
                ),
              );
            },
            child: const Text('⚰️ Bury'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(taskProvider.notifier).deleteTask(task.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Task Graveyard section ───────────────────────────────────────────────────

class _GraveyardSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GraveyardSection> createState() => _GraveyardSectionState();
}

class _GraveyardSectionState extends ConsumerState<_GraveyardSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final buried = ref.watch(buriedTasksProvider);
    if (buried.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(taskProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Text('⚰️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Task Graveyard (${buried.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          ...buried.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskFuneralTile(
                task: task,
                onRevive: () {
                  notifier.reviveTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Task revived. Try not to bury it again.')),
                  );
                },
                onDelete: () => notifier.deleteTask(task.id),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
