class DailyProgressModel {
  final String date; // 'yyyy-MM-dd'
  final int tasksCompleted;
  final int tasksTotal;
  final int habitsCompleted;
  final int habitsTotal;
  final int focusMinutes;
  final bool checkInDone;

  const DailyProgressModel({
    required this.date,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.habitsCompleted = 0,
    this.habitsTotal = 0,
    this.focusMinutes = 0,
    this.checkInDone = false,
  });

  double get taskCompletionRate =>
      tasksTotal == 0 ? 0.0 : tasksCompleted / tasksTotal;

  double get habitCompletionRate =>
      habitsTotal == 0 ? 0.0 : habitsCompleted / habitsTotal;

  double get overallCompletionRate {
    final total = tasksTotal + habitsTotal;
    if (total == 0) return 0.0;
    return (tasksCompleted + habitsCompleted) / total;
  }

  DailyProgressModel copyWith({
    int? tasksCompleted,
    int? tasksTotal,
    int? habitsCompleted,
    int? habitsTotal,
    int? focusMinutes,
    bool? checkInDone,
  }) {
    return DailyProgressModel(
      date: date,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      habitsTotal: habitsTotal ?? this.habitsTotal,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      checkInDone: checkInDone ?? this.checkInDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'tasksCompleted': tasksCompleted,
        'tasksTotal': tasksTotal,
        'habitsCompleted': habitsCompleted,
        'habitsTotal': habitsTotal,
        'focusMinutes': focusMinutes,
        'checkInDone': checkInDone,
      };

  factory DailyProgressModel.fromJson(Map<String, dynamic> json) =>
      DailyProgressModel(
        date: json['date'] as String,
        tasksCompleted: json['tasksCompleted'] as int? ?? 0,
        tasksTotal: json['tasksTotal'] as int? ?? 0,
        habitsCompleted: json['habitsCompleted'] as int? ?? 0,
        habitsTotal: json['habitsTotal'] as int? ?? 0,
        focusMinutes: json['focusMinutes'] as int? ?? 0,
        checkInDone: json['checkInDone'] as bool? ?? false,
      );
}
