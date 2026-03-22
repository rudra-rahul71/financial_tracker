import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';

class Connection {
  final List<Account> accounts;
  final List<TransactionEntry> transactions;
  final Item item;

  Connection({
    required this.accounts,
    required this.transactions,
    required this.item,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      accounts: Account.fromJsonList(json['item']['item_id'], json['accounts']),
      transactions: TransactionEntry.fromJsonList(json['transactions']),
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
