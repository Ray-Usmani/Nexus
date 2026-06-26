import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/account_entry_model.dart';
import '../models/account_model.dart';
import '../state/accounts_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AccountDetailScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsState>().loadEntries(widget.accountId);
    });
  }

  AccountModel? get _account => context.watch<AccountsState>().accountById(widget.accountId);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountsState>();
    final account = _account;
    if (account == null) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: AppBar(backgroundColor: AppColors.bg0),
        body: const Center(child: Text('Account not found', style: TextStyle(color: AppColors.t2))),
      );
    }

    final entries = state.entriesFor(widget.accountId);
    final color = AppColors.catColors[account.colorIndex % AppColors.catColors.length];

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.t1),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(account.title, style: AppText.h2, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.account_balance_wallet, color: color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatCurrency(account.balance),
                      style: AppText.display.copyWith(fontSize: 34, color: AppColors.amber),
                    ),
                    const SizedBox(height: 4),
                    Text('Current balance', style: AppText.caption),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Add',
                      onTap: () => _recordDeposit(context, account),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.remove_circle_outline,
                      label: 'Expense',
                      onTap: () => _recordExpense(context, account),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.swap_horiz,
                      label: 'Transfer',
                      onTap: () => _recordTransfer(context, account, state.accounts),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const SectionLabel('History'),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'No entries yet.\nAdd funds, record an expense, or transfer.',
                        style: AppText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _EntryTile(
                        entry: entries[i],
                        state: state,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordDeposit(BuildContext context, AccountModel account) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Add to balance — ${account.title}', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Note (optional)'),
              maxLines: 2,
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      final a = double.tryParse(amount.text.replaceAll(',', ''));
      if (a != null && a > 0) {
        await context.read<AccountsState>().recordDeposit(
              accountId: account.id,
              amount: a,
              note: note.text,
            );
      }
    }
  }

  Future<void> _recordExpense(BuildContext context, AccountModel account) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Record expense — ${account.title}', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Note (optional)'),
              maxLines: 2,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      final a = double.tryParse(amount.text.replaceAll(',', ''));
      if (a != null && a > 0) {
        await context.read<AccountsState>().recordExpense(
              accountId: account.id,
              amount: a,
              note: note.text,
            );
      }
    }
  }

  Future<void> _recordTransfer(
    BuildContext context,
    AccountModel fromAccount,
    List<AccountModel> allAccounts,
  ) async {
    final others = allAccounts.where((a) => a.id != fromAccount.id).toList();
    if (others.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add another account to transfer between accounts')),
      );
      return;
    }

    String? toId = others.first.id;
    final amount = TextEditingController();
    final note = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.bg2,
          title: Text('Transfer from ${fromAccount.title}', style: AppText.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: toId,
                dropdownColor: AppColors.bg3,
                style: AppText.body,
                decoration: const InputDecoration(hintText: 'To account'),
                items: others
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.title)))
                    .toList(),
                onChanged: (v) => setLocal(() => toId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppText.body,
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                style: AppText.body,
                decoration: const InputDecoration(hintText: 'Note (optional)'),
                maxLines: 2,
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
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted && toId != null) {
      final a = double.tryParse(amount.text.replaceAll(',', ''));
      if (a != null && a > 0) {
        await context.read<AccountsState>().recordTransfer(
              fromAccountId: fromAccount.id,
              toAccountId: toId!,
              amount: a,
              note: note.text,
            );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.amberBright.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.amber, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppText.labelMd.copyWith(color: AppColors.amber)),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final AccountEntryModel entry;
  final AccountsState state;

  const _EntryTile({required this.entry, required this.state});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(entry.date);
    final related = entry.relatedAccountId != null
        ? state.accountById(entry.relatedAccountId!)?.title
        : null;

    String title;
    switch (entry.type) {
      case AccountEntryType.expense:
        title = entry.note.isNotEmpty ? entry.note : 'Expense';
      case AccountEntryType.deposit:
        title = entry.note.isNotEmpty ? entry.note : 'Added to balance';
      case AccountEntryType.transferOut:
        title = related != null ? 'Transfer to $related' : 'Transfer out';
      case AccountEntryType.transferIn:
        title = related != null ? 'Transfer from $related' : 'Transfer in';
    }

    final sign = entry.isCredit ? '+' : '−';
    final amountColor = entry.isCredit ? AppColors.positive : AppColors.negative;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              switch (entry.type) {
                AccountEntryType.expense => Icons.shopping_bag_outlined,
                AccountEntryType.deposit => Icons.add_circle_outline,
                AccountEntryType.transferOut || AccountEntryType.transferIn => Icons.swap_horiz,
              },
              color: AppColors.t2,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                if (entry.note.isNotEmpty &&
                    entry.type != AccountEntryType.expense &&
                    !title.contains(entry.note))
                  Text(entry.note, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(dateStr, style: AppText.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(
            '$sign${formatCurrency(entry.amount)}',
            style: AppText.numberSmall().copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
