/// A personal account/wallet — cash, bank, savings, etc.
/// Balances are tracked independently from budget transactions.
class AccountModel {
  final String id;
  final String title;
  final double balance;
  final int colorIndex;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.title,
    required this.balance,
    required this.colorIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'balance': balance,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
        id: map['id'] as String,
        title: map['title'] as String,
        balance: (map['balance'] as num).toDouble(),
        colorIndex: map['colorIndex'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  AccountModel copyWith({String? title, double? balance}) => AccountModel(
        id: id,
        title: title ?? this.title,
        balance: balance ?? this.balance,
        colorIndex: colorIndex,
        createdAt: createdAt,
      );
}
