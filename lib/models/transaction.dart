class TransactionEntry {
  String id, accountId, name, date, type, subtype;
  double amount;

  static const String tableName = 'transactions';
  static const String columnId = 'id';
  static const String columnAccountId = 'account_id';
  static const String columnName = 'name';
  static const String columnDate = 'date';
  static const String columnType = 'type';
  static const String columnSubtype = 'subtype';
  static const String columnAmount = 'amount';


  TransactionEntry({
    required this.id,
    required this.accountId,
    required this.name,
    required this.date,
    required this.type,
    required this.subtype,
    required this.amount
  });

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['transaction_id'],
      accountId: json['account_id'],
      name: json['name'],
      date: json['date'],
      type: json['personal_finance_category']['primary'],
      subtype: json['personal_finance_category']['detailed'],
      amount: (json['amount'] as num).toDouble()
    );
  }

  static List<TransactionEntry> fromJsonList(List<dynamic> jsonList) {
    final List<TransactionEntry> transactions = [];
    for(final account in jsonList) {
      transactions.add(TransactionEntry.fromJson(account));
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
    };
  }

  factory TransactionEntry.fromMap(Map<String, dynamic> map) {
    return TransactionEntry(
      id: map[columnId] as String,
      accountId: map[columnAccountId] as String,
      name: map[columnName] as String,
      date: map[columnDate] as String,
      type: map[columnType] as String,
      subtype: map[columnSubtype] as String,
      amount: (map[columnAmount] as num).toDouble()
    );
  }
}