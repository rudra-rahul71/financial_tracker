import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/models/item.dart';
import 'package:financial_tracker/models/transaction.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TransactionHistory extends StatefulWidget {
  final Iterable<MapEntry<String, (Item, Account, List<TransactionEntry>)>>
  groupedTransactions;

  const TransactionHistory({super.key, required this.groupedTransactions});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  @override
  Widget build(BuildContext context) {
    List<(Item, Account, List<TransactionEntry>, Set<String>)> list = [];
    DateTime now = DateTime.now();
    double maxVal = -double.maxFinite;
    double minVal = double.maxFinite;
    double dist = 0.0;

    if (widget.groupedTransactions.isEmpty) {
      maxVal = 100.0;
      minVal = 0.0;
    }

    for (final entry in widget.groupedTransactions) {
      List<TransactionEntry> transactionList = [];
      Set<String> activeDates = {};

      double currentBalance = entry.value.$2.available ?? 0.0;
      Map<String, double> dailyTransactions = {};

      for (final transaction in entry.value.$3) {
        dailyTransactions[transaction.date] =
            (dailyTransactions[transaction.date] ?? 0.0) + transaction.amount;
        activeDates.add(transaction.date);
      }

      DateTime today = DateTime(now.year, now.month, now.day);
      double balanceTracker = currentBalance;

      for (int i = 0; i <= ApiService.interval; i++) {
        DateTime currentDay = today.subtract(Duration(days: i));
        String dateString =
            '${currentDay.year}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}';

        transactionList.add(
          TransactionEntry(
            id: '',
            accountId: '',
            name: '',
            date: dateString,
            type: '',
            subtype: '',
            amount: balanceTracker,
          ),
        );

        maxVal = math.max(maxVal, balanceTracker);
        minVal = math.min(minVal, balanceTracker);

        if (dailyTransactions.containsKey(dateString)) {
          balanceTracker += dailyTransactions[dateString]!;
        }
      }

      // Always add today to active dates so the most recent balance has a dot
      String todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      activeDates.add(todayString);

      list.add((entry.value.$1, entry.value.$2, transactionList, activeDates));
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
            minY: minVal == maxVal ? minVal - 10 : minVal - (dist * 0.1),
            maxY: minVal == maxVal ? maxVal + 10 : maxVal + (dist * 0.1),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 65,
                  interval: dist > 0 ? dist / 5 : 10.0,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) {
                      return const SizedBox.shrink();
                    }
                    final int fractionDigits = (value % 1 == 0) ? 0 : 2;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${value >= 0 ? '' : '-'}\$${value.abs().toStringAsFixed(fractionDigits)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Day',
                  style: TextStyle(fontSize: 12),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval:
                      86400000000.0 *
                      math.max(1, (ApiService.interval / 5).ceil()),
                  getTitlesWidget: (value, meta) {
                    final int micros = value.toInt();
                    final DateTime date = DateTime.fromMicrosecondsSinceEpoch(
                      micros,
                    );
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
                    var entry = list[touchedSpot.barIndex];

                    final DateTime date = DateTime.fromMicrosecondsSinceEpoch(
                      touchedSpot.x.toInt(),
                    );
                    final String formattedDate = '${date.month}/${date.day}';

                    final String amount =
                        '\$${touchedSpot.y.toStringAsFixed(2)}';
                    final String account = '${entry.$2.name}\n';
                    final String body = '$formattedDate\n$amount';

                    final TextStyle textStyle = TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    );

                    return LineTooltipItem(
                      account,
                      textStyle,
                      children: [
                        TextSpan(
                          text: '${entry.$1.name}\n',
                          style: textStyle.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: body,
                          style: textStyle.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                      textAlign: TextAlign.left,
                    );
                  }).toList();
                },
              ),
              distanceCalculator: (touchPoint, spotPixelCoordinates) {
                return (touchPoint - spotPixelCoordinates).distance;
              },
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(strokeWidth: 0.0),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  );
                }).toList();
              },
            ),
            lineBarsData: [
              ...list.map((entry) {
                final spots = entry.$3.map((transaction) {
                  return FlSpot(
                    DateTime.parse(
                      transaction.date,
                    ).microsecondsSinceEpoch.toDouble(),
                    transaction.amount,
                  );
                }).toList();

                // spots need to be sorted by x-axis for fl_chart, especially when using step lines
                spots.sort((a, b) => a.x.compareTo(b.x));

                return LineChartBarData(
                  isCurved: false,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      DateTime date = DateTime.fromMicrosecondsSinceEpoch(
                        spot.x.toInt(),
                      );
                      String dateStr =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                      // Only show dots on dates where a transaction occurred
                      if (!entry.$4.contains(dateStr)) {
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                          strokeWidth: 0,
                          strokeColor: Colors.transparent,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                  spots: spots,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
