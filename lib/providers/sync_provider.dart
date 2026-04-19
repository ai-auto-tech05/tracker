import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'task_provider.dart';
import 'habit_provider.dart';
import 'focus_provider.dart';

/// Manages cloud sync lifecycle:
///   1. On sign-in → save user profile to Firestore
///   2. Trigger data sync (pull cloud, merge local, push local-only)
///   3. Called once from SplashScreen / after auth state change

enum SyncStatus { idle, syncing, done, error }

class SyncState {
  final SyncStatus status;
  final String? error;
  const SyncState({this.status = SyncStatus.idle, this.error});
}

final syncProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;

  SyncNotifier(this._ref) : super(const SyncState());

  /// Call this after user signs in (email/google — not guest).
  /// Saves profile to Firestore and syncs all data.
  Future<void> syncAll() async {
    final authUser = _ref.read(authProvider).user;
    if (authUser == null || authUser.provider == AuthProvider.guest) return;

    state = const SyncState(status: SyncStatus.syncing);

    try {
      final firestore = _ref.read(firestoreServiceProvider);

      // 1. Save/update user profile in Firestore (email, name, provider, etc.)
      await firestore.saveUserProfile(authUser);

      // 2. Sync each data type (pull cloud → merge → push local-only)
      await Future.wait([
        _ref.read(userProvider.notifier).syncFromCloud(),
        _ref.read(taskProvider.notifier).syncFromCloud(),
        _ref.read(habitProvider.notifier).syncFromCloud(),
        _ref.read(focusProvider.notifier).syncFromCloud(),
      ]);

      state = const SyncState(status: SyncStatus.done);
    } catch (e) {
      state = SyncState(
          status: SyncStatus.error, error: e.toString());
    }
  }

  /// Upload all local data to cloud (used when guest upgrades to account).
  Future<void> uploadLocalToCloud() async {
    final authUser = _ref.read(authProvider).user;
    if (authUser == null || authUser.provider == AuthProvider.guest) return;

    state = const SyncState(status: SyncStatus.syncing);

    try {
      final firestore = _ref.read(firestoreServiceProvider);
      final hive = _ref.read(hiveServiceProvider);

      await firestore.saveUserProfile(authUser);
      await firestore.uploadAllData(
        uid: authUser.uid,
        userSettings: hive.getUser(),
        tasks: hive.getAllTasks(),
        habits: hive.getAllHabits(),
        focusSessions: hive.getAllFocusSessions(),
      );

      state = const SyncState(status: SyncStatus.done);
    } catch (e) {
      state = SyncState(
          status: SyncStatus.error, error: e.toString());
    }
  }
}
