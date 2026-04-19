import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';

class TimerRing extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final int remainingSeconds;
  final Color color;
  final double size;
  final String? label;
  final bool isRunning;

  const TimerRing({
    super.key,
    required this.progress,
    required this.remainingSeconds,
    required this.color,
    this.size = 240,
    this.label,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.background;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              color: trackColor,
            ),
          ),
          // Progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, value, __) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: trackColor,
                color: color,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateHelper.formatDurationFull(remainingSeconds),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: color,
                    ),
              ),
              if (label != null) ...[
                const SizedBox(height: 4),
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                ),
              ],
              if (isRunning) ...[
                const SizedBox(height: 8),
                _PulsingDot(color: color),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
