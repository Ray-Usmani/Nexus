import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Which part of the app a category belongs to. Mirrors the roadmap's
/// structural split:
///   - daily    → Food, Transport, Shopping, Entertainment, Misc
///   - fixed    → Charity, Savings, Investments, Subscriptions
///   - income   → salary, freelance, etc.
///   - transfer → moving money between your own accounts/envelopes
enum CategorySection { daily, fixed, income, transfer }

CategorySection sectionFromString(String s) =>
    CategorySection.values.firstWhere((e) => e.name == s, orElse: () => CategorySection.daily);

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int colorIndex;
  final CategorySection section;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.section,
    this.isDefault = false,
  });

  Color get color => AppColors.catColors[colorIndex % AppColors.catColors.length];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'colorIndex': colorIndex,
        'section': section.name,
        'isDefault': isDefault ? 1 : 0,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        colorIndex: map['colorIndex'] as int,
        section: sectionFromString(map['section'] as String),
        isDefault: (map['isDefault'] as int) == 1,
      );

  CategoryModel copyWith({String? name, String? icon, int? colorIndex}) => CategoryModel(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        colorIndex: colorIndex ?? this.colorIndex,
        section: section,
        isDefault: isDefault,
      );
}

/// Seed categories created on first launch, matching the roadmap's
/// Daily Tracking + Fixed Expenses structure.
List<CategoryModel> defaultCategories(String Function() genId) => [
      // Daily tracking
      CategoryModel(id: genId(), name: 'Food',          icon: '🍽️', colorIndex: 2, section: CategorySection.daily, isDefault: true),
      CategoryModel(id: genId(), name: 'Transport',      icon: '🚌', colorIndex: 3, section: CategorySection.daily, isDefault: true),
      CategoryModel(id: genId(), name: 'Shopping',       icon: '🛍️', colorIndex: 4, section: CategorySection.daily, isDefault: true),
      CategoryModel(id: genId(), name: 'Entertainment',  icon: '🎬', colorIndex: 5, section: CategorySection.daily, isDefault: true),
      CategoryModel(id: genId(), name: 'Miscellaneous',  icon: '📦', colorIndex: 6, section: CategorySection.daily, isDefault: true),
      // Fixed allocations
      CategoryModel(id: genId(), name: 'Charity',        icon: '🤲', colorIndex: 0, section: CategorySection.fixed, isDefault: true),
      CategoryModel(id: genId(), name: 'Savings',        icon: '💰', colorIndex: 0, section: CategorySection.fixed, isDefault: true),
      CategoryModel(id: genId(), name: 'Investments',    icon: '📈', colorIndex: 1, section: CategorySection.fixed, isDefault: true),
      CategoryModel(id: genId(), name: 'Subscriptions',  icon: '🔁', colorIndex: 7, section: CategorySection.fixed, isDefault: true),
      // Income / transfer
      CategoryModel(id: genId(), name: 'Income',         icon: '💵', colorIndex: 0, section: CategorySection.income, isDefault: true),
      CategoryModel(id: genId(), name: 'Transfer',       icon: '↔️', colorIndex: 3, section: CategorySection.transfer, isDefault: true),
    ];