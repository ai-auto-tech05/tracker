import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/primary_button.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _categoryCtrl;
  late TaskPriority _priority;
  late DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _categoryCtrl = TextEditingController(
        text: widget.task.tags.isNotEmpty ? widget.task.tags.first : '');
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final category = _categoryCtrl.text.trim();
    final updated = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      clearDueDate: _dueDate == null,
      tags: category.isEmpty ? [] : [category],
    );

    await ref.read(taskProvider.notifier).updateTask(updated);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Quick complete toggle in app bar
          IconButton(
            tooltip: widget.task.isCompleted
                ? 'Mark incomplete'
                : 'Mark complete',
            icon: Icon(
              widget.task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: widget.task.isCompleted
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
            onPressed: () async {
              await ref
                  .read(taskProvider.notifier)
                  .toggleComplete(widget.task.id);
              if (mounted) Navigator.pop(context, true);
            },
          ),
          // Delete
          IconButton(
            tooltip: 'Delete task',
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          children: [
            // ── Status chip ──────────────────────────────────────────────
            if (widget.task.isCompleted || widget.task.isOverdue)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.task.isCompleted
                      ? AppColors.successSurface
                      : AppColors.errorSurface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: widget.task.isCompleted
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.task.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      size: 16,
                      color: widget.task.isCompleted
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.task.isCompleted ? 'Completed' : 'Overdue',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: widget.task.isCompleted
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

            // ── Title ─────────────────────────────────────────────────────
            _sectionLabel(context, 'Title'),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: const InputDecoration(
                hintText: 'Task title',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────────────
            _sectionLabel(context, 'Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add more details (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ── Priority ──────────────────────────────────────────────────
            _sectionLabel(context, 'Priority'),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = _priority == p;
                final color = _priorityColor(p);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
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
            const SizedBox(height: 20),

            // ── Due Date ──────────────────────────────────────────────────
            _sectionLabel(context, 'Due Date'),
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
                  border: Border.all(
                    color: _dueDate != null && widget.task.isOverdue
                        ? AppColors.error.withOpacity(0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: _dueDate != null && widget.task.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dueDate != null
                            ? DateHelper.formatDateFull(_dueDate!)
                            : 'Set due date',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: _dueDate != null
                                  ? (widget.task.isOverdue
                                      ? AppColors.error
                                      : null)
                                  : AppColors.textTertiary,
                            ),
                      ),
                    ),
                    if (_dueDate != null) ...[
                      // Reschedule quick buttons
                      _QuickDateButton(
                        label: 'Today',
                        onTap: () => setState(
                            () => _dueDate = DateHelper.today),
                      ),
                      const SizedBox(width: 6),
                      _QuickDateButton(
                        label: 'Tomorrow',
                        onTap: () => setState(() => _dueDate =
                            DateHelper.today
                                .add(const Duration(days: 1))),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Category / Tag ────────────────────────────────────────────
            _sectionLabel(context, 'Category (optional)'),
            TextFormField(
              controller: _categoryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Work, Personal, Health',
                prefixIcon: Icon(Icons.label_outline_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 32),

            // ── Save ──────────────────────────────────────────────────────
            PrimaryButton(
              label: 'Save Changes',
              isLoading: _saving,
              onTap: _save,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                label: const Text('Delete Task',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content:
            Text('Delete "${widget.task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(taskProvider.notifier)
                  .deleteTask(widget.task.id);
              if (mounted) Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );

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

class _QuickDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
