import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final List<MapEntry<CategoryModel, double>> breakdown;
  final int maxItems;

  const CategoryBreakdownChart({
    super.key,
    required this.breakdown,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final items = breakdown.take(maxItems).toList();
    if (items.isEmpty) {
      return Text('No spending this month', style: AppText.bodyMuted);
    }

    final maxValue = items.first.value;

    return Column(
      children: items.map((entry) {
        final cat = entry.key;
        final amount = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cat.name, style: AppText.body.copyWith(fontSize: 13)),
                  ),
                  Text(formatCurrency(amount), style: AppText.numberSmall(color: AppColors.t2)),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedProgressBar(
                fraction: maxValue > 0 ? amount / maxValue : 0,
                color: cat.color,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
