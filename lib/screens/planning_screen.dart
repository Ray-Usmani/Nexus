import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget_plan_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monthLabel = DateFormat('MMMM yyyy').format(state.focusedMonth);
    final remaining = state.totalPlannedAll - state.monthTotalAll;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(monthLabel),
                  const SizedBox(height: 4),
                  Text('Planning', style: AppText.display),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.t2),
                    onPressed: () => _shiftMonth(context, -1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.t2),
                    onPressed: () => _shiftMonth(context, 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AppState>().copyPreviousMonth(),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy prev month'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lime,
                    side: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addPlan(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add row'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lime,
                    side: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Remaining allocation'),
                    Text(formatCurrency(remaining), style: AppText.numberMedium(
                      color: remaining < 0 ? AppColors.negative : AppColors.lime,
                    )),
                  ],
                ),
                Text(
                  '${formatCurrency(state.totalPlannedAll)} planned',
                  style: AppText.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...state.envelopes.map((env) {
            final frac = env.planned > 0 ? env.actual / env.planned : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    EnvelopeRing(envelope: env, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(env.category?.name ?? 'Unknown', style: AppText.body),
                          const SizedBox(height: 4),
                          Text(
                            '${formatCurrency(env.actual)} / ${formatCurrency(env.planned)}',
                            style: AppText.numberSmall(color: AppColors.t2),
                          ),
                          const SizedBox(height: 6),
                          AnimatedProgressBar(fraction: frac, color: env.category?.color ?? AppColors.lime),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          const SectionLabel('Plan rows'),
          const SizedBox(height: 10),
          if (state.plans.isEmpty)
            const EmptyState(emoji: '📋', title: 'No plans', subtitle: 'Copy previous month or add a row.')
          else
            ...state.plans.map((p) => _PlanRow(plan: p)),
        ],
      ),
    );
  }

  void _shiftMonth(BuildContext context, int delta) {
    final state = context.read<AppState>();
    final m = DateTime(state.focusedMonth.year, state.focusedMonth.month + delta, 1);
    state.setFocusedMonth(m);
  }

  Future<void> _addPlan(BuildContext context) async {
    final state = context.read<AppState>();
    if (state.categories.isEmpty) return;
    final cat = state.categories.first;
    await state.addPlan(categoryId: cat.id, plannedAmount: 1000);
  }
}

class _PlanRow extends StatelessWidget {
  final BudgetPlanModel plan;
  const _PlanRow({required this.plan});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cat = state.categoryById(plan.categoryId);
    final actual = state.actualForPlan(plan);
    final label = plan.subcategory.isEmpty ? (cat?.name ?? '') : '${cat?.name} · ${plan.subcategory}';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _editPlan(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body),
                Text(
                  'Actual: ${formatCurrency(actual)}',
                  style: AppText.caption.copyWith(
                    color: actual > plan.plannedAmount ? AppColors.negative : AppColors.t3,
                  ),
                ),
              ],
            ),
          ),
          Text(formatCurrency(plan.plannedAmount), style: AppText.numberSmall()),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.t3, size: 18),
            onPressed: () => state.deletePlan(plan.id),
          ),
        ],
      ),
    );
  }

  Future<void> _editPlan(BuildContext context) async {
    final controller = TextEditingController(text: plan.plannedAmount.toStringAsFixed(0));
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Edit planned amount', style: AppText.h2),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppText.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = double.tryParse(controller.text);
              if (n != null) Navigator.pop(ctx, n);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v != null && context.mounted) {
      await context.read<AppState>().upsertPlan(plan.copyWith(plannedAmount: v));
    }
  }
}
