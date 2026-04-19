import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/primary_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).signUpWithEmail(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    // Email sign-up requires verification before onboarding
    if (success && mounted) context.go(AppRoutes.verifyEmail);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Welcome aboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  'Create your account to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 32),

                // Error banner
                if (authState.error != null)
                  _errorBanner(context, authState.error!),

                // Full name
                _label(context, 'Full Name'),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 14),

                // Email
                _label(context, 'Email'),
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
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 14),

                // Password
                _label(context, 'Password'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 20, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 14),

                // Confirm password
                _label(context, 'Confirm Password'),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 20, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Create Account',
                  isLoading: authState.isLoading,
                  onTap: _submit,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 20),

                // Sign in link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.pushReplacement(AppRoutes.signIn),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );

  Widget _errorBanner(BuildContext context, String message) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      )),
            ),
          ],
        ),
      );
}
