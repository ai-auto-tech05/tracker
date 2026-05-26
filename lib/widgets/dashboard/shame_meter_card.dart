import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/chaos_provider.dart';

class ShameMeterCard extends ConsumerWidget {
  const ShameMeterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(shameMeterProvider);
    final color = _colorForScore(score);
    final label = _labelForScore(score);
    final quip = _quipForScore(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: score > 60 ? 0.2 : 0.08),
            blurRadius: score > 60 ? 20 : 8,
            spreadRadius: score > 60 ? 2 : 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: score > 60 ? 0.35 : 0.12),
          width: score > 60 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Arc ring
          SizedBox(
            width: 80,
            height: 80,
            child: _AnimatedArc(score: score, color: color),
          ),
          const SizedBox(width: 20),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Shame Meter',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull),
                      ),
                      child: Text(
                        label,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$score / 100',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  quip,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  static Color _colorForScore(int s) {
    if (s < 30) return const Color(0xFF10B981); // green
    if (s < 60) return const Color(0xFFF59E0B); // amber
    if (s < 80) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444);             // red
  }

  static String _labelForScore(int s) {
    if (s < 20) return 'Clean';
    if (s < 40) return 'Mild';
    if (s < 60) return 'Yikes';
    if (s < 80) return 'Rough';
    return 'Disaster';
  }

  static String _quipForScore(int s) {
    if (s == 0) return "Nothing to be ashamed of. Suspicious.";
    if (s < 20) return "Look at you, being a functioning adult.";
    if (s < 40) return "Not great, not terrible.";
    if (s < 60) return "The bar is on the floor. You're under it.";
    if (s < 80) return "We're all rooting for you. Kind of.";
    return "This is a judgment-free zone. (It's not.)";
  }
}

// ─── Animated arc ring ────────────────────────────────────────────────────────

class _AnimatedArc extends StatefulWidget {
  final int score;
  final Color color;

  const _AnimatedArc({required this.score, required this.color});

  @override
  State<_AnimatedArc> createState() => _AnimatedArcState();
}

class _AnimatedArcState extends State<_AnimatedArc>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.score / 100.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedArc old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(begin: _anim.value, end: widget.score / 100.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _ArcPainter(
          progress: _anim.value,
          color: widget.color,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
        child: Center(
          child: Text(
            '${widget.score}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color color;
  final bool isDark;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  static const double _startAngle = 135 * math.pi / 180;
  static const double _sweepFull  = 270 * math.pi / 180;
  static const double _strokeW    = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeW) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepFull,
      false,
      Paint()
        ..color = isDark
            ? AppColors.darkSurfaceVariant
            : color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeW
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Fill
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepFull * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
