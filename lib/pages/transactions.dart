import 'package:financial_tracker/core/basic_card.dart';
import 'package:financial_tracker/core/charts/spending_tracker.dart';
import 'package:financial_tracker/core/charts/transaction_history.dart';
import 'package:financial_tracker/core/charts/transaction_table.dart';
import 'package:financial_tracker/core/day_dropdown.dart';
import 'package:financial_tracker/core/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/models/item.dart';
import 'package:financial_tracker/models/transaction.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:financial_tracker/services/db_service.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ApiService _apiService = getIt<ApiService>();
  Iterable<MapEntry<String, (Item, Account, List<TransactionEntry>)>> _groupedTransactions = [];
  Iterable<MapEntry<String, (Item, Account, List<TransactionEntry>)>> _selectedTransactions = [];
  List<TransactionEntry> transactions = [];
  String category = 'Balance';
  bool _loading = false;
  double totalSpent = 0;
  double totalIncome = 0;
  double avgTransactions = 0;
  int totalTransactions = 0;

  _updateInfoCards() {
    totalSpent = 0;
    totalIncome = 0;
    avgTransactions = 0;
    totalTransactions = 0;

    for(final entry in _selectedTransactions) {
      for(final transaction in entry.value.$3) {
        if(transaction.amount > 0) {
          totalSpent += transaction.amount;
          totalTransactions++;
        } else {
          totalIncome += transaction.amount.abs();
        }
      }
    }

    avgTransactions = totalSpent / totalTransactions;
  }

  Future<void> _updateDays(int days) async {
    setState(() {
      _loading = true;
    });

    await _apiService.searchAccounts(context);
    await _updateTransactions();

    setState(() {
      _loading = false;
    });
  }

  void _updateTransactionGroup(String key) {
    setState(() {
      _selectedTransactions = key == '1' ? _groupedTransactions : [_groupedTransactions.firstWhere((e) => e.key == key)];
      _updateInfoCards();
    });
  }

  Future<void> _updateTransactions() async {
    final Map<String, (Item, Account, List<TransactionEntry>)> groupedTransactions = {};
    transactions = await _databaseService.getTransactions();

    for(final transaction in transactions) {
      if (transaction.accountId.isEmpty || transaction.date.isEmpty) {
        continue; 
      }

      final Account? accoount = await _databaseService.getAccountById(transaction.accountId);
      final Item? item = await _databaseService.getItemById(accoount!.itemId);

      groupedTransactions
        .putIfAbsent(transaction.accountId, () => (item!, accoount, [])).$3
        .add(transaction);
    }
    setState(() {
      _groupedTransactions = groupedTransactions.entries;
      _selectedTransactions = groupedTransactions.entries;
      _updateInfoCards();
    });
  }

  Widget categoryDropdown() {
    return IntrinsicWidth(
      child: SizedBox(
        height: 40,
        child: DropdownButtonFormField<String>(
          initialValue: category,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.onPrimary, 
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (String? newValue) {
            setState(() {
              category = newValue!;
            });
          },
          items: ['Balance', 'Spending'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
          dropdownColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _updateTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(header: 'Transactions', sub: 'Track and manage all your transactions',
            action: DayDropdown(daysUpdated: _updateDays,)),
          Expanded(child:
            _loading ? Center(child: CircularProgressIndicator()) :
            transactions.isEmpty ? Center(child: Text('No Analytics')) :
            SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IntrinsicWidth(
                        child: SizedBox(
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            initialValue: '1',
                            dropdownColor: Theme.of(context).colorScheme.onPrimary,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.onPrimary, 
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (String? key) {
                              _updateTransactionGroup(key!);
                            },
                            items: [
                              DropdownMenuItem<String>(
                                value: '1',
                                child: Text(
                                  'All Accounts',
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              ..._groupedTransactions.map<DropdownMenuItem<String>>((MapEntry<String, (Item, Account, List<TransactionEntry>)> value) {
                                return DropdownMenuItem<String>(
                                  value: value.key,
                                  child: Text(
                                    '${value.value.$1.name} - ${value.value.$2.name}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InfoCard(title: 'Total Spent', value: '\$${totalSpent.toStringAsFixed(2)}', color: Theme.of(context).colorScheme.errorContainer,),
                        InfoCard(title: 'Total Income', value: '\$${totalIncome.toStringAsFixed(2)}', color: Theme.of(context).colorScheme.primaryContainer),
                        InfoCard(title: 'Avg Transaction', value: '\$${avgTransactions.abs().toStringAsFixed(2)}'),
                        InfoCard(title: 'Total Transactions', value: totalTransactions.toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  category == 'Balance' ?
                    BasicCard(title: 'Balance History', body: TransactionHistory(groupedTransactions: _selectedTransactions), action: categoryDropdown()) :
                    BasicCard(title: 'Track Spending', body: SpendingTracker(transactions: _selectedTransactions.expand((entry) => entry.value.$3).toList()), action: categoryDropdown()),
                  BasicCard(title: 'All Transactions', 
                    body: TransactionTable(
                      transactions: _selectedTransactions.expand((entry) => entry.value.$3).toList(),
                      total: _selectedTransactions.fold(
                        0.0,
                        (double previousSum, MapEntry<String, (Item, Account, List<TransactionEntry>)> entry)
                          => previousSum + (entry.value.$2.available ?? 0).toDouble(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}