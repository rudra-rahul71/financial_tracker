import 'package:financial_tracker/core/widgets/basic_card.dart';
import 'package:financial_tracker/core/charts/category_spending.dart';
import 'package:financial_tracker/core/charts/distribution_pie.dart';
import 'package:financial_tracker/core/widgets/day_dropdown.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:financial_tracker/core/network/api_service.dart';
import 'package:financial_tracker/core/database/db_service.dart';
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
  bool _showIncome = false;

  Future<void> _updateDays(int days) async {
    setState(() {
      _loading = true;
    });

    await _apiService.searchAccounts(context);
    await _updateTransactions();
  }

  Future<void> _updateTransactions({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final Map<String, double> groupedTransactions = {};

      DateTime now = DateTime.now();
      DateTime threshold = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: ApiService.interval));

      List<TransactionEntry> allTransactions = await _databaseService
          .getTransactions(since: threshold);

      List<TransactionEntry> transactions = allTransactions;

      for (final transaction in transactions) {
        if (transaction.isHidden) continue;

        final isMatchingMode = _showIncome ? transaction.amount < 0 : transaction.amount > 0;
        if (isMatchingMode) {
          final amountValue = transaction.amount.abs();
          groupedTransactions.putIfAbsent(transaction.type, () => 0.0);

          double currentValue = groupedTransactions[transaction.type]!;
          double newValue = currentValue + amountValue;

          if (newValue == 0) {
            groupedTransactions.remove(transaction.type);
          } else {
            groupedTransactions[transaction.type] = newValue;
          }
        }
      }

      _transactionByCategory = groupedTransactions.entries.toList();
      _transactionByCategory.sort((a, b) {
        return b.value.compareTo(a.value);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
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
          PageHeader(
            header: 'Analytics',
            sub: _showIncome
                ? 'Deep insights into your income patterns'
                : 'Deep insights into your spending patterns',
            action: DayDropdown(daysUpdated: _updateDays),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Spending'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: <bool>{_showIncome},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _showIncome = newSelection.first;
                  _updateTransactions();
                });
              },
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _transactionByCategory.isEmpty
                ? Center(child: Text('No Analytics'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        BasicCard(
                          title: 'Distribution',
                          body: DistributionPieChart(
                            groupedTransactions: _transactionByCategory,
                            isIncome: _showIncome,
                          ),
                        ),
                        BasicCard(
                          title: _showIncome ? 'Income by Category' : 'Spending by Category',
                          body: CategorySpending(
                            groupedTransactions: _transactionByCategory,
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
