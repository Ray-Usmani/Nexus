import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/app_database.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        title: Text('Goals', style: AppText.h2),
        iconTheme: const IconThemeData(color: AppColors.t1),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.lime), onPressed: () => _addGoal(context)),
        ],
      ),
      body: state.goals.isEmpty
          ? const Center(
              child: EmptyState(
                emoji: '🎯',
                title: 'No goals yet',
                subtitle: 'Track savings for laptop, travel, emergency fund…',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.goals.length,
              itemBuilder: (context, i) {
                final g = state.goals[i];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(g.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(g.name, style: AppText.h2.copyWith(fontSize: 16))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.t3, size: 18),
                            onPressed: () => state.deleteGoal(g.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatCurrency(g.currentAmount)} / ${formatCurrency(g.targetAmount)}',
                        style: AppText.numberSmall(),
                      ),
                      const SizedBox(height: 8),
                      AnimatedProgressBar(fraction: g.progress, color: AppColors.catColors[g.colorIndex % AppColors.catColors.length]),
                      const SizedBox(height: 8),
                      Text('${(g.progress * 100).toStringAsFixed(0)}% · ${formatCurrency(g.remaining)} to go',
                          style: AppText.caption),
                      TextButton(
                        onPressed: () => _updateProgress(context, g),
                        child: const Text('Update progress', style: TextStyle(color: AppColors.lime)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addGoal(BuildContext context) async {
    final name = TextEditingController();
    final target = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('New goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(hintText: 'Name')),
            TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Target amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
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
        backgroundColor: AppColors.bg2,
        title: Text('Update ${g.name}'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
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
      await context.read<AppState>().updateGoal(g.copyWith(currentAmount: v));
    }
  }
}
