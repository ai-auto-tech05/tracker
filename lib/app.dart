import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/user_provider.dart';
import 'widgets/overlay/heads_up_banner_overlay.dart';
import 'widgets/overlay/chaos_overlay.dart';

class TrackerApp extends ConsumerWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final user = ref.watch(userProvider);
    final isDark = user?.darkMode ?? false;

    return MaterialApp.router(
      title: 'Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => HeadsUpBannerLayer(
        child: ChaosOverlayLayer(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
