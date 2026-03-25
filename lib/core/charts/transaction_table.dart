import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
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
    return switch (value) {
      "GENERAL_MERCHANDISE" => "Shopping",
      "FOOD_AND_DRINK" => "Food",
      "ENTERTAINMENT" => "Leisure",
      "PERSONAL_CARE" => "Personal",
      "LOAN_PAYMENTS" => "Loans",
      "TRANSPORTATION" => "Travel",
      _ => formatSnakeCaseToTitle(value),
    };
  }

  String formatSnakeCaseToTitle(String input) {
    if (input.isEmpty) return "";

    return input
        .split('_')
        .map((word) {
          if (word.isEmpty) return "";
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);

    const List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String month = monthNames[dateTime.month - 1];
    int day = dateTime.day;
    int year = dateTime.year;

    return '$month $day, $year';
  }

  void _updateTransactions() {
    widget.transactions.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );

    balanceTracker = [(widget.transactions.first, widget.total)];
    for (int i = 1; i < widget.transactions.length; i++) {
      balanceTracker.add((
        widget.transactions[i],
        balanceTracker[i - 1].$2 + widget.transactions[i - 1].amount,
      ));
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
    Map<String, List<(TransactionEntry, double)>> groupedTransactions = {};
    for (var entry in balanceTracker) {
      String date = formatDate(entry.$1.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(entry);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DefaultTextStyle(
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Merchant')),
                  Expanded(flex: 2, child: Text('Category')),
                  Expanded(
                    flex: 1,
                    child: Text('Amount', textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          ...groupedTransactions.entries.map((group) {
            String date = group.key;
            var entries = group.value;
            double eodBalance = entries.first.$2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Final Balance: ${eodBalance >= 0 ? '' : '-'}\$${eodBalance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: eodBalance > 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                ...entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.$1.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            getLabel(entry.$1.type),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '\$${entry.$1.amount.abs().toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              color: entry.$1.amount < 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}
