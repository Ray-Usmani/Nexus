import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../state/ai_state.dart';
import '../widgets/common_widgets.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<MapEntry<DateTime, double>>? _monthlyTotals;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_monthlyTotals == null) _loadChart();
  }

  Future<void> _loadChart() async {
    final state = context.read<AppState>();
    final data = await state.lastNMonthsTotals(6);
    if (mounted) setState(() => _monthlyTotals = data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ai = context.watch<AiState>();
    final review = state.weeklyReview;
    final drift = state.envelopes.where((e) => e.planned > 0 && e.actual / e.planned > 0.9).toList();
    final breakdown = state.categoryBreakdown();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const SectionLabel('Analytics'),
          const SizedBox(height: 4),
          Text('Insights', style: AppText.display),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Weekly Review'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Metric('This week', formatCurrency(review.thisWeekTotal)),
                    ),
                    Expanded(
                      child: _Metric('Last week', formatCurrency(review.lastWeekTotal)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (review.biggestCategory != null)
                  Text('Biggest: ${review.biggestCategory} (${formatCurrency(review.biggestCategoryAmount)})',
                      style: AppText.bodyMuted),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Budget health', style: AppText.bodyMuted),
                    const Spacer(),
                    Text('${review.healthScore.toStringAsFixed(0)}%', style: AppText.numberSmall(color: AppColors.lime)),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedProgressBar(fraction: review.healthScore / 100, color: AppColors.lime),
                if (review.changeVsLastWeek != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${review.changeVsLastWeek >= 0 ? '+' : ''}${review.changeVsLastWeek.toStringAsFixed(0)}% vs last week',
                      style: AppText.caption.copyWith(
                        color: review.changeVsLastWeek > 0 ? AppColors.negative : AppColors.lime,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (ai.weeklySummary != null) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SectionLabel('AI Recommendations'),
                      const Spacer(),
                      if (ai.loading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(ai.weeklySummary!, style: AppText.body),
                  if (ai.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...ai.recommendations.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.lime)),
                              Expanded(child: Text(r, style: AppText.bodyMuted.copyWith(fontSize: 13))),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextButton(
            onPressed: ai.loading ? null : () => ai.refreshWeeklyInsight(state),
            child: Text(ai.loading ? 'Loading AI insight…' : 'Refresh AI insight', style: const TextStyle(color: AppColors.lime)),
          ),
          const SizedBox(height: 14),
          if (_monthlyTotals != null && _monthlyTotals!.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('6-month trend'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
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
                                if (i < 0 || i >= _monthlyTotals!.length) return const SizedBox();
                                return Text(
                                  DateFormat('MMM').format(_monthlyTotals![i].key),
                                  style: AppText.caption.copyWith(fontSize: 9),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: _monthlyTotals!.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.value,
                                color: AppColors.lime,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (drift.isNotEmpty) ...[
            const SectionLabel('Budget drift'),
            const SizedBox(height: 10),
            ...drift.map((e) => AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(e.category?.icon ?? '📦'),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.category?.name ?? '', style: AppText.body)),
                      Text('${(e.fraction * 100).toStringAsFixed(0)}%', style: AppText.numberSmall(color: AppColors.warn)),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
          ],
          if (state.todaysAnomalies.isNotEmpty) ...[
            const SectionLabel('Anomalies today'),
            const SizedBox(height: 10),
            ...state.todaysAnomalies.map((a) => AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Text(a.reason, style: AppText.bodyMuted.copyWith(fontSize: 13)),
                )),
            const SizedBox(height: 14),
          ],
          if (breakdown.isNotEmpty) ...[
            const SectionLabel('Category breakdown'),
            const SizedBox(height: 10),
            ...breakdown.take(8).map((e) {
              final total = breakdown.fold(0.0, (s, x) => s + x.value);
              final frac = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e.key.icon} ${e.key.name}', style: AppText.body),
                        Text(formatCurrency(e.value), style: AppText.numberSmall()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedProgressBar(fraction: frac, color: e.key.color),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        Text(value, style: AppText.numberSmall()),
      ],
    );
  }
}
