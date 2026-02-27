import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/models/item.dart';
import 'package:financial_tracker/models/transaction.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TransactionHistory extends StatefulWidget {
  final Iterable<MapEntry<String, (Item, Account, List<TransactionEntry>)>> groupedTransactions;

  const TransactionHistory({
    super.key,
    required this.groupedTransactions,
  });

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  @override
  Widget build(BuildContext context) {
    List<(Item, Account, List<TransactionEntry>)> list = [];
    DateTime now = DateTime.now();
    double maxVal = 0.0;
    double minVal = 0.0;
    double dist = 0.0;

    for(final entry in widget.groupedTransactions) {
      List<TransactionEntry> transactionList = [];
      transactionList.add(TransactionEntry(id: '', accountId: '', name: '', date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        type: '', subtype: '', amount: entry.value.$2.available ?? 0.0));
      double currentBalance = entry.value.$2.available ?? 0.0;
      maxVal = math.max(maxVal, currentBalance);
      minVal = math.min(minVal, currentBalance);
      for(final transaction in entry.value.$3) {
        TransactionEntry newEntry = transaction.copy();
        if(newEntry.date == transactionList.last.date) {
          currentBalance += newEntry.amount;
        } else {
          final temp = newEntry.amount;
          newEntry.amount = currentBalance;
          transactionList.add(newEntry);
          maxVal = math.max(maxVal, currentBalance);
          minVal = math.min(minVal, currentBalance);
          currentBalance += temp;
        }
      }

      DateTime first = now.subtract(Duration(days: ApiService.interval));
      transactionList.add(TransactionEntry(id: '', accountId: '', name: '', date: '${first.year}-${first.month.toString().padLeft(2, '0')}-${first.day.toString().padLeft(2, '0')}',
        type: '', subtype: '', amount: transactionList.last.amount));

      list.add((entry.value.$1, entry.value.$2, transactionList));
    }
    dist = maxVal - minVal;

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
                  interval: dist / 3,
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
                    (Item, Account, List<TransactionEntry>) entry = widget.groupedTransactions.toList()[touchedSpot.barIndex].value;

                    final DateTime date = DateTime.fromMicrosecondsSinceEpoch(touchedSpot.x.toInt());
                    final String formattedDate = '${date.month}/${date.day}';

                    final String amount = '\$${touchedSpot.y.toStringAsFixed(2)}';
                    final String account = '${entry.$2.name}\n';
                    final String body = '$formattedDate\n$amount';

                    final TextStyle textStyle = TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11
                    );

                    return LineTooltipItem(
                      account,
                      textStyle,
                      children: [
                        TextSpan(
                          text: '${entry.$1.name}\n',
                          style: textStyle.copyWith(fontSize: 8, fontWeight: FontWeight.normal)
                        ),
                        TextSpan(
                          text: body,
                          style: textStyle.copyWith(fontWeight: FontWeight.normal)
                        ),
                      ],
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
            ...list.map((entry) {
              return LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.1,
                color: Theme.of(context).colorScheme.primary,
                spots: [
                  ...entry.$3.map((transaction) {
                    return FlSpot(DateTime.parse(transaction.date).microsecondsSinceEpoch.toDouble(), transaction.amount);
                  }),
                ],
              );
            }),
          ],
          ),
        ),
      )
    );
  }
}