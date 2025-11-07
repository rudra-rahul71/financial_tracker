import 'package:financial_tracker/core/day_dropdown.dart';
import 'package:financial_tracker/core/page_header.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {

  int _days = 30;

  void _updateDays(int days) {
    setState(() {
      _days = days;
    });
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
          Expanded(child: Center(child: Text('No Analytics'),))
        ],
      ),
    );
  }
}