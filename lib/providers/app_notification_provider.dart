import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification_model.dart';
import '../services/hive_service.dart';
import 'user_provider.dart';

final appNotifProvider =
    StateNotifierProvider<AppNotifNotifier, List<AppNotificationModel>>((ref) {
  final hive = ref.read(hiveServiceProvider);
  return AppNotifNotifier(hive);
});

class AppNotifNotifier
    extends StateNotifier<List<AppNotificationModel>> {
  final HiveService _hive;

  AppNotifNotifier(this._hive) : super([]) {
    _load();
  }

  void _load() {
    state = _hive.getAllNotifications();
  }

  Future<void> add({
    required AppNotifType type,
    required String title,
    required String body,
  }) async {
    final n = AppNotificationModel(
      id: const Uuid().v4(),
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    await _hive.saveNotification(n);
    state = [n, ...state];
  }

  Future<void> markRead(String id) async {
    final idx = state.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final updated = state[idx].markRead();
    await _hive.saveNotification(updated);
    final list = [...state];
    list[idx] = updated;
    state = list;
  }

  Future<void> markAllRead() async {
    final updated = state.map((n) => n.markRead()).toList();
    for (final n in updated) {
      await _hive.saveNotification(n);
    }
    state = updated;
  }

  Future<void> remove(String id) async {
    await _hive.deleteNotification(id);
    state = state.where((n) => n.id != id).toList();
  }

  Future<void> clearAll() async {
    await _hive.clearAllNotifications();
    state = [];
  }
}

/// Live unread count — watches state, not notifier.
final unreadNotifCountProvider = Provider<int>((ref) {
  return ref.watch(appNotifProvider).where((n) => !n.isRead).length;
});
