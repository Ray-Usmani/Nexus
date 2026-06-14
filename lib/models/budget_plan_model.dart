/// A planned monthly allocation for a category (the "Planning" /
/// spreadsheet-replacement screen). [subcategory] is optional free text
/// for finer breakdowns (e.g. category "Personal" → subcategory "Weekday
/// lunches"), matching the original sheet's Category/Subcategory split.
class BudgetPlanModel {
  final String id;
  final String categoryId;
  final String subcategory; // '' if not used
  final double plannedAmount;
  final int month; // 1-12
  final int year;

  BudgetPlanModel({
    required this.id,
    required this.categoryId,
    this.subcategory = '',
    required this.plannedAmount,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'subcategory': subcategory,
        'plannedAmount': plannedAmount,
        'month': month,
        'year': year,
      };

  factory BudgetPlanModel.fromMap(Map<String, dynamic> map) => BudgetPlanModel(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String,
        subcategory: map['subcategory'] as String? ?? '',
        plannedAmount: (map['plannedAmount'] as num).toDouble(),
        month: map['month'] as int,
        year: map['year'] as int,
      );

  BudgetPlanModel copyWith({double? plannedAmount, String? subcategory}) => BudgetPlanModel(
        id: id,
        categoryId: categoryId,
        subcategory: subcategory ?? this.subcategory,
        plannedAmount: plannedAmount ?? this.plannedAmount,
        month: month,
        year: year,
      );
}