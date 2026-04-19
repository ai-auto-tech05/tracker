import '../core/utils/date_helper.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, done, overdue }

extension TaskPriorityExt on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String get value => name;

  static TaskPriority fromString(String s) =>
      TaskPriority.values.firstWhere((e) => e.name == s,
          orElse: () => TaskPriority.medium);
}

extension TaskStatusExt on TaskStatus {
  String get value => name;

  static TaskStatus fromString(String s) =>
      TaskStatus.values.firstWhere((e) => e.name == s,
          orElse: () => TaskStatus.todo);
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> tags;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.tags = const [],
  });

  bool get isCompleted => status == TaskStatus.done;

  bool get isOverdue =>
      !isCompleted &&
      dueDate != null &&
      DateHelper.isOverdue(dueDate!);

  bool get isDueToday => dueDate != null && DateHelper.isToday(dueDate!);

  TaskModel copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.value,
        'status': status.value,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'tags': tags,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        priority: TaskPriorityExt.fromString(json['priority'] as String? ?? ''),
        status: TaskStatusExt.fromString(json['status'] as String? ?? ''),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
