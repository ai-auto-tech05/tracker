import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/analytics_provider.dart';

class WeeklyFocusChart extends StatelessWidget {
  final List<DayStats> days;

  const WeeklyFocusChart({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxMinutes = days.isEmpty
        ? 60.0
        : days.map((d) => d.focusMinutes.toDouble()).reduce(
              (a, b) => a > b ? a : b) +
            10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxMinutes < 10 ? 60 : maxMinutes,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gIdx, rod, rIdx) => BarTooltipItem(
              '${rod.toY.toInt()}m',
              TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 30,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) {
                  return const SizedBox.shrink();
                }
                final isToday = DateHelper.isToday(days[idx].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateHelper.formatDayLetter(days[idx].date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isToday
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (_) => FlLine(
            color:
                isDark ? AppColors.darkDivider : AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(days.length, (i) {
          final day = days[i];
          final isToday = DateHelper.isToday(day.date);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: day.focusMinutes.toDouble(),
                color: isToday
                    ? AppColors.primary
                    : AppColors.primaryLight.withOpacity(0.5),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class WeeklyHabitChart extends StatelessWidget {
  final List<DayStats> days;

  const WeeklyHabitChart({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gIdx, rod, rIdx) => BarTooltipItem(
              '${(rod.toY * 100).toInt()}%',
              const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 0.5,
              getTitlesWidget: (value, _) => Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) {
                  return const SizedBox.shrink();
                }
                final isToday = DateHelper.isToday(days[idx].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateHelper.formatDayLetter(days[idx].date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isToday
                          ? AppColors.success
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(days.length, (i) {
          final day = days[i];
          final isToday = DateHelper.isToday(day.date);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: day.habitRate,
                color: isToday
                    ? AppColors.success
                    : AppColors.successLight.withOpacity(0.5),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
