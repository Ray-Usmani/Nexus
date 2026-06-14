/// A savings goal — "Laptop", "Germany", "Emergency Fund", etc.
/// [currentAmount] is tracked manually or can be linked to a Savings
/// fixed-allocation total (kept simple/manual here for a single-user app).
class GoalModel {
  final String id;
  final String name;
  final String icon;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final int colorIndex;

  GoalModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.colorIndex,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0, 1) : 0;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline?.toIso8601String(),
        'colorIndex': colorIndex,
      };

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        targetAmount: (map['targetAmount'] as num).toDouble(),
        currentAmount: (map['currentAmount'] as num).toDouble(),
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
        colorIndex: map['colorIndex'] as int,
      );

  GoalModel copyWith({String? name, double? targetAmount, double? currentAmount, DateTime? deadline}) =>
      GoalModel(
        id: id,
        name: name ?? this.name,
        icon: icon,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        colorIndex: colorIndex,
      );
}