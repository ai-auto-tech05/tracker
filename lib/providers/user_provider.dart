import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/auth_user_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final userProvider =
    StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final hive = ref.read(hiveServiceProvider);
  final firestore = ref.read(firestoreServiceProvider);
  final authState = ref.watch(authProvider);
  return UserNotifier(hive, firestore, authState.user);
});

class UserNotifier extends StateNotifier<UserModel?> {
  final HiveService _hive;
  final FirestoreService _firestore;
  final AuthUserModel? _authUser;

  UserNotifier(this._hive, this._firestore, this._authUser) : super(null) {
    _load();
  }

  bool get _isCloudUser =>
      _authUser != null && _authUser!.provider != AuthProvider.guest;

  String? get _uid => _authUser?.uid;

  void _load() {
    state = _hive.getUser();
  }

  Future<void> createUser(
    String name, {
    String productivityProfile = '',
    String notificationStyle = 'sarcastic',
  }) async {
    final user = UserModel(
      id: _uid ?? const Uuid().v4(),
      name: name,
      onboardingCompleted: false,
      productivityProfile: productivityProfile,
      notificationStyle: notificationStyle,
      createdAt: DateTime.now(),
    );
    await _hive.saveUser(user);
    state = user;
    if (_isCloudUser && _uid != null) {
      _firestore.saveUserSettings(_uid!, user).catchError((_) {});
    }
  }

  Future<void> completeOnboarding() async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(onboardingCompleted: true);
    await _hive.saveUser(updated);
    state = updated;
    if (_isCloudUser && _uid != null) {
      _firestore.saveUserSettings(_uid!, updated).catchError((_) {});
    }
  }

  Future<void> updateUser(UserModel updated) async {
    await _hive.saveUser(updated);
    state = updated;
    if (_isCloudUser && _uid != null) {
      _firestore.saveUserSettings(_uid!, updated).catchError((_) {});
    }
  }

  Future<void> updateName(String name) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(name: name);
    await _hive.saveUser(updated);
    state = updated;
    if (_isCloudUser && _uid != null) {
      _firestore.saveUserSettings(_uid!, updated).catchError((_) {});
    }
  }

  Future<void> updateSettings({
    bool? darkMode,
    bool? notificationsEnabled,
    int? dailyFocusGoalMinutes,
    int? defaultFocusDurationMinutes,
    int? defaultShortBreakMinutes,
    int? defaultLongBreakMinutes,
  }) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(
      darkMode: darkMode,
      notificationsEnabled: notificationsEnabled,
      dailyFocusGoalMinutes: dailyFocusGoalMinutes,
      defaultFocusDurationMinutes: defaultFocusDurationMinutes,
      defaultShortBreakMinutes: defaultShortBreakMinutes,
      defaultLongBreakMinutes: defaultLongBreakMinutes,
    );
    await _hive.saveUser(updated);
    state = updated;
    if (_isCloudUser && _uid != null) {
      _firestore.saveUserSettings(_uid!, updated).catchError((_) {});
    }
  }

  /// Pull settings from cloud and merge (cloud wins if exists).
  Future<void> syncFromCloud() async {
    if (!_isCloudUser || _uid == null) return;
    final cloudUser = await _firestore.getUserSettings(_uid!);
    if (cloudUser != null) {
      await _hive.saveUser(cloudUser);
      state = cloudUser;
    } else if (state != null) {
      await _firestore.saveUserSettings(_uid!, state!);
    }
  }
}

/// Convenience provider — true once onboarding is done.
final isOnboardedProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.onboardingCompleted ?? false;
});
