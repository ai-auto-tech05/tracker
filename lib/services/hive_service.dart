import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/focus_session_model.dart';
import '../models/daily_progress_model.dart';
import '../models/app_notification_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _userBox = 'user_box';
  static const String _taskBox = 'task_box';
  static const String _habitBox = 'habit_box';
  static const String _focusBox = 'focus_box';
  static const String _progressBox = 'progress_box';
  static const String _settingsBox = 'settings_box';
  static const String _notifBox    = 'notif_box';

  static const String _userKey = 'current_user';

  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_userBox),
      Hive.openBox<String>(_taskBox),
      Hive.openBox<String>(_habitBox),
      Hive.openBox<String>(_focusBox),
      Hive.openBox<String>(_progressBox),
      Hive.openBox<dynamic>(_settingsBox),
      Hive.openBox<String>(_notifBox),
    ]);
  }

  // ─── User ────────────────────────────────────────────────────────────────

  Box<String> get _users => Hive.box<String>(_userBox);

  Future<void> saveUser(UserModel user) async {
    await _users.put(_userKey, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final raw = _users.get(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ─── Tasks ───────────────────────────────────────────────────────────────

  Box<String> get _tasks => Hive.box<String>(_taskBox);

  Future<void> saveTask(TaskModel task) async {
    await _tasks.put(task.id, jsonEncode(task.toJson()));
  }

  Future<void> deleteTask(String id) async {
    await _tasks.delete(id);
  }

  List<TaskModel> getAllTasks() {
    return _tasks.values
        .map((raw) {
          try {
            return TaskModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<TaskModel>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ─── Habits ──────────────────────────────────────────────────────────────

  Box<String> get _habits => Hive.box<String>(_habitBox);

  Future<void> saveHabit(HabitModel habit) async {
    await _habits.put(habit.id, jsonEncode(habit.toJson()));
  }

  Future<void> deleteHabit(String id) async {
    await _habits.delete(id);
  }

  List<HabitModel> getAllHabits() {
    return _habits.values
        .map((raw) {
          try {
            return HabitModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<HabitModel>()
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // ─── Focus Sessions ──────────────────────────────────────────────────────

  Box<String> get _focus => Hive.box<String>(_focusBox);

  Future<void> saveFocusSession(FocusSessionModel session) async {
    await _focus.put(session.id, jsonEncode(session.toJson()));
  }

  Future<void> deleteFocusSession(String id) async {
    await _focus.delete(id);
  }

  List<FocusSessionModel> getAllFocusSessions() {
    return _focus.values
        .map((raw) {
          try {
            return FocusSessionModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<FocusSessionModel>()
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // ─── Daily Progress ──────────────────────────────────────────────────────

  Box<String> get _progress => Hive.box<String>(_progressBox);

  Future<void> saveDailyProgress(DailyProgressModel p) async {
    await _progress.put(p.date, jsonEncode(p.toJson()));
  }

  DailyProgressModel? getDailyProgress(String date) {
    final raw = _progress.get(date);
    if (raw == null) return null;
    return DailyProgressModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  List<DailyProgressModel> getProgressRange(
      String startDate, String endDate) {
    return _progress.keys
        .whereType<String>()
        .where((k) => k.compareTo(startDate) >= 0 && k.compareTo(endDate) <= 0)
        .map((k) {
          final raw = _progress.get(k);
          if (raw == null) return null;
          try {
            return DailyProgressModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<DailyProgressModel>()
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ─── In-App Notifications ────────────────────────────────────────────────

  Box<String> get _notifs => Hive.box<String>(_notifBox);

  Future<void> saveNotification(AppNotificationModel n) async {
    await _notifs.put(n.id, jsonEncode(n.toJson()));
  }

  Future<void> deleteNotification(String id) async {
    await _notifs.delete(id);
  }

  List<AppNotificationModel> getAllNotifications() {
    return _notifs.values
        .map((raw) {
          try {
            return AppNotificationModel.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<AppNotificationModel>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> clearAllNotifications() async => _notifs.clear();

  // ─── Settings ────────────────────────────────────────────────────────────

  Box<dynamic> get _settings => Hive.box<dynamic>(_settingsBox);

  Future<void> setSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  T? getSetting<T>(String key) => _settings.get(key) as T?;

  // ─── Nuke ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await Future.wait([
      _users.clear(),
      _tasks.clear(),
      _habits.clear(),
      _focus.clear(),
      _progress.clear(),
      _settings.clear(),
      _notifs.clear(),
    ]);
  }
}
