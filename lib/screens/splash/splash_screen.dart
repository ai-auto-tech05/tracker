import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/sync_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Let the splash show for a moment, then route based on auth state
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    final user = ref.read(userProvider);

    if (!authState.isAuthenticated) {
      context.go(AppRoutes.login);
    } else {
      // Trigger cloud sync in background (non-blocking)
      ref.read(syncProvider.notifier).syncAll();

      if (user == null || !user.onboardingCompleted) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: Colors.white,
                size: 48,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                )
                .fadeIn(),
            const SizedBox(height: 20),
            Text(
              'Tracker',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'Build focus. Track progress.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 60),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withOpacity(0.5),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
