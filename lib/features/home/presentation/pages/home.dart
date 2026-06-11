import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService.instance;

  bool _loading = true;
  List<dynamic> _recentTransactions = [];
  double _thisMonthSpending = 0.0;
  double _lastMonthSpending = 0.0;
  double _twoMonthsAgoSpending = 0.0;
  double _spendingPercentChange = 0.0;
  double _projectedThisMonthSpending = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      // Fetch Recent Transactions (take latest 4, unsorted from DB, we sort client-side)
      final allTransactions = await _databaseService.getTransactions();
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      _recentTransactions = allTransactions.where((t) => !t.isHidden).take(4).toList();

      // Calculate spending for this month, last month, and the month before (month-to-date)
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      final currentDay = now.day;

      final lastMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear;
      final lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;

      final twoMonthsAgoYear = lastMonth == 1 ? lastMonthYear - 1 : lastMonthYear;
      final twoMonthsAgo = lastMonth == 1 ? 12 : lastMonth - 1;

      double thisMonthSum = 0.0;
      double lastMonthSum = 0.0;
      double twoMonthsAgoSum = 0.0;

      // Variables to store current month's sub-categories for projection:
      double thisMonthFixed = 0.0;
      double thisMonthVariable = 0.0;
      double thisMonthOneOff = 0.0;

      for (final tx in allTransactions) {
        if (tx.isHidden) continue;
        if (tx.amount <= 0) continue; // spending is amount > 0

        final tDate = DateTime.tryParse(tx.date);
        if (tDate == null) continue;

        if (tDate.year == currentYear && tDate.month == currentMonth) {
          // Compare this month up to the current day of the month
          if (tDate.day <= currentDay) {
            thisMonthSum += tx.amount;

            // Separate for projection
            final classification = tx.billingClassification;
            if (classification == 'fixed') {
              thisMonthFixed += tx.amount;
            } else if (classification == 'one_off') {
              thisMonthOneOff += tx.amount;
            } else {
              thisMonthVariable += tx.amount;
            }
          }
        } else if (tDate.year == lastMonthYear && tDate.month == lastMonth) {
          // Compare last month up to the same day of the month
          if (tDate.day <= currentDay) {
            lastMonthSum += tx.amount;
          }
        } else if (tDate.year == twoMonthsAgoYear && tDate.month == twoMonthsAgo) {
          // Compare month before last up to the same day of the month
          if (tDate.day <= currentDay) {
            twoMonthsAgoSum += tx.amount;
          }
        }
      }

      _thisMonthSpending = thisMonthSum;
      _lastMonthSpending = lastMonthSum;
      _twoMonthsAgoSpending = twoMonthsAgoSum;

      // Calculate Projected EOM spending using the hybrid model:
      final totalDaysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
      final double projectedVariable = currentDay > 0
          ? (thisMonthVariable / currentDay) * totalDaysInMonth
          : 0.0;
      _projectedThisMonthSpending = thisMonthFixed + thisMonthOneOff + projectedVariable;

      if (lastMonthSum > 0) {
        _spendingPercentChange = ((thisMonthSum - lastMonthSum) / lastMonthSum) * 100;
      } else {
        _spendingPercentChange = 0.0;
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showProjectionInfoDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Spending Calculations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This card compares your spending month-over-month and projects your end-of-month (EOM) total.',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 16),
                _buildInfoDetail(
                  title: '📅 Month-to-Date (MTD)',
                  description: 'Compares your actual spending from day 1 up to today against previous months for the exact same date range. This ensures a fair comparison mid-month.',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildInfoDetail(
                  title: '📈 Projected EOM',
                  description: 'Estimated total spending by the end of the month. To prevent skewing, it uses a hybrid calculation:\n\n'
                      'Formula:\n'
                      'Projected = Fixed + One-Off + ((Variable / Current Day) * Days in Month)\n\n'
                      '• 🔄 Fixed Bills (Rent, Utilities) & ⚡ One-Off purchases are added flat (no run-rate scaling).\n'
                      '• 📈 Variable Spending (Dining, Shopping) is projected linearly based on your current daily spending pace.',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildInfoDetail(
                  title: '👁️ Hidden Transactions',
                  description: 'Any transaction marked as "Hidden from Analytics" is excluded from all counts and will not affect the actual or projected EOM totals.',
                  theme: theme,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoDetail({
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingInsightCard(ThemeData theme) {
    final bool hasLastMonth = _lastMonthSpending > 0;
    final bool isSavings = _spendingPercentChange < 0;
    final percentChangeAbs = _spendingPercentChange.abs();

    Color trendColor;
    IconData trendIcon;
    String trendText;

    if (_spendingPercentChange == 0.0) {
      trendColor = Colors.grey;
      trendIcon = Icons.trending_flat_rounded;
      trendText = 'No change';
    } else if (isSavings) {
      trendColor = Colors.greenAccent;
      trendIcon = Icons.trending_down_rounded;
      trendText = '${percentChangeAbs.toStringAsFixed(1)}% less';
    } else {
      trendColor = Colors.orangeAccent;
      trendIcon = Icons.trending_up_rounded;
      trendText = '${percentChangeAbs.toStringAsFixed(1)}% more';
    }

    // Determine the ratio between the three months for progress bars
    // To avoid overflow, we normalize them to a max of 1.0.
    double maxSpending = _thisMonthSpending;
    if (_lastMonthSpending > maxSpending) maxSpending = _lastMonthSpending;
    if (_twoMonthsAgoSpending > maxSpending) maxSpending = _twoMonthsAgoSpending;
    if (maxSpending <= 0) maxSpending = 1.0;

    final double thisMonthRatio = _thisMonthSpending / maxSpending;
    final double lastMonthRatio = _lastMonthSpending / maxSpending;
    final double twoMonthsAgoRatio = _twoMonthsAgoSpending / maxSpending;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(51),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                ),
                    const SizedBox(width: 8),
                    const Text(
                      'Spending Insight',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
                  onPressed: () => _showProjectionInfoDialog(context, theme),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${_thisMonthSpending.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasLastMonth
                            ? 'vs. \$${_lastMonthSpending.toStringAsFixed(2)} same period last month'
                            : 'No spending recorded last month',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.online_prediction_rounded,
                            size: 14,
                            color: theme.colorScheme.primary.withAlpha(200),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Projected EOM: \$${_projectedThisMonthSpending.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasLastMonth) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: trendColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: trendColor.withAlpha(51),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendIcon,
                          color: trendColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendText,
                          style: TextStyle(
                            color: trendColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Comparison Bars
            Column(
              children: [
                // This Month Bar
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'This Month',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: thisMonthRatio,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
                          color: theme.colorScheme.primary,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${_thisMonthSpending.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Last Month Bar
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Last Month',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: lastMonthRatio,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
                          color: theme.colorScheme.onSurface.withAlpha(128),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${_lastMonthSpending.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withAlpha(200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Month Before Bar
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        '2 Months Ago',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: twoMonthsAgoRatio,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
                          color: theme.colorScheme.onSurface.withAlpha(76),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${_twoMonthsAgoSpending.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              wrapAction: false,
              showProfileButton: true,
              header: 'Overview',
              sub: 'Your financial health at a glance',
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              _buildSpendingInsightCard(theme),
                              const SizedBox(height: 20),
                              
                              // Recent Transactions section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Transactions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/transactions'),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('View All'),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_recentTransactions.isEmpty)
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.colorScheme.outlineVariant.withAlpha(51),
                                    ),
                                  ),
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(15),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                                          SizedBox(height: 12),
                                          Text(
                                            'No transactions found',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Connect a bank account to sync transactions.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.colorScheme.outlineVariant.withAlpha(51),
                                    ),
                                  ),
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(15),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _recentTransactions.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                                    itemBuilder: (context, index) {
                                      final tx = _recentTransactions[index];
                                      final isExpense = tx.amount > 0;
                                      final amountText = isExpense
                                          ? '-\$${tx.amount.toStringAsFixed(2)}'
                                          : '+\$${tx.amount.abs().toStringAsFixed(2)}';
                                      
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isExpense
                                              ? theme.colorScheme.errorContainer.withAlpha(25)
                                              : theme.colorScheme.primaryContainer.withAlpha(25),
                                          child: Icon(
                                            isExpense ? Icons.shopping_bag_outlined : Icons.monetization_on_outlined,
                                            color: isExpense
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          tx.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          '${getCategoryLabel(tx.type)} • ${tx.date}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        trailing: Text(
                                          amountText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isExpense
                                                ? theme.colorScheme.error
                                                : Colors.green,
                                          ),
                                        ),
                                        onTap: () => context.go('/transactions'),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
