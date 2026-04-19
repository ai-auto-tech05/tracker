enum SessionType { focus, shortBreak, longBreak }

extension SessionTypeExt on SessionType {
  String get label {
    switch (this) {
      case SessionType.focus:
        return 'Focus';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String get value => name;

  static SessionType fromString(String s) =>
      SessionType.values.firstWhere((e) => e.name == s,
          orElse: () => SessionType.focus);
}

class FocusSessionModel {
  final String id;
  final String? linkedTaskId;
  final SessionType sessionType;
  final int plannedDurationMinutes;
  final int actualDurationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final String? notes;

  const FocusSessionModel({
    required this.id,
    this.linkedTaskId,
    this.sessionType = SessionType.focus,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes = 0,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.notes,
  });

  bool get isFocusSession => sessionType == SessionType.focus;

  FocusSessionModel copyWith({
    String? linkedTaskId,
    int? actualDurationMinutes,
    DateTime? endTime,
    bool? isCompleted,
    String? notes,
  }) {
    return FocusSessionModel(
      id: id,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      sessionType: sessionType,
      plannedDurationMinutes: plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'linkedTaskId': linkedTaskId,
        'sessionType': sessionType.value,
        'plannedDurationMinutes': plannedDurationMinutes,
        'actualDurationMinutes': actualDurationMinutes,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isCompleted': isCompleted,
        'notes': notes,
      };

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) =>
      FocusSessionModel(
        id: json['id'] as String,
        linkedTaskId: json['linkedTaskId'] as String?,
        sessionType: SessionTypeExt.fromString(
            json['sessionType'] as String? ?? ''),
        plannedDurationMinutes:
            json['plannedDurationMinutes'] as int? ?? 25,
        actualDurationMinutes:
            json['actualDurationMinutes'] as int? ?? 0,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        notes: json['notes'] as String?,
      );
}
