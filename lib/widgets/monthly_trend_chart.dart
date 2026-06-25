import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class MonthlyTrendChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> monthlyTotals;
  final double height;

  const MonthlyTrendChart({
    super.key,
    required this.monthlyTotals,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyTotals.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('No data yet', style: AppText.bodyMuted)),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= monthlyTotals.length) return const SizedBox();
                  return Text(
                    DateFormat('MMM').format(monthlyTotals[i].key),
                    style: AppText.caption.copyWith(fontSize: 9),
                  );
                },
              ),
            ),
          ),
          barGroups: monthlyTotals.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: AppColors.amber,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
