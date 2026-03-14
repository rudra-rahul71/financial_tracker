class Item {
  final String id, name;

  static const String tableName = 'items';
  static const String columnId = 'id';
  static const String columnName = 'name';

  Item({
    required this.id,
    required this.name,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['item_id'],
      name: json['institution_name']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnName: name, 
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map[columnId] as String,
      name: map[columnName] as String,
    );
  }
}