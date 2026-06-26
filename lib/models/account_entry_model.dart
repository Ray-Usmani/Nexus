enum AccountEntryType { expense, deposit, transferOut, transferIn }

/// Ledger row for an account — expense, deposit, or transfer (in/out).
class AccountEntryModel {
  final String id;
  final String accountId;
  final AccountEntryType type;
  final double amount;
  final String note;
  final DateTime date;
  /// For transfers: the other account involved.
  final String? relatedAccountId;
  /// Links the two sides of a transfer.
  final String? transferGroupId;

  AccountEntryModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    this.relatedAccountId,
    this.transferGroupId,
  });

  bool get isCredit =>
      type == AccountEntryType.transferIn || type == AccountEntryType.deposit;

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountId': accountId,
        'type': type.name,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'relatedAccountId': relatedAccountId,
        'transferGroupId': transferGroupId,
      };

  factory AccountEntryModel.fromMap(Map<String, dynamic> map) => AccountEntryModel(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        type: AccountEntryType.values.byName(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String,
        date: DateTime.parse(map['date'] as String),
        relatedAccountId: map['relatedAccountId'] as String?,
        transferGroupId: map['transferGroupId'] as String?,
      );
}
