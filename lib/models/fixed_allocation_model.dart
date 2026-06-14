/// How often a fixed allocation recurs.
enum RecurFrequency { once, weekly, monthly, yearly }

RecurFrequency frequencyFromString(String s) =>
    RecurFrequency.values.firstWhere((e) => e.name == s, orElse: () => RecurFrequency.monthly);

/// A recurring (or one-off) fixed allocation — Charity, Savings,
/// Investments, Subscriptions. Each can optionally auto-log a transaction
/// when its [nextDueDate] arrives (checked on app open).
class FixedAllocationModel {
  final String id;
  final String categoryId; // points to a "fixed" section category
  final String name;       // e.g. "Netflix", "Mutual Fund SIP", "Local Shelter"
  final double amount;
  final RecurFrequency frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final bool autoLog; // if true, a transaction is created automatically when due

  FixedAllocationModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    this.autoLog = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'amount': amount,
        'frequency': frequency.name,
        'nextDueDate': nextDueDate.toIso8601String(),
        'isActive': isActive ? 1 : 0,
        'autoLog': autoLog ? 1 : 0,
      };

  factory FixedAllocationModel.fromMap(Map<String, dynamic> map) => FixedAllocationModel(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        frequency: frequencyFromString(map['frequency'] as String),
        nextDueDate: DateTime.parse(map['nextDueDate'] as String),
        isActive: (map['isActive'] as int) == 1,
        autoLog: (map['autoLog'] as int) == 1,
      );

  FixedAllocationModel copyWith({
    String? name,
    double? amount,
    RecurFrequency? frequency,
    DateTime? nextDueDate,
    bool? isActive,
    bool? autoLog,
  }) => FixedAllocationModel(
        id: id,
        categoryId: categoryId,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        frequency: frequency ?? this.frequency,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
        autoLog: autoLog ?? this.autoLog,
      );

  /// Advances [nextDueDate] by one period — called after logging.
  DateTime nextOccurrence() {
    switch (frequency) {
      case RecurFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case RecurFrequency.monthly:
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case RecurFrequency.yearly:
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
      case RecurFrequency.once:
        return nextDueDate;
    }
  }
}