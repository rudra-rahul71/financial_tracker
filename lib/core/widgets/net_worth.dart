import 'package:flutter/material.dart';

class NetWorth extends StatelessWidget {
  final int totalAccounts;
  final double totalValue;

  const NetWorth({
    super.key,
    required this.totalAccounts,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 320;
          final amountFontSize = isCompact ? 24.0 : 32.0;
          final cardPadding = isCompact ? 16.0 : 24.0;
          final iconSize = isCompact ? 40.0 : 50.0;
          final iconInnerSize = isCompact ? 22.0 : 28.0;

          return Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Net Worth',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${totalValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: amountFontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Across $totalAccounts accounts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.onPrimaryFixed,
                        Theme.of(context).colorScheme.onPrimary,
                      ],
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
                  child: Center(child: Icon(Icons.show_chart, size: iconInnerSize)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
