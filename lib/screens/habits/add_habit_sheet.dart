import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/primary_button.dart';

const _iconOptions = [
  ('check_circle', Icons.check_circle_outline_rounded),
  ('fitness', Icons.fitness_center_rounded),
  ('book', Icons.menu_book_rounded),
  ('water', Icons.water_drop_outlined),
  ('sleep', Icons.bedtime_rounded),
  ('meditate', Icons.self_improvement_rounded),
  ('run', Icons.directions_run_rounded),
  ('code', Icons.code_rounded),
  ('music', Icons.music_note_rounded),
  ('food', Icons.restaurant_rounded),
  ('heart', Icons.favorite_outline_rounded),
  ('star', Icons.star_outline_rounded),
  ('brain', Icons.psychology_outlined),
  ('pencil', Icons.edit_outlined),
  ('money', Icons.attach_money_rounded),
  ('walk', Icons.directions_walk_rounded),
];

class AddHabitSheet extends ConsumerStatefulWidget {
  final HabitModel? editingHabit;

  const AddHabitSheet({super.key, this.editingHabit});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _titleController = TextEditingController();
  String _selectedIcon = 'check_circle';
  int _selectedColorIndex = 0;
  HabitFrequency _frequency = HabitFrequency.daily;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.editingHabit;
    if (h != null) {
      _titleController.text = h.title;
      _selectedIcon = h.iconName;
      _selectedColorIndex = AppColors.habitColors
          .indexWhere((c) => c.value == h.colorValue)
          .clamp(0, AppColors.habitColors.length - 1);
      _frequency = h.frequency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final notifier = ref.read(habitProvider.notifier);
    final colorValue =
        AppColors.habitColors[_selectedColorIndex].value;

    if (widget.editingHabit != null) {
      await notifier.updateHabit(
        widget.editingHabit!.copyWith(
          title: _titleController.text.trim(),
          iconName: _selectedIcon,
          colorValue: colorValue,
          frequency: _frequency,
        ),
      );
    } else {
      await notifier.addHabit(
        title: _titleController.text.trim(),
        iconName: _selectedIcon,
        colorValue: colorValue,
        frequency: _frequency,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        AppColors.habitColors[_selectedColorIndex];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            AppDimensions.screenPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.editingHabit != null ? 'Edit Habit' : 'New Habit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // Title
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Habit name'),
            ),
            const SizedBox(height: 20),
            // Icon picker
            Text(
              'Icon',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _iconOptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (name, iconData) = _iconOptions[i];
                  final isSelected = _selectedIcon == name;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIcon = name),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withOpacity(0.15)
                            : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? selectedColor
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected
                            ? selectedColor
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Color picker
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                AppColors.habitColors.length,
                (i) {
                  final color = AppColors.habitColors[i];
                  final isSelected = _selectedColorIndex == i;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Frequency
            Text(
              'Frequency',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: HabitFrequency.values.map((f) {
                final isSelected = _frequency == f;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _frequency = f),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withOpacity(0.12)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? selectedColor
                                : AppColors.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd),
                        ),
                        child: Text(
                          f.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: isSelected
                                    ? selectedColor
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
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: widget.editingHabit != null
                  ? 'Save Changes'
                  : 'Create Habit',
              isLoading: _saving,
              onTap: _save,
              color: selectedColor,
            ),
          ],
        ),
      ),
    );
  }
}
