import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/models/item.dart';
import 'package:financial_tracker/models/transaction.dart';
// import 'package:financial_tracker/models/transaction.dart';
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
            ${TransactionEntry.columnSubtype} TEXT NOT NULL
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

  void updateTable(String table, dynamic value) async {
    final db = await database;
    db.insert(table, value.toMap());
  }

  Future<List<Item>> getItems() async {
    final db = await database;
    final data = await db.query(Item.tableName);
    List<Item> items = data.map(
      (e) => Item(id: e["id"] as String, name: e["name"] as String)
    ).toList();
    return items;
  }
}