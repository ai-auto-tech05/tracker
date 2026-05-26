import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

// ─── Urgency ──────────────────────────────────────────────────────────────────

enum HeadsUpUrgency { info, warning, critical }

// ─── Message model ────────────────────────────────────────────────────────────

class HeadsUpMessage {
  final String id;
  final String title;
  final String body;
  final HeadsUpUrgency urgency;

  HeadsUpMessage({
    required this.title,
    required this.body,
    this.urgency = HeadsUpUrgency.info,
  }) : id = '${DateTime.now().microsecondsSinceEpoch}';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final headsUpProvider =
    StateNotifierProvider<HeadsUpNotifier, List<HeadsUpMessage>>((ref) {
  return HeadsUpNotifier();
});

class HeadsUpNotifier extends StateNotifier<List<HeadsUpMessage>> {
  HeadsUpNotifier() : super([]);

  void show({
    required String title,
    required String body,
    HeadsUpUrgency urgency = HeadsUpUrgency.info,
  }) {
    final msg = HeadsUpMessage(title: title, body: body, urgency: urgency);
    // Max 3 queued at once
    state = [msg, ...state.take(2)];
  }

  void dismiss(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

// ─── Layer widget (added in app.dart builder) ─────────────────────────────────

class HeadsUpBannerLayer extends ConsumerWidget {
  final Widget child;

  const HeadsUpBannerLayer({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(headsUpProvider);
    final current = messages.isNotEmpty ? messages.first : null;

    return Stack(
      children: [
        child,
        if (current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                  vertical: 8,
                ),
                child: _HeadsUpBanner(
                  key: ValueKey(current.id),
                  message: current,
                  onDismiss: () =>
                      ref.read(headsUpProvider.notifier).dismiss(current.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Single banner card ───────────────────────────────────────────────────────

class _HeadsUpBanner extends StatefulWidget {
  final HeadsUpMessage message;
  final VoidCallback onDismiss;

  const _HeadsUpBanner({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  @override
  State<_HeadsUpBanner> createState() => _HeadsUpBannerState();
}

class _HeadsUpBannerState extends State<_HeadsUpBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
    _autoTimer = Timer(const Duration(milliseconds: 4500), _dismiss);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() async {
    _autoTimer?.cancel();
    await _ctrl.reverse();
    widget.onDismiss();
  }

  Color get _accentColor => switch (widget.message.urgency) {
        HeadsUpUrgency.critical => AppColors.error,
        HeadsUpUrgency.warning  => AppColors.warning,
        HeadsUpUrgency.info     => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCritical = widget.message.urgency == HeadsUpUrgency.critical;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(
                      alpha: isCritical ? 0.35 : 0.15),
                  blurRadius: isCritical ? 24 : 12,
                  spreadRadius: isCritical ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Urgency stripe
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusLg),
                        bottomLeft: Radius.circular(AppDimensions.radiusLg),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.title,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message.body,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dismiss X
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
