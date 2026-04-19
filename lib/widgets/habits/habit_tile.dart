import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/habit_model.dart';

class HabitTile extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(habit.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isCompletedToday
                ? habitColor.withOpacity(0.4)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: habitColor.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                _iconData(habit.iconName),
                color: habitColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 12,
                        color: habit.currentStreak > 0
                            ? AppColors.accent
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${habit.currentStreak} day streak',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: habit.currentStreak > 0
                                  ? AppColors.accent
                                  : AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Check button
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompletedToday
                      ? habitColor
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompletedToday
                        ? habitColor
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isCompletedToday
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  IconData _iconData(String name) {
    const map = {
      'check_circle': Icons.check_circle_outline_rounded,
      'fitness': Icons.fitness_center_rounded,
      'book': Icons.menu_book_rounded,
      'water': Icons.water_drop_outlined,
      'sleep': Icons.bedtime_rounded,
      'meditate': Icons.self_improvement_rounded,
      'run': Icons.directions_run_rounded,
      'code': Icons.code_rounded,
      'music': Icons.music_note_rounded,
      'food': Icons.restaurant_rounded,
      'heart': Icons.favorite_outline_rounded,
      'star': Icons.star_outline_rounded,
      'brain': Icons.psychology_outlined,
      'pencil': Icons.edit_outlined,
      'money': Icons.attach_money_rounded,
      'walk': Icons.directions_walk_rounded,
    };
    return map[name] ?? Icons.check_circle_outline_rounded;
  }
}

// Grid-style habit item for dashboard quick view
class HabitCheckRow extends StatelessWidget {
  final HabitModel habit;
  final bool isCompleted;
  final VoidCallback onToggle;

  const HabitCheckRow({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(habit.colorValue);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: habitColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: habitColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            habit.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? AppColors.textTertiary : null,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? habitColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? habitColor : AppColors.border,
                width: 1.5,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 12, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }
}
