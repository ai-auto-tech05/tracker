import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_user_model.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/focus_session_model.dart';
import '../models/user_model.dart';

/// Cloud Firestore service — syncs user data to the cloud.
///
/// Firestore structure:
/// ```
/// users/{uid}
///   ├── email, displayName, provider, createdAt, lastLogin, ...
///   ├── profile/settings  → UserModel (focus prefs, dark mode, etc.)
///   ├── tasks/{taskId}    → TaskModel
///   ├── habits/{habitId}  → HabitModel
///   └── focus_sessions/{sessionId} → FocusSessionModel
/// ```
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Enable offline persistence (enabled by default on mobile, but be explicit)
  Future<void> init() async {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ─── User Profile (top-level doc: users/{uid}) ────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Save/update user profile in Firestore. Called on every sign-in.
  Future<void> saveUserProfile(AuthUserModel user) async {
    await _userDoc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'provider': user.provider.value,
      'isEmailVerified': user.isEmailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update just the lastLogin timestamp.
  Future<void> updateLastLogin(String uid) async {
    await _userDoc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    }).catchError((_) {}); // ignore if doc doesn't exist yet
  }

  // ─── User Settings (sub-doc: users/{uid}/profile/settings) ─────────────────

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _userDoc(uid).collection('profile').doc('settings');

  Future<void> saveUserSettings(String uid, UserModel user) async {
    await _settingsDoc(uid).set(user.toJson(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserSettings(String uid) async {
    final snap = await _settingsDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    try {
      return UserModel.fromJson(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _tasksCol(String uid) =>
      _userDoc(uid).collection('tasks');

  Future<void> saveTask(String uid, TaskModel task) async {
    await _tasksCol(uid).doc(task.id).set(task.toJson());
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksCol(uid).doc(taskId).delete();
  }

  Future<List<TaskModel>> getAllTasks(String uid) async {
    final snap = await _tasksCol(uid).get();
    return snap.docs
        .map((doc) {
          try {
            return TaskModel.fromJson(doc.data());
          } catch (_) {
            return null;
          }
        })
        .whereType<TaskModel>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Real-time stream of tasks.
  Stream<List<TaskModel>> watchTasks(String uid) {
    return _tasksCol(uid).snapshots().map((snap) => snap.docs
        .map((doc) {
          try {
            return TaskModel.fromJson(doc.data());
          } catch (_) {
            return null;
          }
        })
        .whereType<TaskModel>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // ─── Habits ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _habitsCol(String uid) =>
      _userDoc(uid).collection('habits');

  Future<void> saveHabit(String uid, HabitModel habit) async {
    await _habitsCol(uid).doc(habit.id).set(habit.toJson());
  }

  Future<void> deleteHabit(String uid, String habitId) async {
    await _habitsCol(uid).doc(habitId).delete();
  }

  Future<List<HabitModel>> getAllHabits(String uid) async {
    final snap = await _habitsCol(uid).get();
    return snap.docs
        .map((doc) {
          try {
            return HabitModel.fromJson(doc.data());
          } catch (_) {
            return null;
          }
        })
        .whereType<HabitModel>()
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // ─── Focus Sessions ──────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _focusCol(String uid) =>
      _userDoc(uid).collection('focus_sessions');

  Future<void> saveFocusSession(
      String uid, FocusSessionModel session) async {
    await _focusCol(uid).doc(session.id).set(session.toJson());
  }

  Future<void> deleteFocusSession(String uid, String sessionId) async {
    await _focusCol(uid).doc(sessionId).delete();
  }

  Future<List<FocusSessionModel>> getAllFocusSessions(String uid) async {
    final snap = await _focusCol(uid).get();
    return snap.docs
        .map((doc) {
          try {
            return FocusSessionModel.fromJson(doc.data());
          } catch (_) {
            return null;
          }
        })
        .whereType<FocusSessionModel>()
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // ─── Bulk upload (local → cloud migration) ─────────────────────────────

  /// Upload all local data to cloud. Used when guest upgrades to account,
  /// or first time syncing an existing local user.
  Future<void> uploadAllData({
    required String uid,
    required UserModel? userSettings,
    required List<TaskModel> tasks,
    required List<HabitModel> habits,
    required List<FocusSessionModel> focusSessions,
  }) async {
    final batch = _db.batch();

    // Settings
    if (userSettings != null) {
      batch.set(_settingsDoc(uid), userSettings.toJson(),
          SetOptions(merge: true));
    }

    // Tasks
    for (final task in tasks) {
      batch.set(_tasksCol(uid).doc(task.id), task.toJson());
    }

    // Habits
    for (final habit in habits) {
      batch.set(_habitsCol(uid).doc(habit.id), habit.toJson());
    }

    // Focus sessions (Firestore batch limit = 500, split if needed)
    for (final session in focusSessions.take(400)) {
      batch.set(_focusCol(uid).doc(session.id), session.toJson());
    }

    await batch.commit();

    // Handle overflow focus sessions (if > 400)
    if (focusSessions.length > 400) {
      final batch2 = _db.batch();
      for (final session in focusSessions.skip(400)) {
        batch2.set(_focusCol(uid).doc(session.id), session.toJson());
      }
      await batch2.commit();
    }
  }

  // ─── Download all (cloud → local restore) ────────────────────────────────

  /// Pull all cloud data. Returns null values if nothing exists yet.
  Future<({
    UserModel? settings,
    List<TaskModel> tasks,
    List<HabitModel> habits,
    List<FocusSessionModel> focusSessions,
  })> downloadAllData(String uid) async {
    final results = await Future.wait([
      getUserSettings(uid),
      getAllTasks(uid),
      getAllHabits(uid),
      getAllFocusSessions(uid),
    ]);

    return (
      settings: results[0] as UserModel?,
      tasks: results[1] as List<TaskModel>,
      habits: results[2] as List<HabitModel>,
      focusSessions: results[3] as List<FocusSessionModel>,
    );
  }
}
