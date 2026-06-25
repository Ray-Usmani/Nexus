import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/app_database.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/app_logo.dart';
import '../widgets/search_icon_button.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: CustomScrollView(
        slivers: [
          // ── Top App Bar ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.t1),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const AppLogo(size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'SpendWise',
                    style: AppText.h2.copyWith(color: AppColors.amber, letterSpacing: -0.5, fontSize: 20),
                  ),
                  const Spacer(),
                  const SearchIconButton(),
                ],
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Goals', style: AppText.h1.copyWith(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        'Track and manage your savings',
                        style: AppText.bodyMuted,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _addGoal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 18, color: AppColors.onAmber),
                          const SizedBox(width: 6),
                          Text(
                            'NEW GOAL',
                            style: AppText.label.copyWith(color: AppColors.onAmber, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Goals List ───────────────────────────────────────────────
          if (state.goals.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dashed "add" placeholder card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => _addGoal(context),
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppColors.bg3,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.line.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: AppColors.bg2,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Color(0x1A000000), blurRadius: 8),
                                ],
                              ),
                              child: const Icon(Icons.add, size: 28, color: AppColors.amber),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Dreaming of something?',
                              style: AppText.h2.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a goal to start saving for your\nnext big milestone.',
                              style: AppText.bodyMuted,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i < state.goals.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCard(
                          goal: state.goals[i],
                          colorIndex: i,
                          onDelete: () => state.deleteGoal(state.goals[i].id),
                          onUpdateProgress: () => _updateProgress(ctx, state.goals[i]),
                        ),
                      );
                    }
                    // "Add New Goal" card
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _addGoal(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.line.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.bg2,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 24, color: AppColors.amber),
                              ),
                              const SizedBox(height: 12),
                              Text('Add another goal', style: AppText.h2.copyWith(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                'Start saving for your next milestone',
                                style: AppText.bodyMuted.copyWith(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: state.goals.length + 1,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
        ),
      ),
    );
  }

  Future<void> _addGoal(BuildContext context) async {
    final name = TextEditingController();
    final target = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Goal name (e.g. Emergency Fund)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Target amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.t3)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      final t = double.tryParse(target.text) ?? 0;
      if (name.text.isNotEmpty && t > 0) {
        await context.read<AppState>().addGoal(GoalModel(
              id: AppDatabase.instance.newId(),
              name: name.text.trim(),
              icon: '🎯',
              targetAmount: t,
              currentAmount: 0,
              colorIndex: 0,
            ));
      }
    }
  }

  Future<void> _updateProgress(BuildContext context, GoalModel g) async {
    final controller = TextEditingController(text: g.currentAmount.toStringAsFixed(0));
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update — ${g.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppText.body,
          decoration: const InputDecoration(hintText: 'Current saved amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.t3)),
          ),
          ElevatedButton(
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
      await context.read<AppState>().updateGoal(g.copyWith(currentAmount: v));
    }
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final int colorIndex;
  final VoidCallback onDelete;
  final VoidCallback onUpdateProgress;

  const _GoalCard({
    required this.goal,
    required this.colorIndex,
    required this.onDelete,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.catColors[colorIndex % AppColors.catColors.length];
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final isCompleted = goal.progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(goal.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: AppText.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted ? 'Goal achieved! 🎉' : 'In progress',
                      style: AppText.caption.copyWith(
                        color: isCompleted ? AppColors.amber : AppColors.t3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(goal.currentAmount),
                    style: AppText.numberSmall().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.t1,
                    ),
                  ),
                  Text(
                    'of ${formatCurrency(goal.targetAmount)}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct% completed',
                style: AppText.labelMd.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              Text(
                isCompleted ? 'Done!' : '${formatCurrency(goal.remaining)} left',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedProgressBar(
            fraction: goal.progress,
            color: color,
            height: 8,
            delay: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onUpdateProgress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.amberBright.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Update progress',
                      style: AppText.labelMd.copyWith(color: AppColors.amber),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.delete_outline, size: 18, color: AppColors.t3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
