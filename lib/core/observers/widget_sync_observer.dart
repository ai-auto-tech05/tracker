import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/widget_update_service.dart';

/// Watches [taskProvider] and [habitProvider] and pushes updated data to
/// the native home-screen widgets whenever either provider changes or is
/// first initialized.
///
/// Register once in ProviderScope:
///   ProviderScope(observers: [WidgetSyncObserver()], child: ...)
class WidgetSyncObserver extends ProviderObserver {

  void _push(ProviderContainer container) {
    Future.microtask(() {
      final tasks  = container.read(taskProvider);
      final habits = container.read(habitProvider);
      WidgetUpdateService.update(tasks: tasks, habits: habits);
    });
  }

  /// Called when a provider is first created — populates the widget on app
  /// launch even if nothing has changed since the last session.
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (provider == taskProvider || provider == habitProvider) {
      _push(container);
    }
  }

  /// Called every time a provider's state changes — keeps widget in sync
  /// with every task toggle, add, delete, habit completion, etc.
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == taskProvider || provider == habitProvider) {
      _push(container);
    }
  }
}
