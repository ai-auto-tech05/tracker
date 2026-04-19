import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref
        .read(authProvider.notifier)
        .resetPassword(_emailCtrl.text.trim());
    if (error == null && mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: _sent ? _buildSuccess(context) : _buildForm(context, authState),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppColors.primary, size: 28),
          ).animate().scale(curve: Curves.elasticOut).fadeIn(),
          const SizedBox(height: 20),
          Text(
            'Forgot your password?',
            style: Theme.of(context).textTheme.headlineSmall,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            "Enter your email and we'll send you a reset link.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 32),

          if (authState.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                authState.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  size: 20, color: AppColors.textSecondary),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          PrimaryButton(
            label: 'Send Reset Link',
            isLoading: authState.isLoading,
            onTap: _submit,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.successSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: AppColors.success, size: 40),
        ).animate().scale(curve: Curves.elasticOut).fadeIn(),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'We sent a reset link to\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Sign In'),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
