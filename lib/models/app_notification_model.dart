import 'package:flutter/material.dart';

enum AppNotifType { taskOverdue, habitMissed, focusDone, alexTaunt, system }

extension AppNotifTypeExt on AppNotifType {
  String get displayName {
    switch (this) {
      case AppNotifType.taskOverdue:
        return 'Task Overdue';
      case AppNotifType.habitMissed:
        return 'Habit Missed';
      case AppNotifType.focusDone:
        return 'Focus Done';
      case AppNotifType.alexTaunt:
        return 'Alex';
      case AppNotifType.system:
        return 'System';
    }
  }

  Color get accentColor {
    switch (this) {
      case AppNotifType.taskOverdue:
        return const Color(0xFFEF4444);
      case AppNotifType.habitMissed:
        return const Color(0xFFF97316);
      case AppNotifType.focusDone:
        return const Color(0xFF10B981);
      case AppNotifType.alexTaunt:
        return const Color(0xFF8B5CF6);
      case AppNotifType.system:
        return const Color(0xFF4F46E5);
    }
  }

  IconData get icon {
    switch (this) {
      case AppNotifType.taskOverdue:
        return Icons.assignment_late_rounded;
      case AppNotifType.habitMissed:
        return Icons.loop_rounded;
      case AppNotifType.focusDone:
        return Icons.timer_rounded;
      case AppNotifType.alexTaunt:
        return Icons.person_rounded;
      case AppNotifType.system:
        return Icons.notifications_rounded;
    }
  }
}

class AppNotificationModel {
  final String id;
  final AppNotifType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotificationModel markRead() => AppNotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) =>
      AppNotificationModel(
        id: json['id'] as String,
        type: AppNotifType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AppNotifType.system,
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}
