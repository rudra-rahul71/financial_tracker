import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:financial_tracker/features/accounts/domain/entities/sync_cursor.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  DatabaseService._constructor();

  Future<Database> get database async {
    return _db != null ? _db! : await getDatabase();
  }

  Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/financial_tracker.db';
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${Item.tableName} (
            ${Item.columnId} TEXT PRIMARY KEY,
            ${Item.columnName} TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ${Account.tableName} (
            ${Account.columnId} TEXT PRIMARY KEY,
            ${Account.columnItemId} TEXT NOT NULL,
            ${Account.columnName} TEXT NOT NULL,
            ${Account.columnOfficialName} TEXT NOT NULL,
            ${Account.columnType} TEXT NOT NULL,
            ${Account.columnSubtype} TEXT NOT NULL,
            ${Account.columnAvailable} REAL,
            ${Account.columnCurrent} REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE ${TransactionEntry.tableName} (
            ${TransactionEntry.columnId} TEXT PRIMARY KEY,
            ${TransactionEntry.columnAccountId} TEXT NOT NULL,
            ${TransactionEntry.columnName} TEXT NOT NULL,
            ${TransactionEntry.columnDate} TEXT NOT NULL,
            ${TransactionEntry.columnAmount} REAL NOT NULL,
            ${TransactionEntry.columnType} TEXT NOT NULL,
            ${TransactionEntry.columnSubtype} TEXT NOT NULL,
            ${TransactionEntry.columnIsPending} INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ${SyncCursor.tableName} (
            ${SyncCursor.columnItemId} TEXT PRIMARY KEY,
            ${SyncCursor.columnNextCursor} TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE transaction_preferences (
            transaction_id TEXT PRIMARY KEY,
            custom_category TEXT,
            is_hidden INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return database;
  }

  void clearTable(String table) async {
    final db = await database;
    db.delete(table);
  }

  void updateTable(String table, dynamic value, {ConflictAlgorithm? conflictAlgorithm}) async {
    final db = await database;
    db.insert(table, value.toMap(), conflictAlgorithm: conflictAlgorithm);
  }

  void removeTransaction(String id) async {
    final db = await database;
    db.delete(
      TransactionEntry.tableName,
      where: '${TransactionEntry.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveTransactionPreference(String id, {String? category, bool? isHidden}) async {
    final db = await database;
    final existing = await db.query('transaction_preferences', where: 'transaction_id = ?', whereArgs: [id]);
    
    Map<String, dynamic> data = {'transaction_id': id};
    if (existing.isNotEmpty) {
      data = Map<String, dynamic>.from(existing.first);
    }
    
    if (category != null) data['custom_category'] = category;
    if (isHidden != null) data['is_hidden'] = isHidden ? 1 : 0;
    
    await db.insert('transaction_preferences', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> getLatestTransactionDate() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(${TransactionEntry.columnDate}) as max_date FROM ${TransactionEntry.tableName}'
    );
    if (result.isNotEmpty && result.first['max_date'] != null) {
      final dateString = result.first['max_date'] as String;
      return DateTime.tryParse(dateString);
    }
    return null;
  }

  Future<Item?> getItemById(String id) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      Item.tableName,
      where: '${Item.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Item.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<Account?> getAccountById(String id) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      Account.tableName,
      where: '${Account.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Account.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final data = await db.query(Account.tableName);
    List<Account> accounts = data
        .map((account) => Account.fromMap(account))
        .toList();
    return accounts;
  }

  Future<List<TransactionEntry>> getTransactions() async {
    final db = await database;
    final data = await db.query(TransactionEntry.tableName);
    List<TransactionEntry> transactions = data
        .map((transaction) => TransactionEntry.fromMap(transaction))
        .toList();

    try {
      final prefsData = await db.query('transaction_preferences');
      final Map<String, Map<String, dynamic>> prefsMap = {
        for (var row in prefsData)
          row['transaction_id'] as String: row
      };
      for (var t in transactions) {
        if (prefsMap.containsKey(t.id)) {
          final pref = prefsMap[t.id]!;
          if (pref['custom_category'] != null) {
            t.type = pref['custom_category'] as String;
          }
          t.isHidden = (pref['is_hidden'] as int? ?? 0) == 1;
        }
      }
    } catch (e) {
      // Ignore if table doesn't exist
    }

    return transactions;
  }

  Future<String?> getCursor(String itemId) async {
    final db = await database;
    final result = await db.query(
      SyncCursor.tableName,
      where: '${SyncCursor.columnItemId} = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first[SyncCursor.columnNextCursor] as String?;
    }
    return null;
  }

  Future<void> saveCursor(String itemId, String nextCursor) async {
    final db = await database;
    await db.insert(
      SyncCursor.tableName,
      {
        SyncCursor.columnItemId: itemId,
        SyncCursor.columnNextCursor: nextCursor,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAllCursors() async {
    final db = await database;
    final data = await db.query(SyncCursor.tableName);
    return {
      for (var row in data)
        row[SyncCursor.columnItemId] as String:
            row[SyncCursor.columnNextCursor] as String,
    };
  }
}
