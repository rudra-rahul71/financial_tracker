import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategorySpending extends StatelessWidget {
  final List<MapEntry<String, double>> groupedTransactions;

  const CategorySpending({
    super.key,
    required this.groupedTransactions,
  });

  getLabel(String value) {
    return switch(value) {
      "GENERAL_MERCHANDISE" => "Shopping",
      "FOOD_AND_DRINK" => "Food",
      "ENTERTAINMENT" => "Leisure",
      "PERSONAL_CARE" => "Personal",
      "LOAN_PAYMENTS" => "Loans",
      "TRANSPORTATION" => "Travel",
      _ => formatSnakeCaseToTitle(value)
    };
  }

  String formatSnakeCaseToTitle(String input) {
    if (input.isEmpty) return "";

    return input
      .split('_').map((word) {
        if (word.isEmpty) return "";
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final max = groupedTransactions[0].value;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12), 
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double chartWidth = constraints.maxWidth;
            final int numberOfIntervals = chartWidth < 350.0 ? 3 : 4;
            final double dynamicInterval = max > 0 ? max / numberOfIntervals.toDouble() : 1.0;

            return BarChart(
              BarChartData(
                rotationQuarterTurns: 1,
                borderData: FlBorderData(
                  show: false
                ),
                gridData: FlGridData(
                  show: false
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(axisNameWidget: Text('')),
                  leftTitles: AxisTitles(axisNameWidget: Text('')),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 75,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(getLabel(groupedTransactions[value.toInt()].key))
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: dynamicInterval,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text('\$${value.toStringAsFixed(0)}'),
                        );
                      },

                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(2)}',
                        TextStyle()
                      );
                    },
                  ),
                ),
                barGroups: [
                  ...groupedTransactions.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      groupVertically: true,
                      x: entry.key, 
                      barRods: [
                        BarChartRodData(
                          color: Theme.of(context).colorScheme.primary,
                          toY: entry.value.value
                        ), 
                      ],
                    );
                  }),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}