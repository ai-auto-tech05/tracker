import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/app_notification_model.dart';
import '../../providers/app_notification_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(appNotifProvider);
    final notifier = ref.read(appNotifProvider.notifier);
    final hasUnread = notifs.any((n) => !n.isRead);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Notifications'),
            actions: [
              if (hasUnread)
                TextButton(
                  onPressed: notifier.markAllRead,
                  child: Text(
                    'Mark all read',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
              if (notifs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => _confirmClear(context, notifier),
                  tooltip: 'Clear all',
                ),
            ],
          ),
          if (notifs.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 56, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing here yet.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Complete something and we'll have something to say.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _NotifTile(
                    notif: notifs[i],
                    onTap: () => notifier.markRead(notifs[i].id),
                    onDismiss: () => notifier.remove(notifs[i].id),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.06, end: 0),
                  childCount: notifs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(
      BuildContext context, AppNotifNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) notifier.clearAll();
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = notif.type.accentColor;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: notif.isRead
                ? (isDark ? AppColors.darkSurface : AppColors.surface)
                : (isDark
                    ? AppColors.darkSurface
                    : accent.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: notif.isRead ? AppColors.border : accent.withValues(alpha: 0.2),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Type-coloured left border
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusMd),
                      bottomLeft: Radius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(notif.type.icon,
                              size: 16, color: accent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: notif.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notif.body,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(notif.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return DateHelper.formatDateShort(dt);
  }
}
