import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/widget_update_service.dart';

/// Watches [taskProvider] and [habitProvider] and pushes updated data to the
/// native home-screen widget every time either changes.
///
/// Register in ProviderScope:
///   ProviderScope(observers: [WidgetSyncObserver()], child: ...)
class WidgetSyncObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == taskProvider || provider == habitProvider) {
      final tasks = container.read(taskProvider);
      final habits = container.read(habitProvider);
      // Fire-and-forget — widget update is non-blocking.
      Future.microtask(
        () => WidgetUpdateService.update(tasks: tasks, habits: habits),
      );
    }
  }
}
