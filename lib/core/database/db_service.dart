import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:financial_tracker/features/accounts/domain/entities/sync_cursor.dart';
import 'package:financial_tracker/features/budgets/domain/entities/budget.dart';
import 'package:financial_tracker/features/savings/domain/entities/savings_goal.dart';
import 'package:financial_tracker/features/savings/domain/entities/savings_bucket.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();

  DatabaseService._constructor() {
    _firestore.settings = const Settings(persistenceEnabled: false);
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> clearAllData() async {
    try {
      // Safely terminate the active Firestore instance to clear persistence
      await _firestore.terminate();
      await _firestore.clearPersistence();
    } catch (e) {
      // In case persistence is already cleared or not initialized
    }
  }

  void updateTable(
    String table,
    dynamic value, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection(table)
        .doc(value.id);

    // Using merge to preserve custom fields (customCategory, isHidden) on Plaid updates
    await docRef.set(value.toMap(), SetOptions(merge: true));
  }

  void removeTransaction(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection(TransactionEntry.tableName)
        .doc(id)
        .delete();
  }

  Future<void> saveTransactionPreference(
    String id, {
    String? category,
    bool? isHidden,
    String? classification,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User is not logged in');
    }

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection(TransactionEntry.tableName)
        .doc(id);

    await docRef.set({
      if (category != null) 'customCategory': category,
      if (isHidden != null) 'isHidden': isHidden,
      if (classification != null) 'classification': classification,
    }, SetOptions(merge: true));
  }

  Future<DateTime?> getLatestTransactionDate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(TransactionEntry.tableName)
        .orderBy(TransactionEntry.columnDate, descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty &&
        querySnapshot.docs.first.data()[TransactionEntry.columnDate] != null) {
      final dateString =
          querySnapshot.docs.first.data()[TransactionEntry.columnDate]
              as String;
      return DateTime.tryParse(dateString);
    }
    return null;
  }

  Future<Item?> getItemById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection(Item.tableName)
        .doc(id)
        .get();

    if (doc.exists && doc.data() != null) {
      return Item.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<Item>> getItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(Item.tableName)
        .get();

    return querySnapshot.docs.map((doc) => Item.fromMap(doc.data())).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection(Account.tableName)
        .doc(id)
        .get();

    if (doc.exists && doc.data() != null) {
      return Account.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<Account>> getAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(Account.tableName)
        .get();

    return querySnapshot.docs
        .map((doc) => Account.fromMap(doc.data()))
        .toList();
  }

  Future<List<TransactionEntry>> getTransactions({DateTime? since}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(uid)
        .collection(TransactionEntry.tableName);

    // Optimized server-side filtering
    if (since != null) {
      final dateStr = since.toIso8601String().split('T')[0];
      query = query.where(
        TransactionEntry.columnDate,
        isGreaterThanOrEqualTo: dateStr,
      );
    }

    final querySnapshot = await query.get();

    return querySnapshot.docs
        .map(
          (doc) => TransactionEntry.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<String?> getCursor(String itemId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection(SyncCursor.tableName)
        .doc(itemId)
        .get();

    if (doc.exists && doc.data() != null) {
      return doc.data()![SyncCursor.columnNextCursor] as String?;
    }
    return null;
  }

  Future<void> saveCursor(String itemId, String nextCursor) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection(SyncCursor.tableName)
        .doc(itemId)
        .set({
          SyncCursor.columnItemId: itemId,
          SyncCursor.columnNextCursor: nextCursor,
        }, SetOptions(merge: true));
  }

  Future<Map<String, String>> getAllCursors() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(SyncCursor.tableName)
        .get();

    return {
      for (var doc in querySnapshot.docs)
        doc.id: doc.data()[SyncCursor.columnNextCursor] as String,
    };
  }

  Future<List<Budget>> getBudgets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(Budget.tableName)
        .get();

    return querySnapshot.docs.map((doc) => Budget.fromMap(doc.data())).toList();
  }

  Future<void> saveBudget(Budget budget) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection(Budget.tableName)
        .doc(budget.id.isEmpty ? null : budget.id);

    final id = budget.id.isEmpty ? docRef.id : budget.id;
    final updatedBudget = budget.copyWith(id: id);

    await docRef.set(updatedBudget.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteBudget(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection(Budget.tableName)
        .doc(id)
        .delete();
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(SavingsGoal.tableName)
        .get();

    return querySnapshot.docs
        .map((doc) => SavingsGoal.fromMap(doc.data()))
        .toList();
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection(SavingsGoal.tableName)
        .doc(goal.id.isEmpty ? null : goal.id);

    final id = goal.id.isEmpty ? docRef.id : goal.id;
    final updatedGoal = goal.copyWith(id: id);

    await docRef.set(updatedGoal.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSavingsGoal(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection(SavingsGoal.tableName)
        .doc(id)
        .delete();
  }

  Future<List<SavingsBucket>> getSavingsBuckets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(SavingsBucket.tableName)
        .get();

    return querySnapshot.docs
        .map((doc) => SavingsBucket.fromMap(doc.data()))
        .toList();
  }

  Future<void> saveSavingsBucket(SavingsBucket bucket) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection(SavingsBucket.tableName)
        .doc(bucket.id.isEmpty ? null : bucket.id);

    final id = bucket.id.isEmpty ? docRef.id : bucket.id;
    final updatedBucket = bucket.copyWith(id: id);

    await docRef.set(updatedBucket.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSavingsBucket(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection(SavingsBucket.tableName)
        .doc(id)
        .delete();
  }

  Future<List<String>> getSavingsSelectedAccountIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('savings_config')
        .doc('config')
        .get();

    if (doc.exists && doc.data() != null) {
      final list = doc.data()!['selectedAccountIds'] as List<dynamic>?;
      if (list != null) {
        return list.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<void> saveSavingsSelectedAccountIds(List<String> accountIds) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savings_config')
        .doc('config')
        .set({'selectedAccountIds': accountIds}, SetOptions(merge: true));
  }

  Future<void> updateAccountName(String accountId, String customName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection(Account.tableName)
        .doc(accountId)
        .update({Account.columnCustomName: customName});
  }
}
