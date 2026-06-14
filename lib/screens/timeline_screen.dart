import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final txns = state.displayTransactions;

    final grouped = <String, List<TransactionModel>>{};
    for (final t in txns) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        title: Text('Timeline', style: AppText.h2),
        iconTheme: const IconThemeData(color: AppColors.t1),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final m = DateTime(state.focusedMonth.year, state.focusedMonth.month - 1, 1);
              state.setFocusedMonth(m);
            },
          ),
          Center(
            child: Text(DateFormat('MMM yyyy').format(state.focusedMonth), style: AppText.caption),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final m = DateTime(state.focusedMonth.year, state.focusedMonth.month + 1, 1);
              state.setFocusedMonth(m);
            },
          ),
        ],
      ),
      body: txns.isEmpty
          ? const Center(child: EmptyState(emoji: '📅', title: 'No transactions', subtitle: 'Add expenses to see history.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: keys.length,
              itemBuilder: (context, i) {
                final key = keys[i];
                final dayTxns = grouped[key]!;
                final date = DateTime.parse(key);
                final dayTotal = dayTxns.fold(0.0, (s, t) => s + t.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('EEEE, MMM d').format(date), style: AppText.h2.copyWith(fontSize: 15)),
                          Text(formatCurrency(dayTotal), style: AppText.numberSmall(color: AppColors.negative)),
                        ],
                      ),
                    ),
                    ...dayTxns.map((t) {
                      final cat = state.categoryById(t.categoryId);
                      final tags = state.tagsForIds(t.tagIds);
                      return TransactionTile(
                        transaction: t,
                        category: cat,
                        tags: tags,
                        onTap: () => _editNote(context, t),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _editNote(BuildContext context, TransactionModel t) async {
    final controller = TextEditingController(text: t.note);
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Edit note'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (note != null && context.mounted) {
      await context.read<AppState>().updateTransaction(t.copyWith(note: note));
    }
  }
}
