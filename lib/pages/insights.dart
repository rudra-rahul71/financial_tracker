import 'package:financial_tracker/core/page_header.dart';
import 'package:flutter/material.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(header: 'Insights', sub: 'Personalized recommendations and financial insights'),
          Expanded(child: Center(child: Text('No Insights'),))
        ],
      ),
    );
  }
}