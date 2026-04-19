import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../models/auth_user_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../core/utils/date_helper.dart';
import '../core/utils/streak_calculator.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

final habitProvider =
    StateNotifierProvider<HabitNotifier, List<HabitModel>>((ref) {
  final hive = ref.read(hiveServiceProvider);
  final firestore = ref.read(firestoreServiceProvider);
  final authUser = ref.watch(authProvider).user;
  return HabitNotifier(hive, firestore, authUser);
});

class HabitNotifier extends StateNotifier<List<HabitModel>> {
  final HiveService _hive;
  final FirestoreService _firestore;
  final AuthUserModel? _authUser;

  HabitNotifier(this._hive, this._firestore, this._authUser) : super([]) {
    _load();
  }

  bool get _isCloudUser =>
      _authUser != null && _authUser!.provider != AuthProvider.guest;
  String? get _uid => _authUser?.uid;

  void _load() {
    state = _hive.getAllHabits().where((h) => !h.isArchived).toList();
  }

  Future<void> addHabit({
    required String title,
    String? description,
    String iconName = 'check_circle',
    required int colorValue,
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> targetWeekdays = const [],
    String? reminderTime,
  }) async {
    final habit = HabitModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      iconName: iconName,
      colorValue: colorValue,
      frequency: frequency,
      targetWeekdays: targetWeekdays,
      createdAt: DateTime.now(),
      reminderTime: reminderTime,
    );
    await _hive.saveHabit(habit);
    state = [...state, habit];
    if (_isCloudUser && _uid != null) {
      _firestore.saveHabit(_uid!, habit).catchError((_) {});
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _hive.saveHabit(habit);
    state = state.map((h) => h.id == habit.id ? habit : h).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveHabit(_uid!, habit).catchError((_) {});
    }
  }

  Future<void> toggleCompletion(String id, {DateTime? date}) async {
    final habit = state.firstWhere((h) => h.id == id);
    final key = DateHelper.toStorageKey(date ?? DateHelper.today);
    final wasCompleted = habit.completionHistory[key] == true;

    final updatedHistory = Map<String, bool>.from(habit.completionHistory);
    if (wasCompleted) {
      updatedHistory.remove(key);
    } else {
      updatedHistory[key] = true;
    }

    final currentStreak =
        StreakCalculator.computeCurrentStreak(updatedHistory);
    final longestStreak = StreakCalculator.computeLongestStreak(updatedHistory);

    final updated = habit.copyWith(
      completionHistory: updatedHistory,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );

    await _hive.saveHabit(updated);
    state = state.map((h) => h.id == id ? updated : h).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveHabit(_uid!, updated).catchError((_) {});
    }
  }

  Future<void> archiveHabit(String id) async {
    final habit = state.firstWhere((h) => h.id == id);
    final archived = habit.copyWith(isArchived: true);
    await _hive.saveHabit(archived);
    state = state.where((h) => h.id != id).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveHabit(_uid!, archived).catchError((_) {});
    }
  }

  Future<void> deleteHabit(String id) async {
    await _hive.deleteHabit(id);
    state = state.where((h) => h.id != id).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.deleteHabit(_uid!, id).catchError((_) {});
    }
  }

  /// Pull from cloud and merge.
  Future<void> syncFromCloud() async {
    if (!_isCloudUser || _uid == null) return;
    final cloudHabits = await _firestore.getAllHabits(_uid!);
    final localHabits = _hive.getAllHabits();

    final merged = <String, HabitModel>{};
    for (final h in localHabits) {
      merged[h.id] = h;
    }
    for (final h in cloudHabits) {
      merged[h.id] = h;
    }

    for (final h in merged.values) {
      await _hive.saveHabit(h);
    }

    final cloudIds = cloudHabits.map((h) => h.id).toSet();
    for (final h in localHabits) {
      if (!cloudIds.contains(h.id)) {
        _firestore.saveHabit(_uid!, h).catchError((_) {});
      }
    }

    state = merged.values.where((h) => !h.isArchived).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  bool isCompletedToday(String id) {
    final habit = state.firstWhere((h) => h.id == id,
        orElse: () => throw StateError('Habit not found'));
    final key = DateHelper.toStorageKey(DateHelper.today);
    return habit.completionHistory[key] == true;
  }

  List<HabitModel> get todayHabits {
    final now = DateTime.now();
    return state.where((h) {
      if (h.frequency == HabitFrequency.daily) return true;
      if (h.targetWeekdays.isEmpty) return true;
      return h.targetWeekdays.contains(now.weekday);
    }).toList();
  }

  int get completedTodayCount {
    final key = DateHelper.toStorageKey(DateHelper.today);
    return todayHabits
        .where((h) => h.completionHistory[key] == true)
        .length;
  }

  int get appStreakDays {
    int streak = 0;
    DateTime cursor = DateHelper.today;
    while (streak < 365) {
      final key = DateHelper.toStorageKey(cursor);
      final dayHabits = state
          .where((h) => h.frequency == HabitFrequency.daily)
          .toList();
      if (dayHabits.isEmpty) break;
      final allDone =
          dayHabits.every((h) => h.completionHistory[key] == true);
      if (allDone) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

final todayHabitsProvider = Provider<List<HabitModel>>((ref) {
  return ref.watch(habitProvider.notifier).todayHabits;
});

final habitCompletedTodayProvider = Provider<int>((ref) {
  ref.watch(habitProvider);
  return ref.watch(habitProvider.notifier).completedTodayCount;
});
