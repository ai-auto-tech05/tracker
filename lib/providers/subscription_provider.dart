import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_provider.dart';
import 'user_provider.dart';

const int kFreemiumTaskLimit = 3;

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(userProvider)?.isPremium ?? false;
});

final activeTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => !t.isCompleted).length;
});

final canCreateTaskProvider = Provider<bool>((ref) {
  if (ref.watch(isPremiumProvider)) return true;
  return ref.watch(activeTaskCountProvider) < kFreemiumTaskLimit;
});
