import 'package:financial_tracker/core/day_dropdown.dart';
import 'package:financial_tracker/core/page_header.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _updateDays(int days) {
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(header: 'Home', sub: 'Your financial overview at a glance',
            action: DayDropdown(daysUpdated: _updateDays,)),
          Expanded(child: Center(child: Text('No Analytics'),))
        ],
      ),
    );
  }
}