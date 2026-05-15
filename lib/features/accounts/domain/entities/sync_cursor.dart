class SyncCursor {
  final String itemId;
  final String nextCursor;

  static const String tableName = 'cursors';
  static const String columnItemId = 'item_id';
  static const String columnNextCursor = 'next_cursor';

  SyncCursor({
    required this.itemId,
    required this.nextCursor,
  });
}
