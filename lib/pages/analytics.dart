import 'package:financial_tracker/core/day_dropdown.dart';
import 'package:financial_tracker/core/page_header.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

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
          PageHeader(header: 'Analytics', sub: 'Deep insights into your spending patterns',
            action: DayDropdown(daysUpdated: _updateDays,)),
          Expanded(child: Center(child: Text('No Analytics'),))
        ],
      ),
    );
  }
}