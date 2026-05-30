import 'package:fl_chart/fl_chart.dart';
import 'package:financial_tracker/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class DistributionPieChart extends StatefulWidget {
  final List<MapEntry<String, double>> groupedTransactions;
  final bool isIncome;

  const DistributionPieChart({
    super.key,
    required this.groupedTransactions,
    this.isIncome = false,
  });

  @override
  State<DistributionPieChart> createState() => _DistributionPieChartState();
}

class _DistributionPieChartState extends State<DistributionPieChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final double totalValue = widget.groupedTransactions.fold(
      0.0,
      (double previousSum, MapEntry<String, double> entry) =>
          previousSum + entry.value,
    );

    Widget getPieChart() {
      return AspectRatio(
        aspectRatio: 1,
        child: PieChart(
          PieChartData(
            // centerSpaceRadius: 0,
            sections: List.generate(widget.groupedTransactions.length, (index) {
              double percentage =
                  (widget.groupedTransactions[index].value / totalValue) * 100;
              return PieChartSectionData(
                value: widget.groupedTransactions[index].value,
                title: '${percentage.toStringAsFixed(2)}%',
                showTitle: percentage >= 5.0,
                radius: _selected == index ? 90 : 100,
                color: Theme.of(context).colorScheme.onPrimary,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              );
            }),
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent e, PieTouchResponse? r) {
                if (r != null && r.touchedSection != null) {
                  setState(() {
                    _selected = r.touchedSection!.touchedSectionIndex;
                  });
                }
              },
            ),
          ),
        ),
      );
    }

    Widget getOverview() {
      final valueLabel = widget.isIncome ? 'Received' : 'Spent';
      final totalLabel = widget.isIncome ? 'Total Income' : 'Total Spent';
      return _selected != null && _selected != -1
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Category: ${getCategoryLabel(widget.groupedTransactions[_selected!].key)}',
                ),
                Text(
                  '$valueLabel: \$${widget.groupedTransactions[_selected!].value.toStringAsFixed(2)}',
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Analytics Overview'),
                Text('$totalLabel: \$${totalValue.toStringAsFixed(2)}'),
              ],
            );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 500;

        return isNarrow
            ? Column(
                children: [
                  getOverview(),
                  const SizedBox(height: 12.0),
                  Expanded(child: getPieChart()),
                ],
              )
            : Row(
                children: [
                  Expanded(child: getPieChart()),
                  Expanded(child: getOverview()),
                ],
              );
      },
    );
  }
}
