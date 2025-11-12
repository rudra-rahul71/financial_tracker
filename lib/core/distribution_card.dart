import 'package:financial_tracker/core/charts/distribution_pie.dart';
import 'package:flutter/material.dart';

class DistributionCard extends StatefulWidget {
  final List<MapEntry<String, double>> groupedTransactions;

  const DistributionCard({
    super.key,
    required this.groupedTransactions,
  });

  @override
  State<DistributionCard> createState() => _DistributionCardState();
}

class _DistributionCardState extends State<DistributionCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Distribution'),
            const SizedBox(height: 12.0),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: DistributionPieChart(groupedTransactions: widget.groupedTransactions),
            )
          ],
        ),
      ),
    );
  }
}