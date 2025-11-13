import 'package:financial_tracker/models/transaction.dart';
import 'package:flutter/material.dart';

class TransactionTable extends StatefulWidget {
  final double total;
  final List<TransactionEntry> transactions;

  const TransactionTable({
    super.key,
    required this.total,
    required this.transactions,
  });

  @override
  State<TransactionTable> createState() => _TransactionTableState();
}

class _TransactionTableState extends State<TransactionTable> {
  List<(TransactionEntry, double)> balanceTracker = [];

  getLabel(String value) {
    return switch(value) {
      "GENERAL_MERCHANDISE" => "Shopping",
      "FOOD_AND_DRINK" => "Food",
      "ENTERTAINMENT" => "Leisure",
      "PERSONAL_CARE" => "Personal",
      "LOAN_PAYMENTS" => "Loans",
      "TRANSPORTATION" => "Travel",
      _ => formatSnakeCaseToTitle(value)
    };
  }

  String formatSnakeCaseToTitle(String input) {
    if (input.isEmpty) return "";

    return input
      .split('_').map((word) {
        if (word.isEmpty) return "";
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);

    const List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String month = monthNames[dateTime.month - 1];
    int day = dateTime.day;
    int year = dateTime.year;

    return '$month $day, $year';
  }

  void _updateTransactions() {
    widget.transactions.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    balanceTracker = [(widget.transactions.first, widget.total)];
    for(int i = 1; i < widget.transactions.length; i++) {
      balanceTracker.add((widget.transactions[i], balanceTracker[i - 1].$2 + widget.transactions[i - 1].amount));
    }
  }

  @override
  void initState() {
    super.initState();
    
    setState(() {
      _updateTransactions();
    });
  }

  @override
  void didUpdateWidget(TransactionTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.transactions != oldWidget.transactions) {
      setState(() {
        _updateTransactions();
      });
    }
  }

  @override
    Widget build(BuildContext context) {
    return 
    SingleChildScrollView(
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Expanded(
              child: Text('Date'),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text('Merchant'),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text('Category'),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text('Amount'),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text('Balance'),
            ),
          ),
        ],
        rows: [
          ...balanceTracker.map((entry) {
            return DataRow(
              cells: <DataCell>[
                DataCell(Text(formatDate(entry.$1.date))),
                DataCell(Text(entry.$1.name)),
                DataCell(Text(getLabel(entry.$1.type))),
                DataCell(
                  Text('\$${entry.$1.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: entry.$1.amount < 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error
                    ),
                  )
                ),
                DataCell(
                  Text('${entry.$2 >= 0 ? '' : '-'}\$${entry.$2.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: entry.$2 > 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error
                    ),
                  )
                )
              ],
            );
          }),
        ],
      ),
    );
  }
}