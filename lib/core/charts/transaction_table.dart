import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class TransactionTable extends StatefulWidget {
  final double total;
  final List<TransactionEntry> transactions;
  final Future<void> Function() onCategoryChanged;
  final String selectedCategory;
  final bool showBalance;

  const TransactionTable({
    super.key,
    required this.total,
    required this.transactions,
    required this.onCategoryChanged,
    required this.selectedCategory,
    this.showBalance = true,
  });

  @override
  State<TransactionTable> createState() => _TransactionTableState();
}

class _TransactionTableState extends State<TransactionTable> {
  List<(TransactionEntry, double)> balanceTracker = [];
  String? _updatingTransactionId;



  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);

    const List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String month = monthNames[dateTime.month - 1];
    int day = dateTime.day;
    int year = dateTime.year;

    return '$month $day, $year';
  }

  void _updateTransactions() {
    widget.transactions.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );

    if (widget.showBalance) {
      balanceTracker = [(widget.transactions.first, widget.total)];
      for (int i = 1; i < widget.transactions.length; i++) {
        balanceTracker.add((
          widget.transactions[i],
          balanceTracker[i - 1].$2 + widget.transactions[i - 1].amount,
        ));
      }
    } else {
      balanceTracker = widget.transactions.map((t) => (t, 0.0)).toList();
    }
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _updateTransactions();
    });
  }

  @override
  void didUpdateWidget(TransactionTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.transactions != oldWidget.transactions) {
      setState(() {
        _updateTransactions();
      });
    }
  }

  void _editCategory(TransactionEntry transaction) async {
    final Set<String> baseCategories = {
      'INCOME',
      'TRANSFER_IN',
      'TRANSFER_OUT',
      'LOAN_PAYMENTS',
      'BANK_FEES',
      'ENTERTAINMENT',
      'FOOD_AND_DRINK',
      'GENERAL_MERCHANDISE',
      'HOME_IMPROVEMENT',
      'MEDICAL',
      'PERSONAL_CARE',
      'GENERAL_SERVICES',
      'GOVERNMENT_AND_NON_PROFIT',
      'TRANSPORTATION',
      'TRAVEL',
      'RENT_AND_UTILITIES',
    };
    baseCategories.addAll(widget.transactions.map((t) => t.type));

    final categories = baseCategories.toList();
    categories.sort();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String newCategory = '';
        bool isCustom = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Category'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCustom)
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ...categories.map(
                              (c) => ListTile(
                                title: Text(getCategoryLabel(c)),
                                onTap: () => Navigator.pop(context, c),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Add Custom Category...'),
                              onTap: () {
                                setState(() {
                                  isCustom = true;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Custom Category',
                          hintText: 'e.g. Small Business',
                        ),
                        onChanged: (val) => newCategory = val,
                        onSubmitted: (val) {
                          if (val.isNotEmpty) {
                            Navigator.pop(
                              context,
                              val.toUpperCase().replaceAll(' ', '_'),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                if (isCustom)
                  TextButton(
                    onPressed: () {
                      if (newCategory.isNotEmpty) {
                        Navigator.pop(
                          context,
                          newCategory.toUpperCase().replaceAll(' ', '_'),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;
      setState(() {
        _updatingTransactionId = transaction.id;
      });
      try {
        await DatabaseService.instance.saveTransactionPreference(
          transaction.id,
          category: result,
        );
        await widget.onCategoryChanged();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update category: $e'),
            backgroundColor: errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _updatingTransactionId = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<(TransactionEntry, double)>> groupedTransactions = {};
    for (var entry in balanceTracker) {
      if (widget.selectedCategory != 'All Categories' && entry.$1.type != widget.selectedCategory) {
        continue;
      }
      String date = formatDate(entry.$1.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(entry);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...groupedTransactions.entries.map((group) {
            String date = group.key;
            var entries = group.value;
            double eodBalance = entries.first.$2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (widget.showBalance) ...[
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            'Final Balance: ${eodBalance >= 0 ? '' : '-'}\$${eodBalance.abs().toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: eodBalance > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...entries.map((entry) {
                  final isUpdating = _updatingTransactionId == entry.$1.id;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isUpdating ? 0.5 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUpdating
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.15)
                            : null,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.$1.name +
                                      (entry.$1.isPending ? ' (Pending)' : ''),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: entry.$1.isPending
                                        ? FontStyle.italic
                                        : null,
                                    color: entry.$1.isPending
                                        ? Theme.of(context).colorScheme.onSurface
                                              .withValues(alpha: 0.6)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  getCategoryLabel(entry.$1.type),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${entry.$1.amount.abs().toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: entry.$1.amount < 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: isUpdating
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _editCategory(entry.$1);
                                      } else if (value == 'hide' || value == 'unhide') {
                                        final isHidden = value == 'hide';
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        final errorColor = Theme.of(context).colorScheme.error;
                                        setState(() {
                                          _updatingTransactionId = entry.$1.id;
                                        });
                                        try {
                                          await DatabaseService.instance
                                              .saveTransactionPreference(
                                                entry.$1.id,
                                                isHidden: isHidden,
                                              );
                                          await widget.onCategoryChanged();
                                        } catch (e) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to update preference: $e'),
                                              backgroundColor: errorColor,
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _updatingTransactionId = null;
                                            });
                                          }
                                        }
                                      }
                                    },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Category'),
                                    ),
                                    PopupMenuItem(
                                      value: entry.$1.isHidden ? 'unhide' : 'hide',
                                      child: Text(
                                        entry.$1.isHidden
                                            ? 'Unhide from Analytics'
                                            : 'Hide from Analytics',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ],
            );
          }),
        ],
      ),
    );
  }
}
