import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/primary_button.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final TaskModel? editingTask;

  const AddTaskSheet({super.key, this.editingTask});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.editingTask;
    if (t != null) {
      _titleController.text = t.title;
      _descController.text = t.description ?? '';
      _priority = t.priority;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final notifier = ref.read(taskProvider.notifier);
    if (widget.editingTask != null) {
      await notifier.updateTask(
        widget.editingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        ),
      );
    } else {
      await notifier.addTask(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
            widget.editingTask != null ? 'Edit Task' : 'New Task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          // Title
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Task title'),
          ),
          const SizedBox(height: 12),
          // Description
          TextField(
            controller: _descController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(hintText: 'Description (optional)'),
          ),
          const SizedBox(height: 16),
          // Priority
          Text(
            'Priority',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: TaskPriority.values.map((p) {
              final isSelected = _priority == p;
              final color = _priorityColor(p);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : AppColors.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.label,
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Due date
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _dueDate != null
                          ? DateHelper.formatDateFull(_dueDate!)
                          : 'Set due date (optional)',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _dueDate != null
                                    ? null
                                    : AppColors.textTertiary,
                              ),
                    ),
                  ),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textTertiary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: widget.editingTask != null ? 'Save Changes' : 'Add Task',
            isLoading: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }

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
}
