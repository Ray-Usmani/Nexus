/// Type of money movement. "expense" is the default for daily/fixed
/// spending; "income" adds to your available budget; "transfer" moves
/// money between your own envelopes/accounts (net-zero overall).
enum TransactionType { expense, income, transfer }

TransactionType typeFromString(String s) =>
    TransactionType.values.firstWhere((e) => e.name == s, orElse: () => TransactionType.expense);

/// A single transaction. Maps to the `transactions` table.
///
/// Split transactions: a "parent" transaction with [parentId] == null
/// represents the full amount; if it's been split, its [amount] still
/// holds the original total (for display in the Timeline), and one or
/// more "child" rows reference it via [parentId] with their own
/// category + amount (summing to the parent's amount). The Daily/Planning
/// aggregations use child rows when present, otherwise the parent row
/// itself.
class TransactionModel {
  final String id;
  final double amount;
  final String note;
  final String categoryId;
  final DateTime date;
  final TransactionType type;
  final String paymentMethod; // e.g. "Cash", "Card", "UPI"
  final List<String> tagIds;
  final String? parentId; // set on split "child" rows
  final bool isSplitParent; // true if this row has been split into children

  TransactionModel({
    required this.id,
    required this.amount,
    required this.note,
    required this.categoryId,
    required this.date,
    this.type = TransactionType.expense,
    this.paymentMethod = 'Cash',
    this.tagIds = const [],
    this.parentId,
    this.isSplitParent = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'note': note,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'type': type.name,
        'paymentMethod': paymentMethod,
        'tagIds': tagIds.join(','),
        'parentId': parentId,
        'isSplitParent': isSplitParent ? 1 : 0,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String,
        categoryId: map['categoryId'] as String,
        date: DateTime.parse(map['date'] as String),
        type: typeFromString(map['type'] as String? ?? 'expense'),
        paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
        tagIds: ((map['tagIds'] as String?) ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        parentId: map['parentId'] as String?,
        isSplitParent: (map['isSplitParent'] as int? ?? 0) == 1,
      );

  TransactionModel copyWith({
    double? amount,
    String? note,
    String? categoryId,
    DateTime? date,
    TransactionType? type,
    String? paymentMethod,
    List<String>? tagIds,
  }) => TransactionModel(
        id: id,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        type: type ?? this.type,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        tagIds: tagIds ?? this.tagIds,
        parentId: parentId,
        isSplitParent: isSplitParent,
      );
}

/// One slice of a split transaction (used only at creation time — the
/// repository turns these into child TransactionModel rows).
class SplitPart {
  final String categoryId;
  final double amount;
  final String note;

  SplitPart({required this.categoryId, required this.amount, this.note = ''});
}