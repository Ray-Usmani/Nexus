import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'daily_screen.dart';
import 'planning_screen.dart';
import 'fixed_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'add_expense_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    DailyScreen(),
    PlanningScreen(),
    FixedScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  static const _labels = ['Home', 'Daily', 'Plan', 'Fixed', 'Insights', 'Settings'];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.today_rounded,
    Icons.table_chart_rounded,
    Icons.repeat_rounded,
    Icons.insights_rounded,
    Icons.settings_rounded,
  ];

  void _openQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bg0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.lineHi)),
          ),
          child: const AddExpenseScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickAdd,
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.bg0,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.bg1,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (int i = 0; i < _labels.length; i++) ...[
                if (i == 3) const SizedBox(width: 48),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icons[i], size: 20, color: _index == i ? AppColors.lime : AppColors.t3),
                        Text(
                          _labels[i],
                          style: AppText.caption.copyWith(
                            fontSize: 9,
                            color: _index == i ? AppColors.lime : AppColors.t3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
