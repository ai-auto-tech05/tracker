import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/task_model.dart';

class TaskFuneralTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onRevive;
  final VoidCallback onDelete;

  const TaskFuneralTile({
    required this.task,
    required this.onRevive,
    required this.onDelete,
    super.key,
  });

  static const List<String> _epitaphs = [
    "Here lies a task that never got started.",
    "Postponed to death. No flowers, please.",
    "Cause of death: 'I'll do it tomorrow.'",
    "They had so much potential.",
    "RIP. Survived by 47 other incomplete tasks.",
    "Not completed, but never forgotten. (Unlike this task.)",
    "A good idea, born too soon.",
    "Went from 'urgent' to 'eternal'.",
    "It asked for so little. You gave less.",
    "Marked as overdue more times than it was ever worked on.",
    "Short life. Zero output.",
    "Died waiting. Still waiting.",
  ];

  String get _epitaph =>
      _epitaphs[task.id.hashCode.abs() % _epitaphs.length];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚰️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                // Delete
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '"$_epitaph"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRevive,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.replay_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Revive',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
