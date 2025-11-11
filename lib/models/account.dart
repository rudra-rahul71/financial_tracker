class Account {
  String id, itemId, name, officialName, type, subetype;
  double? available, current;

  static const String tableName = 'accounts';
  static const String columnId = 'id';
  static const String columnItemId = 'item_id';
  static const String columnName = 'name';
  static const String columnOfficialName = 'official_name';
  static const String columnType = 'type';
  static const String columnSubtype = 'subtype';
  static const String columnAvailable = 'available';
  static const String columnCurrent = 'current';

  Account({
    required this.id,
    required this.itemId,
    required this.name,
    required this.officialName,
    required this.type,
    required this.subetype,
    this.available,
    this.current
  });

  factory Account.fromJson(String itemId, Map<String, dynamic> json) {
    return Account(
      id: json['account_id'],
      itemId: itemId,
      name: json['name'],
      officialName: json['official_name'],
      type: json['type'],
      subetype: json['subtype'],
      available: (json['balances']['available'] as num).toDouble(),
      current: (json['balances']['current'] as num).toDouble()
    );
  }

  static List<Account> fromJsonList(String itemId, List<dynamic> jsonList) {
    final List<Account> accounts = [];
    for(final account in jsonList) {
      accounts.add(Account.fromJson(itemId, account));
    }
    return accounts;
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnItemId: itemId,
      columnName: name, 
      columnOfficialName: officialName,
      columnType: type,
      columnSubtype: subetype,
      columnAvailable: available,
      columnCurrent: current
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map[columnId] as String,
      itemId: map[columnItemId] as String,
      name: map[columnName] as String,
      officialName: map[columnOfficialName] as String,
      type: map[columnType] as String,
      subetype: map[columnSubtype] as String,
      available: (map[columnAvailable] as num).toDouble(),
      current: (map[columnCurrent] as num).toDouble(),
    );
  }
}