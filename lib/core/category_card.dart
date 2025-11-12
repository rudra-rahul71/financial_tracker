import 'package:financial_tracker/core/charts/category_spending.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  final List<MapEntry<String, double>> groupedTransactions;

  const CategoryCard({
    super.key,
    required this.groupedTransactions,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Spending by Category'),
            const SizedBox(height: 12.0),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: CategorySpending(groupedTransactions: widget.groupedTransactions),
            )
          ],
        ),
      ),
    );
  }
}