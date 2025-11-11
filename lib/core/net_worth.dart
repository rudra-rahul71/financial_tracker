import 'package:flutter/material.dart';

class NetWorth extends StatelessWidget {
  final int totalAccounts;
  final double totalValue;

  const NetWorth({
    super.key,
    required this.totalAccounts,
    required this.totalValue
  });

  @override
  Widget build(BuildContext context) {
    final Color dark = Theme.of(context).colorScheme.onPrimary;
    final Color light = Theme.of(context).colorScheme.onPrimaryFixed;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Net Worth',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$$totalValue',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Across $totalAccounts accounts',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [light, dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onPrimaryFixedVariant,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.show_chart,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}