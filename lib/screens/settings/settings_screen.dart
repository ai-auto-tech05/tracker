import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/auth_user_model.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/upgrade_sheet.dart';
import '../auth/edit_email_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final authUser = ref.watch(currentAuthUserProvider);
    final notifier = ref.read(userProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ── Account card ───────────────────────────────────────────
                _SectionLabel(label: 'Account'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar with optional premium badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: AppColors.primarySurface,
                                  shape: BoxShape.circle,
                                ),
                                child: authUser?.provider ==
                                        AuthProvider.google
                                    ? const Center(
                                        child: Text('G',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4285F4),
                                            )))
                                    : authUser?.provider ==
                                            AuthProvider.guest
                                        ? const Icon(
                                            Icons.person_outline_rounded,
                                            color: AppColors.textSecondary,
                                            size: 24)
                                        : const Icon(Icons.person_rounded,
                                            color: AppColors.primary,
                                            size: 24),
                              ),
                              if (isPremium)
                                Positioned(
                                  bottom: -2,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                  decoration: const InputDecoration(
                                    labelText: 'Display Name',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      notifier.updateName(val.trim());
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Name updated')),
                                      );
                                    }
                                  },
                                ),
                                if (authUser != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    authUser.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.textTertiary),
                        ],
                      ),
                      if (authUser != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _providerBadge(context, authUser.provider),
                            const Spacer(),
                            _verificationBadge(context, authUser),
                          ],
                        ),
                        // Pending email change indicator
                        if (authUser.pendingEmail != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_outlined,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Pending change to: ${authUser.pendingEmail}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: Colors.amber.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Edit Email option (email provider only)
                        if (authUser.provider == AuthProvider.email) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _openEditEmail(context),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Change email address',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 16,
                                      color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Focus ──────────────────────────────────────────────────
                _SectionLabel(label: 'Focus Timer'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _DurationTile(
                        label: 'Focus Duration',
                        value: user.defaultFocusDurationMinutes,
                        min: 5,
                        max: 120,
                        step: 5,
                        onChanged: (v) => notifier.updateSettings(
                            defaultFocusDurationMinutes: v),
                      ),
                      const Divider(height: 1),
                      _DurationTile(
                        label: 'Short Break',
                        value: user.defaultShortBreakMinutes,
                        min: 1,
                        max: 30,
                        step: 1,
                        onChanged: (v) => notifier.updateSettings(
                            defaultShortBreakMinutes: v),
                      ),
                      const Divider(height: 1),
                      _DurationTile(
                        label: 'Long Break',
                        value: user.defaultLongBreakMinutes,
                        min: 5,
                        max: 60,
                        step: 5,
                        onChanged: (v) => notifier.updateSettings(
                            defaultLongBreakMinutes: v),
                      ),
                      const Divider(height: 1),
                      _DurationTile(
                        label: 'Daily Focus Goal',
                        value: user.dailyFocusGoalMinutes,
                        min: 15,
                        max: 480,
                        step: 15,
                        suffix: 'min',
                        onChanged: (v) => notifier.updateSettings(
                            dailyFocusGoalMinutes: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Appearance ────────────────────────────────────────────
                _SectionLabel(label: 'Appearance'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: _ToggleTile(
                    label: 'Dark Mode',
                    icon: Icons.dark_mode_outlined,
                    value: user.darkMode,
                    onChanged: (v) =>
                        notifier.updateSettings(darkMode: v),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Notifications ─────────────────────────────────────────
                _SectionLabel(label: 'Notifications'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: _ToggleTile(
                    label: 'Enable Notifications',
                    icon: Icons.notifications_outlined,
                    value: user.notificationsEnabled,
                    onChanged: (v) =>
                        notifier.updateSettings(notificationsEnabled: v),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Data ──────────────────────────────────────────────────
                _SectionLabel(label: 'Data'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ActionTile(
                        label: 'Export Data',
                        icon: Icons.upload_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Export coming in a future update'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ActionTile(
                        label: 'Clear All Data',
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        onTap: () => _confirmClearData(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── About ─────────────────────────────────────────────────
                _SectionLabel(label: 'About'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoTile(label: 'Version', value: '1.0.0'),
                      const Divider(height: 1),
                      _ActionTile(
                        label: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _ActionTile(
                        label: 'Terms of Service',
                        icon: Icons.description_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Subscription ──────────────────────────────────────────
                if (isPremium)
                  _buildPremiumBadgeCard(context, ref)
                else
                  _buildUpgradeCard(context),
                const SizedBox(height: 16),

                // ── Sign Out ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context, ref),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    label: const Text('Sign Out',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity,
                          AppDimensions.buttonHeight),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditEmail(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditEmailScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email address updated successfully.')),
      );
    }
  }

  Widget _verificationBadge(BuildContext context, AuthUserModel user) {
    if (user.provider != AuthProvider.email) return const SizedBox.shrink();
    if (user.isEmailVerified) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.success),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => context.go(AppRoutes.verifyEmail),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 12, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Not verified — tap to verify',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerBadge(BuildContext context, AuthProvider provider) {
    final isGoogle = provider == AuthProvider.google;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGoogle
            ? const Color(0xFFEAF0FB)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGoogle ? Icons.g_mobiledata_rounded : Icons.email_outlined,
            size: 14,
            color: isGoogle
                ? const Color(0xFF4285F4)
                : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${provider.label} account',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isGoogle
                      ? const Color(0xFF4285F4)
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => UpgradeSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.accentLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Go Premium',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Unlimited tasks, analytics, cloud sync & more',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: const [
                _PremiumChip(label: 'Unlimited tasks'),
                _PremiumChip(label: 'AI suggestions'),
                _PremiumChip(label: 'Calendar view'),
                _PremiumChip(label: 'Cloud sync'),
                _PremiumChip(label: 'Analytics'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBadgeCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'You have access to all premium features.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out? Your data will remain on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete all tasks, habits, and focus sessions. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ─── Shared setting widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _DurationTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    this.suffix = 'min',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Row(
            children: [
              _CircleButton(
                icon: Icons.remove_rounded,
                onTap: value > min ? () => onChanged(value - step) : null,
              ),
              const SizedBox(width: 12),
              Text(
                '$value $suffix',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              _CircleButton(
                icon: Icons.add_rounded,
                onTap: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primarySurface
              : AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null
                ? AppColors.primary
                : AppColors.textTertiary),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, size: 20, color: tileColor),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: tileColor)),
      trailing: Icon(Icons.chevron_right_rounded,
          size: 18, color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  )),
        ],
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  final String label;
  const _PremiumChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
