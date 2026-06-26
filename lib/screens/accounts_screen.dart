import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../state/accounts_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountsState = context.watch<AccountsState>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.t1),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Accounts', style: AppText.h1.copyWith(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            'Track balances separately from your budget',
                            style: AppText.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addAccount(context),
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
                              'NEW',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Total balance'),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency(accountsState.totalBalance),
                        style: AppText.display.copyWith(fontSize: 32, color: AppColors.amber),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${accountsState.accounts.length} account${accountsState.accounts.length == 1 ? '' : 's'}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            if (accountsState.accounts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _addAccount(context),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.bg2,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined,
                                size: 28, color: AppColors.amber),
                          ),
                          const SizedBox(height: 16),
                          Text('No accounts yet', style: AppText.h2.copyWith(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text(
                            'Add a cash, bank, or savings account\nto track balances and transfers.',
                            style: AppText.bodyMuted,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: accountsState.accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final account = accountsState.accounts[i];
                    return _AccountCard(
                      account: account,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountDetailScreen(accountId: account.id),
                        ),
                      ),
                      onDelete: () => _confirmDelete(context, account),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAccount(BuildContext context) async {
    final title = TextEditingController();
    final balance = TextEditingController(text: '0');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('New Account', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Account title (e.g. HBL Savings)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Starting balance'),
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
    if (saved == true && context.mounted && title.text.trim().isNotEmpty) {
      final b = double.tryParse(balance.text.replaceAll(',', '')) ?? 0;
      await context.read<AccountsState>().addAccount(title: title.text, balance: b);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AccountModel account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Delete ${account.title}?', style: AppText.h2),
        content: Text(
          'This removes the account and its ledger history. Budget transactions are not affected.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.t3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AccountsState>().deleteAccount(account.id);
    }
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.catColors[account.colorIndex % AppColors.catColors.length];

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.account_balance_wallet, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.title, style: AppText.h2.copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                Text('Tap to view & record', style: AppText.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(account.balance),
                style: AppText.numberSmall().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: account.balance >= 0 ? AppColors.t1 : AppColors.negative,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.t3),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
