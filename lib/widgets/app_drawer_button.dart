import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Opens the root [Scaffold] drawer from any main tab screen.
class AppDrawerButton extends StatelessWidget {
  const AppDrawerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded, color: AppColors.amber, size: 24),
      onPressed: () => Scaffold.of(context).openDrawer(),
      tooltip: 'Menu',
    );
  }
}
