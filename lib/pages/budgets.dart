import 'package:financial_tracker/core/page_header.dart';
import 'package:flutter/material.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(header: 'Budgets', sub: 'Set and track your spending limits', 
            action: ElevatedButton.icon(
              onPressed: () {
                  // Handle add account action
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Create Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Theme.of(context).colorScheme.inverseSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Expanded(child: Center(child:
           Text('No Budgets'),
           ))
        ],
      ),
    );
  }
}