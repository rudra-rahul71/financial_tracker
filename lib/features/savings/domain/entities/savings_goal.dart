class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final double monthlyContribution;
  final DateTime createdAt;

  static const String tableName = 'savings_goals';

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.monthlyContribution,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'monthlyContribution': monthlyContribution,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      monthlyContribution: (map['monthlyContribution'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    double? monthlyContribution,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
