class Budget {
  final String id;
  final String category;
  final double limitAmount;

  static const String tableName = 'budgets';

  Budget({required this.id, required this.category, required this.limitAmount});

  Map<String, dynamic> toMap() {
    return {'id': id, 'category': category, 'limitAmount': limitAmount};
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limitAmount: (map['limitAmount'] as num).toDouble(),
    );
  }

  Budget copyWith({String? id, String? category, double? limitAmount}) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}
