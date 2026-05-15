import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';

class Connection {
  final List<Account> accounts;
  final List<TransactionEntry> added;
  final List<TransactionEntry> modified;
  final List<String> removed;
  final String nextCursor;
  final Item item;

  Connection({
    required this.accounts,
    required this.added,
    required this.modified,
    required this.removed,
    required this.nextCursor,
    required this.item,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    List<String> parseRemoved(List<dynamic>? list) {
      if (list == null) return [];
      return list.map((e) => e['transaction_id'] as String).toList();
    }

    return Connection(
      accounts: Account.fromJsonList(json['item']['item_id'], json['accounts'] ?? []),
      added: TransactionEntry.fromJsonList(json['added'] ?? []),
      modified: TransactionEntry.fromJsonList(json['modified'] ?? []),
      removed: parseRemoved(json['removed'] as List<dynamic>?),
      nextCursor: json['next_cursor'] as String? ?? '',
      item: Item.fromJson(json['item']),
    );
  }

  static List<Connection> fromJsonList(List<dynamic> jsonList) {
    final List<Connection> connections = [];
    for (final connection in jsonList) {
      connections.add(Connection.fromJson(connection));
    }
    return connections;
  }
}
