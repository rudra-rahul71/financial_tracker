import 'package:financial_tracker/core/category_card.dart';
import 'package:financial_tracker/core/day_dropdown.dart';
import 'package:financial_tracker/core/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/models/transaction.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:financial_tracker/services/db_service.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ApiService _apiService = getIt<ApiService>();
  List<MapEntry<String, double>> _transactionByCategory = [];
  bool _loading = false;

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

  Future<void> _updateTransactions() async {
    final Map<String, double> groupedTransactions = {};

    List<TransactionEntry> transactions = await _databaseService.getTransactions();
    for(final transaction in transactions) {
      if(transaction.amount > 0) {
        groupedTransactions.putIfAbsent(transaction.type, () => 0.0);

        double currentValue = groupedTransactions[transaction.type]!;
        double newValue = currentValue + transaction.amount;
          
        if (newValue == 0) {
          groupedTransactions.remove(transaction.type);
        } else {
          groupedTransactions[transaction.type] = newValue;
        }
      }
    }

    _transactionByCategory = groupedTransactions.entries.toList();

    setState(() {
      _transactionByCategory.sort((a, b) {
        return b.value.compareTo(a.value);
      });
    });
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
        children: <Widget>[
          PageHeader(header: 'Analytics', sub: 'Deep insights into your spending patterns',
            action: DayDropdown(daysUpdated: _updateDays)),
          Expanded(child:
            _loading ? Center(child: CircularProgressIndicator()) :
            _transactionByCategory.isEmpty ? Center(child: Text('No Analytics')) :
            SingleChildScrollView(
              child: Column(
                children: [
                  CategoryCard(groupedTransactions: _transactionByCategory),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}