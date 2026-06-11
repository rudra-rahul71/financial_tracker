class TransactionEntry {
  String id, accountId, name, date, type, subtype;
  double amount;

  bool isPending;
  bool isHidden = false;
  String? classification;

  static const String tableName = 'transactions';
  static const String columnId = 'id';
  static const String columnAccountId = 'account_id';
  static const String columnName = 'name';
  static const String columnDate = 'date';
  static const String columnType = 'type';
  static const String columnSubtype = 'subtype';
  static const String columnAmount = 'amount';
  static const String columnIsPending = 'is_pending';

  TransactionEntry({
    required this.id,
    required this.accountId,
    required this.name,
    required this.date,
    required this.type,
    required this.subtype,
    required this.amount,
    required this.isPending,
    this.classification,
  });

  String get billingClassification {
    if (classification != null && classification!.isNotEmpty) {
      return classification!;
    }
    // Default logic:
    if (type == 'RENT_AND_UTILITIES' || type == 'LOAN_PAYMENTS') {
      return 'fixed';
    }
    return 'variable';
  }

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['transaction_id'],
      accountId: json['account_id'],
      name: json['name'],
      date: json['date'],
      type: json['personal_finance_category']?['primary'] ?? '',
      subtype: json['personal_finance_category']?['detailed'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      isPending: json['pending'] == true,
      classification: json['classification'] as String?,
    );
  }

  static List<TransactionEntry> fromJsonList(List<dynamic> jsonList) {
    final List<TransactionEntry> transactions = [];
    for (final json in jsonList) {
      transactions.add(TransactionEntry.fromJson(json));
    }
    return transactions;
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnAccountId: accountId,
      columnName: name,
      columnDate: date,
      columnType: type,
      columnSubtype: subtype,
      columnAmount: amount,
      columnIsPending: isPending ? 1 : 0,
      if (classification != null) 'classification': classification,
    };
  }

  factory TransactionEntry.fromMap(Map<String, dynamic> map) {
    final t = TransactionEntry(
      id: map[columnId] as String,
      accountId: map[columnAccountId] as String,
      name: map[columnName] as String,
      date: map[columnDate] as String,
      type: map[columnType] as String,
      subtype: map[columnSubtype] as String,
      amount: (map[columnAmount] as num).toDouble(),
      isPending: map[columnIsPending] is bool
          ? map[columnIsPending] as bool
          : (map[columnIsPending] as int) == 1,
      classification: map['classification'] as String?,
    );
    if (map['customCategory'] != null) {
      t.type = map['customCategory'] as String;
    }
    if (map['isHidden'] != null) {
      t.isHidden = map['isHidden'] as bool;
    }
    return t;
  }

  TransactionEntry copy() {
    return TransactionEntry(
      id: id,
      accountId: accountId,
      name: name,
      date: date,
      type: type,
      subtype: subtype,
      amount: amount,
      isPending: isPending,
      classification: classification,
    );
  }
}
