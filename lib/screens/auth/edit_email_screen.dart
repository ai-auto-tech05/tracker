import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_user_model.dart';

/// Two-step email change screen:
///   Step 1 — re-authenticate (email users only)
///   Step 2 — enter new email + confirm
///   Step 3 — pending state (shows resend + confirm buttons)
class EditEmailScreen extends ConsumerStatefulWidget {
  const EditEmailScreen({super.key});

  @override
  ConsumerState<EditEmailScreen> createState() => _EditEmailScreenState();
}

enum _EditEmailStep { reauth, newEmail, pending }

class _EditEmailScreenState extends ConsumerState<EditEmailScreen> {
  _EditEmailStep _step = _EditEmailStep.reauth;

  // Controllers
  final _passwordCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();

  // UI state
  bool _obscurePassword = true;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    // Google users skip re-auth
    if (user?.provider != AuthProvider.email) {
      _step = _EditEmailStep.newEmail;
    }
    // If already in pending state (navigated back), show pending UI
    if (user?.pendingEmail != null) {
      _step = _EditEmailStep.pending;
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _newEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Change Email'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
            vertical: 24,
          ),
          child: AnimatedSwitcher(
            duration: 300.ms,
            child: _buildStep(context, user, authState),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, AuthUserModel? user, AuthState authState) {
    switch (_step) {
      case _EditEmailStep.reauth:
        return _buildReauthStep(context, authState);
      case _EditEmailStep.newEmail:
        return _buildNewEmailStep(context, user, authState);
      case _EditEmailStep.pending:
        return _buildPendingStep(context, user, authState);
    }
  }

  // ─── Step 1: Re-authenticate ───────────────────────────────────────────────

  Widget _buildReauthStep(BuildContext context, AuthState authState) {
    return Column(
      key: const ValueKey('reauth'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 1, total: 2),
        const SizedBox(height: 24),
        Text(
          'Confirm your identity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'For security, enter your current password before changing your email.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        if (_error != null) _ErrorBanner(message: _error!),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitReauth(authState),
          decoration: InputDecoration(
            labelText: 'Current Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: authState.isLoading ? null : () => _submitReauth(authState),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Continue'),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Future<void> _submitReauth(AuthState authState) async {
    final password = _passwordCtrl.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() => _error = null);

    final ok = await ref
        .read(authProvider.notifier)
        .reauthenticate(password: password);

    if (!mounted) return;
    if (ok) {
      setState(() => _step = _EditEmailStep.newEmail);
    } else {
      setState(
          () => _error = ref.read(authProvider).error ?? 'Authentication failed.');
    }
  }

  // ─── Step 2: Enter new email ───────────────────────────────────────────────

  Widget _buildNewEmailStep(
      BuildContext context, AuthUserModel? user, AuthState authState) {
    return Column(
      key: const ValueKey('newEmail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user?.provider == AuthProvider.email) ...[
          _StepIndicator(current: 2, total: 2),
          const SizedBox(height: 24),
        ],
        Text(
          'Enter new email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            children: [
              const TextSpan(text: 'Current email: '),
              TextSpan(
                text: user?.email ?? '',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (_error != null) _ErrorBanner(message: _error!),
        TextFormField(
          controller: _newEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitNewEmail(),
          decoration: const InputDecoration(
            labelText: 'New Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A verification link will be sent to this address.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: authState.isLoading ? null : _submitNewEmail,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send Verification'),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Future<void> _submitNewEmail() async {
    final newEmail = _newEmailCtrl.text.trim();
    if (newEmail.isEmpty) {
      setState(() => _error = 'Please enter an email address.');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(newEmail)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() => _error = null);

    final ok = await ref
        .read(authProvider.notifier)
        .initiateEmailChange(newEmail: newEmail);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _step = _EditEmailStep.pending;
        _successMessage =
            ref.read(authProvider).message ?? 'Verification sent.';
      });
    } else {
      setState(
          () => _error = ref.read(authProvider).error ?? 'Failed to send verification.');
    }
  }

  // ─── Step 3: Pending verification ─────────────────────────────────────────

  Widget _buildPendingStep(
      BuildContext context, AuthUserModel? user, AuthState authState) {
    final pendingEmail = user?.pendingEmail ?? _newEmailCtrl.text.trim();

    return Column(
      key: const ValueKey('pending'),
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_unread_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your new inbox',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'A verification link was sent to',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Text(
            pendingEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Click the link in that email, then tap "Confirm change" below.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_error != null) _ErrorBanner(message: _error!),
        if (_successMessage != null) _SuccessBanner(message: _successMessage!),
        const SizedBox(height: 8),
        // Confirm change button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: authState.isLoading ? null : _confirmChange,
            icon: authState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: const Text('Confirm change'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Resend button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: authState.isLoading ? null : _resendChange,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Resend verification'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Cancel button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: authState.isLoading ? null : _cancelChange,
            child: const Text('Cancel email change'),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Future<void> _confirmChange() async {
    setState(() {
      _error = null;
      _successMessage = null;
    });
    final ok = await ref.read(authProvider.notifier).confirmEmailChange();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true); // pop with success signal
    } else {
      setState(() =>
          _error = ref.read(authProvider).error ?? 'Could not confirm change.');
    }
  }

  Future<void> _resendChange() async {
    setState(() {
      _error = null;
      _successMessage = null;
    });
    final ok =
        await ref.read(authProvider.notifier).resendEmailChangeVerification();
    if (!mounted) return;
    if (ok) {
      setState(() =>
          _successMessage = ref.read(authProvider).message ?? 'Email resent.');
    } else {
      setState(() =>
          _error = ref.read(authProvider).error ?? 'Could not resend.');
    }
  }

  void _cancelChange() {
    Navigator.of(context).pop(false);
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
