import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;
  String? _localMessage;
  String? _localError;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final email = user?.email ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: _signOut,
              child: Text(
                'Sign Out',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
              vertical: 16,
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // ── Icon ────────────────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 28),
                // ── Title ───────────────────────────────────────────────────
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  'Please check your inbox and click the verification link before continuing.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 32),
                // ── Status messages ──────────────────────────────────────────
                if (_localError != null)
                  _StatusBanner(
                    message: _localError!,
                    isError: true,
                    onDismiss: () => setState(() => _localError = null),
                  ).animate().fadeIn(),
                if (_localMessage != null)
                  _StatusBanner(
                    message: _localMessage!,
                    isError: false,
                    onDismiss: () => setState(() => _localMessage = null),
                  ).animate().fadeIn(),
                const SizedBox(height: 8),
                // ── Primary action ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checking ? null : _checkVerification,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_rounded, size: 20),
                    label: Text(
                        _checking ? 'Checking...' : "I've verified, continue"),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                // ── Resend ───────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resending ? null : () => _resend(email),
                    icon: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                        _resending ? 'Sending...' : 'Resend verification email'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _localError = null;
      _localMessage = null;
    });

    final verified = await ref.read(authProvider.notifier).checkEmailVerified();

    if (!mounted) return;
    setState(() => _checking = false);

    if (verified) {
      // Proceed to onboarding or dashboard
      final authState = ref.read(authProvider);
      if (authState.isNewUser) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      setState(() {
        _localError = 'Email not verified yet. Please check your inbox and '
            'click the link, then try again.';
      });
    }
  }

  Future<void> _resend(String email) async {
    setState(() {
      _resending = true;
      _localError = null;
      _localMessage = null;
    });

    final ok =
        await ref.read(authProvider.notifier).resendVerificationEmail(email);

    if (!mounted) return;
    setState(() => _resending = false);

    final authState = ref.read(authProvider);
    if (ok) {
      setState(() => _localMessage =
          authState.message ?? 'Verification email sent.');
    } else {
      setState(() => _localError =
          authState.error ?? 'Failed to resend. Please try again.');
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) context.go(AppRoutes.login);
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _StatusBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    final bg = isError
        ? AppColors.error.withOpacity(0.1)
        : AppColors.success.withOpacity(0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

