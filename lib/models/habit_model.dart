enum HabitFrequency { daily, weekly }

extension HabitFrequencyExt on HabitFrequency {
  String get label => name[0].toUpperCase() + name.substring(1);
  String get value => name;

  static HabitFrequency fromString(String s) =>
      HabitFrequency.values.firstWhere((e) => e.name == s,
          orElse: () => HabitFrequency.daily);
}

class HabitModel {
  final String id;
  final String title;
  final String? description;
  final String iconName;
  final int colorValue; // stored as int (Color.value)
  final HabitFrequency frequency;
  /// For weekly habits: which weekday indices (1=Mon…7=Sun) are target days.
  final List<int> targetWeekdays;
  /// Completion history: key = 'yyyy-MM-dd', value = true if completed.
  final Map<String, bool> completionHistory;
  final int currentStreak;
  final int longestStreak;
  final bool isArchived;
  final DateTime createdAt;
  final String? reminderTime; // 'HH:mm' format

  const HabitModel({
    required this.id,
    required this.title,
    this.description,
    this.iconName = 'check_circle',
    required this.colorValue,
    this.frequency = HabitFrequency.daily,
    this.targetWeekdays = const [],
    this.completionHistory = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isArchived = false,
    required this.createdAt,
    this.reminderTime,
  });

  HabitModel copyWith({
    String? title,
    String? description,
    String? iconName,
    int? colorValue,
    HabitFrequency? frequency,
    List<int>? targetWeekdays,
    Map<String, bool>? completionHistory,
    int? currentStreak,
    int? longestStreak,
    bool? isArchived,
    String? reminderTime,
    bool clearReminder = false,
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      targetWeekdays: targetWeekdays ?? this.targetWeekdays,
      completionHistory: completionHistory ?? this.completionHistory,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconName': iconName,
        'colorValue': colorValue,
        'frequency': frequency.value,
        'targetWeekdays': targetWeekdays,
        'completionHistory':
            completionHistory.map((k, v) => MapEntry(k, v)),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'reminderTime': reminderTime,
      };

  factory HabitModel.fromJson(Map<String, dynamic> json) => HabitModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        iconName: json['iconName'] as String? ?? 'check_circle',
        colorValue: json['colorValue'] as int,
        frequency:
            HabitFrequencyExt.fromString(json['frequency'] as String? ?? ''),
        targetWeekdays: (json['targetWeekdays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        completionHistory: (json['completionHistory'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as bool)) ??
            {},
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        isArchived: json['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reminderTime: json['reminderTime'] as String?,
      );
}
