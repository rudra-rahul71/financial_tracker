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
