import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/auth_user_model.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/signin_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/main_shell/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/habits/habits_screen.dart';
import '../screens/focus/focus_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notification_center_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String signIn = '/signin';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/';
  static const String tasks = '/tasks';
  static const String habits = '/habits';
  static const String focus = '/focus';
  static const String analytics = '/analytics';
  static const String settings       = '/settings';
  static const String notifications  = '/notifications';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isOnboarded = ref.watch(isOnboardedProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthenticated = authState.isAuthenticated;
      final authUnknown = authState.status == AuthStatus.unknown;
      final user = authState.user;

      // While auth is loading, stay on splash
      if (authUnknown) return AppRoutes.splash;

      final authRoutes = [
        AppRoutes.login,
        AppRoutes.signUp,
        AppRoutes.signIn,
        AppRoutes.forgotPassword,
        AppRoutes.splash,
      ];
      final isOnAuthRoute = authRoutes.contains(loc);
      final isOnVerifyRoute = loc == AppRoutes.verifyEmail;

      // Not logged in → push to login
      if (!isAuthenticated && !isOnAuthRoute && !isOnVerifyRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated) {
        final needsEmailVerification = user?.provider == AuthProvider.email &&
            !(user?.isEmailVerified ?? false);

        // Email user who hasn't verified → force to verify screen
        if (needsEmailVerification &&
            !isOnVerifyRoute &&
            !isOnAuthRoute &&
            loc != AppRoutes.splash) {
          return AppRoutes.verifyEmail;
        }

        // Verified + on auth route → into the app
        if (!needsEmailVerification && isOnAuthRoute && loc != AppRoutes.splash) {
          return isOnboarded ? AppRoutes.dashboard : AppRoutes.onboarding;
        }

        // Verified + on verify route → into the app
        if (!needsEmailVerification && isOnVerifyRoute) {
          return isOnboarded ? AppRoutes.dashboard : AppRoutes.onboarding;
        }

        // Onboarding incomplete → force onboarding (unless verifying or on auth)
        if (!isOnboarded &&
            !needsEmailVerification &&
            loc != AppRoutes.onboarding &&
            !isOnAuthRoute &&
            !isOnVerifyRoute) {
          return AppRoutes.onboarding;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const TasksScreen()),
          ),
          GoRoute(
            path: AppRoutes.habits,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const HabitsScreen()),
          ),
          GoRoute(
            path: AppRoutes.focus,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const FocusScreen()),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const AnalyticsScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const SettingsScreen()),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (_, state) =>
                _noTransitionPage(state, const NotificationCenterScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _noTransitionPage(
    GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, __, ___, Widget child) => child,
  );
}
