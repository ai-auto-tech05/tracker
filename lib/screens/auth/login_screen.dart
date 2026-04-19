import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ── Logo ───────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 20),

              Text(
                'Tracker',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                'Build focus. Track progress.\nStay consistent.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 56),

              // ── Error banner ───────────────────────────────────────────
              if (authState.error != null)
                _ErrorBanner(message: authState.error!, ref: ref),

              // ── Google button ──────────────────────────────────────────
              _SocialButton(
                onTap: authState.isLoading
                    ? null
                    : () => _googleSignIn(context, ref),
                isLoading:
                    authState.isLoading && authState.error == null,
                label: 'Continue with Google',
                icon: _GoogleIcon(),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 12),

              // ── Divider ────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 12),

              // ── Email button ───────────────────────────────────────────
              _SocialButton(
                onTap: authState.isLoading
                    ? null
                    : () => context.push(AppRoutes.signIn),
                label: 'Continue with Email',
                icon: const Icon(Icons.email_outlined,
                    size: 20, color: AppColors.textSecondary),
                outlined: true,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 12),

              // ── Guest button ──────────────────────────────────────────
              _SocialButton(
                onTap: authState.isLoading
                    ? null
                    : () => _guestSignIn(context, ref),
                label: 'Continue as Guest',
                icon: const Icon(Icons.person_outline_rounded,
                    size: 20, color: AppColors.textSecondary),
                outlined: true,
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 24),

              // ── Create account ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.signUp),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Create account'),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              // ── Guest note ─────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Guest data stays on this device only. Sign up anytime to sync.',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 16),

              // ── Terms note ─────────────────────────────────────────────
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Google sign-in — opens the real native Google account picker.
  Future<void> _googleSignIn(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(authProvider.notifier);
    final isNew = await notifier.signInWithGoogle();

    if (!context.mounted) return;
    if (ref.read(authProvider).error != null) return;

    if (isNew) {
      context.go(AppRoutes.onboarding);
    } else {
      final user = ref.read(userProvider);
      if (user == null || !user.onboardingCompleted) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  /// Guest sign-in — Firebase anonymous auth, no credentials needed.
  Future<void> _guestSignIn(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(authProvider.notifier).signInAsGuest();

    if (!context.mounted) return;
    if (ref.read(authProvider).error != null) return;

    if (success) {
      context.go(AppRoutes.onboarding);
    }
  }
}

// ─── Social Button ─────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool outlined;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              child: _content(context),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                side: BorderSide(
                  color: isDark ? AppColors.darkDivider : AppColors.border,
                ),
              ),
              child: _content(context),
            ),
    );
  }

  Widget _content(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ─── Google Icon ──────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

// ─── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final WidgetRef ref;

  const _ErrorBanner({required this.message, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(authProvider.notifier).clearError(),
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
