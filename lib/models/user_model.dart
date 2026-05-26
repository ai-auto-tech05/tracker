class UserModel {
  final String id;
  final String name;
  final bool onboardingCompleted;
  final int dailyFocusGoalMinutes;
  final int defaultFocusDurationMinutes;
  final int defaultShortBreakMinutes;
  final int defaultLongBreakMinutes;
  final bool darkMode;
  final bool notificationsEnabled;
  // Quiz-derived fields — set during onboarding
  final String productivityProfile; // e.g. "Last-Minute Survivor"
  final String notificationStyle;   // 'gentle' | 'sarcastic' | 'brutal'
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.onboardingCompleted = false,
    this.dailyFocusGoalMinutes = 120,
    this.defaultFocusDurationMinutes = 25,
    this.defaultShortBreakMinutes = 5,
    this.defaultLongBreakMinutes = 15,
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.productivityProfile = '',
    this.notificationStyle = 'sarcastic',
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    bool? onboardingCompleted,
    int? dailyFocusGoalMinutes,
    int? defaultFocusDurationMinutes,
    int? defaultShortBreakMinutes,
    int? defaultLongBreakMinutes,
    bool? darkMode,
    bool? notificationsEnabled,
    String? productivityProfile,
    String? notificationStyle,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      dailyFocusGoalMinutes:
          dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
      defaultFocusDurationMinutes:
          defaultFocusDurationMinutes ?? this.defaultFocusDurationMinutes,
      defaultShortBreakMinutes:
          defaultShortBreakMinutes ?? this.defaultShortBreakMinutes,
      defaultLongBreakMinutes:
          defaultLongBreakMinutes ?? this.defaultLongBreakMinutes,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      productivityProfile: productivityProfile ?? this.productivityProfile,
      notificationStyle: notificationStyle ?? this.notificationStyle,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'onboardingCompleted': onboardingCompleted,
        'dailyFocusGoalMinutes': dailyFocusGoalMinutes,
        'defaultFocusDurationMinutes': defaultFocusDurationMinutes,
        'defaultShortBreakMinutes': defaultShortBreakMinutes,
        'defaultLongBreakMinutes': defaultLongBreakMinutes,
        'darkMode': darkMode,
        'notificationsEnabled': notificationsEnabled,
        'productivityProfile': productivityProfile,
        'notificationStyle': notificationStyle,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
        dailyFocusGoalMinutes: json['dailyFocusGoalMinutes'] as int? ?? 120,
        defaultFocusDurationMinutes:
            json['defaultFocusDurationMinutes'] as int? ?? 25,
        defaultShortBreakMinutes:
            json['defaultShortBreakMinutes'] as int? ?? 5,
        defaultLongBreakMinutes:
            json['defaultLongBreakMinutes'] as int? ?? 15,
        darkMode: json['darkMode'] as bool? ?? false,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        productivityProfile: json['productivityProfile'] as String? ?? '',
        notificationStyle: json['notificationStyle'] as String? ?? 'sarcastic',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
