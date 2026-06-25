import 'package:flutter/material.dart';

import '../screens/search_screen.dart';
import '../theme/app_theme.dart';

/// Compact search affordance — opens [SearchScreen] as a pushed route.
class SearchIconButton extends StatelessWidget {
  const SearchIconButton({super.key});

  static void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search_rounded, color: AppColors.amber, size: 24),
      onPressed: () => open(context),
      tooltip: 'Search',
    );
  }
}
