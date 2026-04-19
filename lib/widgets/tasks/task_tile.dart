import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;    // opens edit screen
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onDelete,
  });

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = task.isOverdue;
    final isComplete = task.isCompleted;

    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        onDelete!();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isOverdue
                  ? AppColors.error.withOpacity(0.3)
                  : (isDark ? AppColors.darkDivider : AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isComplete
                            ? AppColors.success
                            : _priorityColor(task.priority),
                        width: 2,
                      ),
                    ),
                    child: isComplete
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: isComplete
                                ? TextDecoration.lineThrough
                                : null,
                            color: isComplete
                                ? AppColors.textTertiary
                                : null,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (task.dueDate != null || task.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateHelper.formatDate(task.dueDate!),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isOverdue
                                        ? AppColors.error
                                        : AppColors.textTertiary,
                                  ),
                            ),
                          ],
                          if (task.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.tags.first,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Priority dot + 3-dot menu
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _priorityColor(task.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0);
  }
}
