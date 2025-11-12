import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DistributionPieChart extends StatefulWidget {
  final List<MapEntry<String, double>> groupedTransactions;

  const DistributionPieChart({
    super.key,
    required this.groupedTransactions,
  });

  @override
  State<DistributionPieChart> createState() => _DistributionPieChartState();
}

class _DistributionPieChartState extends State<DistributionPieChart> {
  int? _selected;

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
    final double totalValue = widget.groupedTransactions.fold(
      0.0,
      (double previousSum, MapEntry<String, double> entry) => previousSum + entry.value,
    );

    Widget getPieChart() {
      return AspectRatio(
        aspectRatio: 1,
        child: PieChart(
          PieChartData(
            // centerSpaceRadius: 0,
            sections: List.generate(widget.groupedTransactions.length, (index) {
              return PieChartSectionData(
                value: widget.groupedTransactions[index].value,
                title: '${((widget.groupedTransactions[index].value / totalValue) * 100).toStringAsFixed(2)}%',
                radius: _selected == index ? 90 : 100,
                color: Theme.of(context).colorScheme.onPrimary,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1
                ),
              );
            }),          
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent e, PieTouchResponse? r) {
                if(r != null && r.touchedSection != null) {
                  setState(() {
                    _selected = r.touchedSection!.touchedSectionIndex;
                  });
                }
              },
            )
          ),
        ),
      );
    }

    Widget getOverview() {
      return _selected != null && _selected != -1 ?
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Category: ${getLabel(widget.groupedTransactions[_selected!].key)}'),
          Text('Spent: \$${widget.groupedTransactions[_selected!].value.toStringAsFixed(2)}'),
        ]
      ) :
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Analytics Overview'),
          Text('Total Spent: \$${totalValue.toStringAsFixed(2)}'),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 500;
      
        return isNarrow ?
        Column(children: [getOverview(), const SizedBox(height: 12.0), Expanded(child: getPieChart())]) :
        Row(
          children: [
            Expanded(child: getPieChart()),
            Expanded(child: getOverview()),
          ]
        );
      }
    );
  }
}