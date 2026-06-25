import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/category_model.dart';
import '../state/app_state.dart';
import '../state/ai_state.dart';
import '../widgets/app_drawer_button.dart';
import '../widgets/app_logo.dart';
import '../widgets/search_icon_button.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/common_widgets.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/transaction_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MapEntry<DateTime, double>>? _monthlyTotals;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_monthlyTotals == null) _loadChart();
  }

  Future<void> _loadChart() async {
    final data = await context.read<AppState>().lastNMonthsTotals(6);
    if (mounted) setState(() => _monthlyTotals = data);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ai = context.watch<AiState>();
    final monthLabel = DateFormat('MMMM yyyy').format(state.focusedMonth);
    final summary = state.endOfDaySummary;
    final dailyEnvelopes = state.envelopes
        .where((e) => e.category?.section == CategorySection.daily)
        .toList();
    final breakdown = state.categoryBreakdown();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Row(
            children: [
              const AppDrawerButton(),
              const Spacer(),
              const AppLogo(size: 32),
              const SizedBox(width: 8),
              Text(
                'SpendWise',
                style: AppText.h2.copyWith(color: AppColors.amber, letterSpacing: -0.5, fontSize: 20),
              ),
              const Spacer(),
              const SearchIconButton(),
              const ProfileAvatar(size: 40),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthLabel.toUpperCase(),
                    style: AppText.label.copyWith(color: AppColors.t3),
                  ),
                  const SizedBox(height: 2),
                  Text('Dashboard', style: AppText.display.copyWith(fontSize: 26)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SafeToSpendCard(
            safeToSpend: state.safeToSpendPerDay,
            todayTotal: state.todayTotal,
            monthlyRemaining: state.monthlyRemaining,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'This week', value: state.last7DaysTotal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(label: 'Daily avg', value: state.dailyAverage),
              ),
            ],
          ),
          if (_monthlyTotals != null && _monthlyTotals!.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('6-month trend'),
                  const SizedBox(height: 16),
                  MonthlyTrendChart(monthlyTotals: _monthlyTotals!),
                ],
              ),
            ),
          ],
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Category breakdown'),
                  const SizedBox(height: 12),
                  CategoryBreakdownChart(breakdown: breakdown),
                ],
              ),
            ),
          ],
          if (ai.dailyInsight != null) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('AI Insight'),
                  const SizedBox(height: 8),
                  Text(ai.dailyInsight!, style: AppText.body),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('End of Day'),
                const SizedBox(height: 12),
                _SummaryRow('Spent today', formatCurrency(summary.totalSpent)),
                if (summary.largestCategory != null)
                  _SummaryRow('Largest', '${summary.largestCategory} (${formatCurrency(summary.largestCategoryAmount)})'),
                _SummaryRow(
                  'vs Yesterday',
                  '${summary.comparisonToYesterday >= 0 ? '+' : ''}${formatCurrency(summary.comparisonToYesterday)}',
                ),
              ],
            ),
          ),
          if (state.todaysAnomalies.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Anomalies'),
                  const SizedBox(height: 10),
                  ...state.todaysAnomalies.take(3).map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a.reason, style: AppText.bodyMuted.copyWith(fontSize: 12))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (dailyEnvelopes.isNotEmpty) ...[
            const SectionLabel('Envelopes'),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dailyEnvelopes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final env = dailyEnvelopes[i];
                  return Column(
                    children: [
                      EnvelopeRing(envelope: env),
                      const SizedBox(height: 6),
                      Text(env.category?.name ?? '', style: AppText.caption),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel("Today's Expenses"),
              Text(formatCurrency(state.todayTotal), style: AppText.numberSmall(color: AppColors.t2)),
            ],
          ),
          const SizedBox(height: 12),
          ..._todayList(context, state),
        ],
      ),
    );
  }

  List<Widget> _todayList(BuildContext context, AppState state) {
    final today = state.displayForDay(DateTime.now());
    if (today.isEmpty) {
      return const [
        EmptyState(
          emoji: '🧾',
          title: 'Nothing logged today',
          subtitle: 'Tap + to add your first expense.',
        ),
      ];
    }
    return today.map((t) {
      final cat = state.categoryById(t.categoryId);
      final tags = state.tagsForIds(t.tagIds);
      return TransactionTile(
        transaction: t,
        category: cat,
        tags: tags,
        onTap: () => showTransactionDetailSheet(context, t, category: cat),
      );
    }).toList();
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 6),
          AnimatedCurrency(value: value, style: AppText.numberMedium()),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.bodyMuted),
          Text(value, style: AppText.numberSmall()),
        ],
      ),
    );
  }
}
