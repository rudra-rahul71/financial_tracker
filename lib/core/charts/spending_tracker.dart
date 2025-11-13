import 'package:financial_tracker/models/transaction.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingTracker extends StatefulWidget {
  final List<TransactionEntry> transactions;

  const SpendingTracker({
    super.key,
    required this.transactions,
  });

  @override
  State<SpendingTracker> createState() => _SpendingTrackerState();
}

class _SpendingTrackerState extends State<SpendingTracker> {
  List<TransactionEntry> _transactions = [];

  void _updateTransactions() {
    setState(() {
      _transactions =  widget.transactions
        .where((transaction) => transaction.amount > 0).toList();
        
      Map<String, TransactionEntry> t = _transactions.fold(<String, TransactionEntry>{}, (Map<String, TransactionEntry> accum, TransactionEntry entry) {
        accum.update(
          entry.date,
          (existing) {
            existing.amount += entry.amount;
            return existing;
          },
          ifAbsent: () => entry.copy(),
        );
        return accum;
      });

      _transactions = t.entries.map((ent) => ent.value).toList();

      _transactions
        .sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    });
  }

  @override
  void initState() {
    super.initState();
    
    _updateTransactions();
  }

  @override
  void didUpdateWidget(SpendingTracker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.transactions != oldWidget.transactions) {
      _updateTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12), 
      ),
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: LineChart(
          LineChartData(
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 70,
                  // interval: dist / 3,
                  getTitlesWidget: (value, meta) {
                    return Text('${value >= 0 ? '' : '-'}\$${value.abs().toStringAsFixed(2)}');
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text('Day'),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 777700000000 * (ApiService.interval.toDouble() / 30),
                  getTitlesWidget: (value, meta) {
                    final int micros = value.toInt();
                    final DateTime date = DateTime.fromMicrosecondsSinceEpoch(micros);
                    final String formattedDate = '${date.month}/${date.day}';

                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideVertically: true,
                fitInsideHorizontally: true,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final DateTime date = DateTime.fromMicrosecondsSinceEpoch(touchedSpot.x.toInt());
                    final String formattedDate = '${date.month}/${date.day}';

                    final String amount = '\$${touchedSpot.y.toStringAsFixed(2)}';
                    final String body = '$formattedDate\n$amount';

                    final TextStyle textStyle = TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11
                    );

                    return LineTooltipItem(
                      body,
                      textStyle,
                      textAlign: TextAlign.left,
                    );
                  }).toList();
                }
              ),
              distanceCalculator: (touchPoint, spotPixelCoordinates) {
                return (touchPoint - spotPixelCoordinates).distance;
              },
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(FlLine(
                    strokeWidth: 0.0,
                  ), FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ));
                }).toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.1,
                color: Theme.of(context).colorScheme.primary,
                spots: [
                  ..._transactions.map((transaction) {
                    return FlSpot(DateTime.parse(transaction.date).microsecondsSinceEpoch.toDouble(), transaction.amount);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}