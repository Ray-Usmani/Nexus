import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../screens/goals_screen.dart';
import '../screens/planning_screen.dart';
import '../screens/fixed_screen.dart';
import '../screens/accounts_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'SpendWise',
                    style: AppText.h2.copyWith(color: AppColors.amber, fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'More screens',
                    style: AppText.caption.copyWith(color: AppColors.t3),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: AppColors.line.withValues(alpha: 0.3)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: Icons.account_balance_outlined,
                    label: 'Accounts',
                    onTap: () => _navigate(context, const AccountsScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.flag_outlined,
                    label: 'Goals',
                    onTap: () => _navigate(context, const GoalsScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Budget Planning',
                    onTap: () => _navigate(context, const PlanningScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.repeat_outlined,
                    label: 'Fixed Expenses',
                    onTap: () => _navigate(context, const FixedScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.amber, size: 22),
      ),
      title: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.t3, size: 20),
      onTap: onTap,
    );
  }
}
