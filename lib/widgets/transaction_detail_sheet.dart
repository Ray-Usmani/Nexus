import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context,
  TransactionModel transaction, {
  CategoryModel? category,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category?.icon ?? '📝', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category?.name ?? 'Expense',
                  style: AppText.body.copyWith(color: AppColors.t3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(formatCurrency(transaction.amount), style: AppText.numberLarge()),
          const SizedBox(height: 8),
          Text(
            transaction.note.isEmpty ? 'No note' : transaction.note,
            style: AppText.body,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy HH:mm').format(transaction.date),
            style: AppText.caption,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: AppColors.bg2,
                    title: Text('Delete expense?', style: AppText.h2.copyWith(fontSize: 18)),
                    content: Text(
                      'This will permanently remove ${formatCurrency(transaction.amount)} from your records.',
                      style: AppText.bodyMuted,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.t3)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.negative)),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !ctx.mounted) return;

                await ctx.read<AppState>().deleteTransaction(transaction.id);
                if (ctx.mounted) Navigator.pop(ctx);
                onDeleted?.call();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted'),
                      backgroundColor: AppColors.bg3,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.negative,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.negative.withValues(alpha: 0.4)),
                ),
              ),
              child: const Text('Delete transaction'),
            ),
          ),
        ],
      ),
    ),
  );
}
