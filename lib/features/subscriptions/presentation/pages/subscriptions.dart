import 'package:financial_tracker/core/network/api_service.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = getIt<ApiService>();
  late TabController _tabController;

  bool _loading = true;
  List<dynamic> _inflows = [];
  List<dynamic> _outflows = [];

  double _totalMonthlyOutflow = 0.0;
  int _activeOutflowsCount = 0;
  int _upcomingRenewalsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await _apiService.getRecurringTransactions(context);
      if (data != null) {
        _inflows = data['inflow_streams'] ?? [];
        _outflows = data['outflow_streams'] ?? [];
        _calculateMetrics();
      }
    } catch (e) {
      debugPrint('Error fetching recurring transactions: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _calculateMetrics() {
    double monthlyTotal = 0.0;
    int activeCount = 0;
    int upcomingCount = 0;

    final now = DateTime.now();
    final fortnightFromNow = now.add(const Duration(days: 14));

    for (final outflow in _outflows) {
      final bool isActive = outflow['is_active'] == true;
      if (isActive) {
        activeCount++;
      }

      // Normalize amount to monthly spend
      final double rawAmount = _parseAmount(outflow['average_amount']?['amount']).abs();
      final String frequency = (outflow['frequency'] ?? '').toString().toLowerCase();

      double monthlyAmount = 0.0;
      if (isActive) {
        switch (frequency) {
          case 'monthly':
            monthlyAmount = rawAmount;
            break;
          case 'weekly':
            monthlyAmount = rawAmount * 4.33;
            break;
          case 'biweekly':
            monthlyAmount = rawAmount * 2.16;
            break;
          case 'semimonthly':
            monthlyAmount = rawAmount * 2.0;
            break;
          case 'yearly':
            monthlyAmount = rawAmount / 12.0;
            break;
          default:
            monthlyAmount = rawAmount; // Fallback to raw amount
        }
        monthlyTotal += monthlyAmount;
      }

      // Check for upcoming renewals in next 14 days
      final String? nextDateStr = _safeString(outflow['predicted_next_date']);
      if (nextDateStr != null && nextDateStr.isNotEmpty) {
        final nextDate = DateTime.tryParse(nextDateStr);
        if (nextDate != null &&
            nextDate.isAfter(now.subtract(const Duration(days: 1))) &&
            nextDate.isBefore(fortnightFromNow)) {
          upcomingCount++;
        }
      }
    }

    setState(() {
      _totalMonthlyOutflow = monthlyTotal;
      _activeOutflowsCount = activeCount;
      _upcomingRenewalsCount = upcomingCount;
    });
  }

  double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Color _getBrandColor(String name) {
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final double hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.65, 0.75).toColor();
  }

  String _getFrequencyLabel(String freq) {
    if (freq.isEmpty) return 'Recurring';
    return freq[0].toUpperCase() + freq.substring(1).toLowerCase();
  }

  String? _safeString(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    if (val is Map) {
      return val['String'] as String?;
    }
    return val.toString();
  }

  String _getStreamName(dynamic stream) {
    final String merchant = _safeString(stream['merchant_name']) ?? '';
    if (merchant.trim().isNotEmpty) return merchant;
    final String desc = _safeString(stream['description']) ?? '';
    if (desc.trim().isNotEmpty) return desc;
    return 'Recurring Item';
  }

  String _formatDate(String? dateStr, {bool includeYear = true}) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthInt = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        if (monthInt >= 1 && monthInt <= 12) {
          final month = months[monthInt - 1];
          final dayStr = day.toString().padLeft(2, '0');
          return includeYear ? '$month $dayStr, $year' : '$month $dayStr';
        }
      }
    } catch (_) {}
    return dateStr;
  }

  void _showStreamDetails(dynamic stream, bool isInflow) {
    final String titleName = _getStreamName(stream);
    final double avgAmount = _parseAmount(stream['average_amount']?['amount']).abs();
    final double lastAmount = _parseAmount(stream['last_amount']?['amount']).abs();
    final String frequency = stream['frequency'] ?? 'Unknown';
    final String status = stream['status'] ?? 'Unknown';
    final String? category = stream['personal_finance_category']?['primary'];
    final String? nextDateStr = _safeString(stream['predicted_next_date']);
    final bool isActive = stream['is_active'] == true;
    final List<dynamic> txIds = stream['transaction_ids'] ?? [];

    final theme = Theme.of(context);
    final brandColor = _getBrandColor(titleName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(76),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withAlpha(153),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: brandColor.withAlpha(38),
                    child: Text(
                      titleName.isNotEmpty ? titleName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category != null)
                          Text(
                            category.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withAlpha(38)
                          : Colors.red.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Amount Overview Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStatCard(
                      'Average Amount',
                      '\$${avgAmount.toStringAsFixed(2)}',
                      theme,
                      isInflow: isInflow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailStatCard(
                      'Last Amount',
                      '\$${lastAmount.toStringAsFixed(2)}',
                      theme,
                      isInflow: isInflow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Info Details List
              _buildInfoRow('Frequency', _getFrequencyLabel(frequency), Icons.repeat, theme),
              _buildInfoRow('Status', status.toUpperCase(), Icons.info_outline, theme),
              if (nextDateStr != null && nextDateStr.isNotEmpty)
                _buildInfoRow(
                  isInflow ? 'Predicted Next Deposit' : 'Predicted Next Payment',
                  _formatDate(nextDateStr, includeYear: true),
                  Icons.calendar_today_outlined,
                  theme,
                ),
              _buildInfoRow('Associated Transactions', '${txIds.length} payments tracked', Icons.receipt_long_outlined, theme),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStatCard(String label, String value, ThemeData theme, {required bool isInflow}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(76),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isInflow ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withAlpha(204)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String header,
    String subHeader,
    String value,
    Color accentColor,
    ThemeData theme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(76),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subHeader,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.subscriptions_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Subscriptions Tracked Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your bank account to automatically extract and track Netflix, Spotify, software tools, utility bills, and other recurring items.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/accounts');
              },
              icon: const Icon(Icons.account_balance, size: 18),
              label: const Text('Go to Accounts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamsList(
    List<dynamic> streams,
    bool isInflow,
    ThemeData theme,
  ) {
    if (streams.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: streams.length,
      itemBuilder: (context, index) {
        final stream = streams[index];
        final String name = _getStreamName(stream);
        final double rawAmount = _parseAmount(stream['average_amount']?['amount']).abs();
        final String frequency = stream['frequency'] ?? '';
        final bool isActive = stream['is_active'] == true;
        final String? nextDateStr = _safeString(stream['predicted_next_date']);

        final String freqLabel = frequency.isNotEmpty
            ? frequency.toLowerCase()
            : 'recurring';
        final String renewalText = nextDateStr != null && nextDateStr.isNotEmpty
            ? 'Renews: ${_formatDate(nextDateStr, includeYear: false)}'
            : 'Renewal: N/A';

        final Color brandColor = _getBrandColor(name);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(51),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: () => _showStreamDetails(stream, isInflow),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: brandColor.withAlpha(38),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _getFrequencyLabel(freqLabel),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isActive &&
                                nextDateStr != null &&
                                nextDateStr.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withAlpha(153),
                                  ),
                                ),
                              ),
                              Text(
                                renewalText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${rawAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isInflow
                              ? Colors.green
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withAlpha(25)
                              : Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              PageHeader(
                header: 'Subscriptions & Bills',
                sub:
                    'Track monthly recurring outflows, subscriptions, and inflows.',
                action: IconButton(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Sync Subscriptions',
                ),
              ),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_inflows.isEmpty && _outflows.isEmpty)
                Expanded(child: _buildEmptyState(theme))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Summary Stats row
                          Row(
                            children: [
                              _buildMetricCard(
                                'MONTHLY SPEND',
                                'Total active bills',
                                '\$${_totalMonthlyOutflow.toStringAsFixed(2)}',
                                theme.colorScheme.primary,
                                theme,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricCard(
                                'ACTIVE SUBS',
                                'Direct streams detected',
                                '$_activeOutflowsCount',
                                Colors.green,
                                theme,
                              ),
                              const SizedBox(width: 8),
                              _buildMetricCard(
                                'UPCOMING (14D)',
                                'Renewals in 2 weeks',
                                '$_upcomingRenewalsCount',
                                Colors.amber,
                                theme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Tab Bar
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(76),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withAlpha(76),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: theme.colorScheme.onPrimary,
                              unselectedLabelColor:
                                  theme.colorScheme.onSurfaceVariant,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Subscriptions & Bills'),
                                Tab(text: 'Recurring Inflows'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // List section based on tab selection
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              if (_tabController.index == 0) {
                                return _buildStreamsList(
                                  _outflows,
                                  false,
                                  theme,
                                );
                              } else {
                                return _buildStreamsList(_inflows, true, theme);
                              }
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
