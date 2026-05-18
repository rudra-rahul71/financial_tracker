import 'package:fl_chart/fl_chart.dart';
import 'package:financial_tracker/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class CategorySpending extends StatelessWidget {
  final List<MapEntry<String, double>> groupedTransactions;

  const CategorySpending({super.key, required this.groupedTransactions});

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
            final double dynamicInterval = max > 0
                ? max / numberOfIntervals.toDouble()
                : 1.0;

            return BarChart(
              BarChartData(
                rotationQuarterTurns: 1,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(axisNameWidget: Text('')),
                  leftTitles: AxisTitles(axisNameWidget: Text('')),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 110,
                      getTitlesWidget: (value, meta) {
                        final label = getCategoryLabel(
                          groupedTransactions[value.toInt()].key,
                        );
                        return SideTitleWidget(
                          meta: meta,
                          child: Tooltip(
                            message: label,
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                        String formatted;
                        if (value >= 1000000) {
                          formatted =
                              '${(value / 1000000).toStringAsFixed(1)}M';
                        } else if (value >= 1000) {
                          formatted = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          formatted = value.toStringAsFixed(0);
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '\$$formatted',
                            style: const TextStyle(fontSize: 10),
                          ),
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
                        TextStyle(),
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
                          toY: entry.value.value,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
