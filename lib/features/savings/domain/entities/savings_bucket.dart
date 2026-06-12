class SavingsBucket {
  final String id;
  final String title;
  final double currentAmount;
  final DateTime createdAt;

  static const String tableName = 'savings_buckets';

  SavingsBucket({
    required this.id,
    required this.title,
    required this.currentAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'currentAmount': currentAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavingsBucket.fromMap(Map<String, dynamic> map) {
    return SavingsBucket(
      id: map['id'] as String,
      title: map['title'] as String,
      currentAmount: (map['currentAmount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SavingsBucket copyWith({
    String? id,
    String? title,
    double? currentAmount,
    DateTime? createdAt,
  }) {
    return SavingsBucket(
      id: id ?? this.id,
      title: title ?? this.title,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
