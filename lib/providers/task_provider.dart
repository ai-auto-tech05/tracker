import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/auth_user_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../core/utils/date_helper.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

final taskProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  final hive = ref.read(hiveServiceProvider);
  final firestore = ref.read(firestoreServiceProvider);
  final authUser = ref.watch(authProvider).user;
  return TaskNotifier(hive, firestore, authUser);
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final HiveService _hive;
  final FirestoreService _firestore;
  final AuthUserModel? _authUser;

  TaskNotifier(this._hive, this._firestore, this._authUser) : super([]) {
    _load();
  }

  bool get _isCloudUser =>
      _authUser != null && _authUser!.provider != AuthProvider.guest;
  String? get _uid => _authUser?.uid;

  void _load() {
    state = _hive.getAllTasks();
    _refreshOverdueStatuses();
  }

  void _refreshOverdueStatuses() {
    final updated = state.map((task) {
      if (!task.isCompleted &&
          task.dueDate != null &&
          DateHelper.isOverdue(task.dueDate!)) {
        return task.copyWith(status: TaskStatus.overdue);
      }
      return task;
    }).toList();
    state = updated;
  }

  Future<void> addTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.todo,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      tags: tags,
    );
    await _hive.saveTask(task);
    state = [...state, task];
    if (_isCloudUser && _uid != null) {
      _firestore.saveTask(_uid!, task).catchError((_) {});
    }
  }

  Future<void> updateTask(TaskModel task) async {
    await _hive.saveTask(task);
    state = state.map((t) => t.id == task.id ? task : t).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveTask(_uid!, task).catchError((_) {});
    }
  }

  Future<void> toggleComplete(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    TaskModel updated;
    if (task.isCompleted) {
      updated = task.copyWith(
        status: task.isOverdue ? TaskStatus.overdue : TaskStatus.todo,
        completedAt: null,
      );
    } else {
      updated = task.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
      );
    }
    await _hive.saveTask(updated);
    state = state.map((t) => t.id == id ? updated : t).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveTask(_uid!, updated).catchError((_) {});
    }
  }

  Future<void> deleteTask(String id) async {
    await _hive.deleteTask(id);
    state = state.where((t) => t.id != id).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.deleteTask(_uid!, id).catchError((_) {});
    }
  }

  Future<void> buryTask(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    final updated = task.copyWith(isBuried: true, buriedAt: DateTime.now());
    await _hive.saveTask(updated);
    state = state.map((t) => t.id == id ? updated : t).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveTask(_uid!, updated).catchError((_) {});
    }
  }

  Future<void> reviveTask(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    final updated = task.copyWith(
      isBuried: false,
      clearBuriedAt: true,
      status: TaskStatus.todo,
    );
    await _hive.saveTask(updated);
    state = state.map((t) => t.id == id ? updated : t).toList();
    if (_isCloudUser && _uid != null) {
      _firestore.saveTask(_uid!, updated).catchError((_) {});
    }
  }

  /// Pull from cloud, merge with local, push local-only to cloud.
  Future<void> syncFromCloud() async {
    if (!_isCloudUser || _uid == null) return;
    final cloudTasks = await _firestore.getAllTasks(_uid!);
    final localTasks = _hive.getAllTasks();

    final merged = <String, TaskModel>{};
    for (final t in localTasks) {
      merged[t.id] = t;
    }
    for (final t in cloudTasks) {
      merged[t.id] = t;
    }

    for (final t in merged.values) {
      await _hive.saveTask(t);
    }

    final cloudIds = cloudTasks.map((t) => t.id).toSet();
    for (final t in localTasks) {
      if (!cloudIds.contains(t.id)) {
        _firestore.saveTask(_uid!, t).catchError((_) {});
      }
    }

    state = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _refreshOverdueStatuses();
  }

  List<TaskModel> get todayTasks => state.where((t) {
        if (t.isCompleted) return false;
        if (t.isBuried) return false;
        return t.isDueToday || t.isOverdue || t.dueDate == null;
      }).toList();

  List<TaskModel> get overdueTasks =>
      state.where((t) => t.isOverdue).toList();

  List<TaskModel> get completedTasks =>
      state.where((t) => t.isCompleted).toList();

  List<TaskModel> get upcomingTasks => state.where((t) {
        if (t.isCompleted || t.isOverdue) return false;
        if (t.dueDate == null) return false;
        return t.dueDate!.isAfter(DateHelper.today);
      }).toList();

  int get completedTodayCount {
    final today = DateHelper.today;
    return state.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return DateHelper.isSameDay(t.completedAt!, today);
    }).length;
  }
}

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(taskProvider.notifier).todayTasks;
});

final overdueTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(taskProvider.notifier).overdueTasks;
});

final buriedTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(taskProvider).where((t) => t.isBuried).toList();
});
