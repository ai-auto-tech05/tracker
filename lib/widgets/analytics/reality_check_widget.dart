import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

// ─── Period toggle ─────────────────────────────────────────────────────────────

enum _Period { week, month }

// ─── Root widget ──────────────────────────────────────────────────────────────

class RealityCheckWidget extends ConsumerStatefulWidget {
  const RealityCheckWidget({super.key});

  @override
  ConsumerState<RealityCheckWidget> createState() =>
      _RealityCheckWidgetState();
}

class _RealityCheckWidgetState extends ConsumerState<RealityCheckWidget> {
  _Period _period = _Period.week;

  // ── Data helpers ─────────────────────────────────────────────────────────

  _RCData _compute(List<TaskModel> tasks) {
    final now = DateTime.now();
    final days = _period == _Period.week ? 7 : 30;
    final cutoff = now.subtract(Duration(days: days));

    final buriedCount = tasks.where((t) {
      if (!t.isBuried || t.buriedAt == null) return false;
      return t.buriedAt!.isAfter(cutoff);
    }).length;

    final overdueCount = tasks.where((t) => t.isOverdue && !t.isBuried).length;

    final wastedMin = (buriedCount + overdueCount) * 30;
    final wastedHrs = wastedMin / 60.0;

    final yearlyHours = wastedHrs / days * 365;
    final yearlyDays = (yearlyHours / 8).round();

    final bars = _barData(tasks, now);
    final trending = _isTrendingUp(bars);

    return _RCData(
      buriedCount: buriedCount,
      overdueCount: overdueCount,
      wastedHrs: wastedHrs,
      yearlyDays: yearlyDays,
      bars: bars,
      isTrendingUp: trending,
    );
  }

  List<_BarValue> _barData(List<TaskModel> tasks, DateTime now) {
    if (_period == _Period.week) {
      // 7 daily bars
      return List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final key = DateHelper.toStorageKey(day);
        final count = tasks.where((t) {
          if (!t.isBuried || t.buriedAt == null) return false;
          return DateHelper.toStorageKey(t.buriedAt!) == key;
        }).length;
        return _BarValue(
          value: count * 0.5,
          label: _dayLabel(day.weekday),
        );
      });
    } else {
      // 4 weekly bars
      return List.generate(4, (i) {
        final weekEnd = now.subtract(Duration(days: (3 - i) * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 7));
        final count = tasks.where((t) {
          if (!t.isBuried || t.buriedAt == null) return false;
          return t.buriedAt!.isAfter(weekStart) &&
              t.buriedAt!.isBefore(weekEnd);
        }).length;
        return _BarValue(
          value: count * 0.5,
          label: 'Wk ${i + 1}',
        );
      });
    }
  }

  static bool _isTrendingUp(List<_BarValue> bars) {
    if (bars.length < 3) return false;
    final last = bars.last.value;
    final prev = bars.sublist(0, bars.length - 1);
    final avg = prev.fold(0.0, (s, b) => s + b.value) / prev.length;
    return last > avg && last > 0;
  }

  static String _dayLabel(int weekday) {
    const labels = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final data = _compute(tasks);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12132A),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + toggle ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics that don't lie\nto you to be nice.",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ).animate().fadeIn(delay: 50.ms),
                const SizedBox(height: 16),
                _PeriodToggle(
                  period: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── 4 KPI cards ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.55,
              children: [
                _RCKpiCard(
                  icon: Icons.sentiment_very_dissatisfied_rounded,
                  value: '${data.buriedCount}',
                  label: 'Buried tasks',
                  sub: _period == _Period.week
                      ? 'this week'
                      : 'this month alone',
                  delay: 100,
                ),
                _RCKpiCard(
                  icon: Icons.warning_amber_rounded,
                  value: '${data.overdueCount}',
                  label: 'Overdue',
                  sub: 'and aging',
                  delay: 150,
                ),
                _RCKpiCard(
                  icon: Icons.access_time_rounded,
                  value: _fmtHours(data.wastedHrs),
                  label: 'Hours wasted',
                  sub: _period == _Period.week
                      ? 'this week'
                      : 'this month',
                  delay: 200,
                ),
                _RCKpiCard(
                  icon: Icons.remove_red_eye_outlined,
                  value: '${data.yearlyDays} days',
                  label: 'Yearly projection',
                  sub: 'lost to scrolling',
                  delay: 250,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Bar chart ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _period == _Period.week
                      ? 'Hours wasted / day'
                      : 'Hours wasted / week',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (data.isTrendingUp)
                  const Text(
                    '↗ trending up. sadly.',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (data.bars.every((b) => b.value == 0))
                  const Text(
                    '✓ nothing wasted.',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  const Text(
                    '↘ slightly less bad.',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _BarChart(bars: data.bars),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08, end: 0);
  }

  static String _fmtHours(double h) {
    if (h == 0) return '0h';
    if (h < 1) return '${(h * 60).round()}m';
    if (h == h.roundToDouble()) return '${h.round()}h';
    return '${h.toStringAsFixed(1)}h';
  }
}

// ─── Data container ───────────────────────────────────────────────────────────

class _RCData {
  final int buriedCount;
  final int overdueCount;
  final double wastedHrs;
  final int yearlyDays;
  final List<_BarValue> bars;
  final bool isTrendingUp;

  const _RCData({
    required this.buriedCount,
    required this.overdueCount,
    required this.wastedHrs,
    required this.yearlyDays,
    required this.bars,
    required this.isTrendingUp,
  });
}

class _BarValue {
  final double value;
  final String label;
  const _BarValue({required this.value, required this.label});
}

// ─── Period toggle ────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;

  const _PeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2040),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: '7 days',
            active: period == _Period.week,
            onTap: () => onChanged(_Period.week),
          ),
          _Pill(
            label: '30 days',
            active: period == _Period.month,
            onTap: () => onChanged(_Period.month),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight:
                active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── KPI card ─────────────────────────────────────────────────────────────────

class _RCKpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sub;
  final int delay;

  const _RCKpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sub,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E3A),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }
}

// ─── Gradient bar chart ────────────────────────────────────────────────────────

class _BarChart extends StatefulWidget {
  final List<_BarValue> bars;

  const _BarChart({required this.bars});

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_BarChart old) {
    super.didUpdateWidget(old);
    if (old.bars != widget.bars) {
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
        painter: _BarChartPainter(
          bars: widget.bars,
          progress: _anim.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_BarValue> bars;
  final double progress;

  const _BarChartPainter({required this.bars, required this.progress});

  static const _gradientColors = [
    Color(0xFFF97316), // orange top
    Color(0xFFEF4444), // red bottom
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final maxVal =
        bars.map((b) => b.value).fold(0.0, math.max).clamp(0.01, double.infinity);

    const barRadius = Radius.circular(6);
    const labelH = 20.0;
    const barSpacing = 6.0;
    final totalBars = bars.length;
    final barW =
        (size.width - barSpacing * (totalBars - 1)) / totalBars;
    final chartH = size.height - labelH;

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final x = i * (barW + barSpacing);
      final normalised = (bar.value / maxVal).clamp(0.0, 1.0);
      final barH = (normalised * chartH * progress).clamp(4.0, chartH);
      final top = chartH - barH;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barW, barH),
        topLeft: barRadius,
        topRight: barRadius,
      );

      // Gradient fill
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bar.value == 0
            ? [const Color(0xFF2D3060), const Color(0xFF2D3060)]
            : _gradientColors,
      ).createShader(rect.outerRect);

      canvas.drawRRect(rect, Paint()..shader = gradient);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + (barW - tp.width) / 2, chartH + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress || old.bars != bars;
}
