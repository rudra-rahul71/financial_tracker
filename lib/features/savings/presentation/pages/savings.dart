import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/savings/domain/entities/savings_bucket.dart';
import 'package:financial_tracker/features/savings/domain/entities/savings_goal.dart';
import 'package:flutter/material.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final DatabaseService _db = DatabaseService.instance;

  List<SavingsGoal> _goals = [];
  List<SavingsBucket> _buckets = [];
  List<Account> _allAccounts = [];
  List<String> _selectedAccountIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final goals = await _db.getSavingsGoals();
      final buckets = await _db.getSavingsBuckets();
      final accounts = await _db.getAccounts();
      final savedSelections = await _db.getSavingsSelectedAccountIds();

      // Set state and compute defaults if needed
      _goals = goals;
      _buckets = buckets;
      _allAccounts = accounts;

      if (savedSelections.isEmpty) {
        // Default to all depository (checking and savings) accounts
        _selectedAccountIds = _allAccounts
            .where((a) => a.type.toLowerCase() == 'depository')
            .map((a) => a.id)
            .toList();

        // If no depository accounts are found, default to all accounts
        if (_selectedAccountIds.isEmpty) {
          _selectedAccountIds = _allAccounts.map((a) => a.id).toList();
        }
        await _db.saveSavingsSelectedAccountIds(_selectedAccountIds);
      } else {
        _selectedAccountIds = savedSelections;
      }
    } catch (e) {
      debugPrint('Error loading savings data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Helper formatter for currencies
  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final String basic = absAmount.toStringAsFixed(0);
    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    buffer.write('\$');

    final length = basic.length;
    for (int i = 0; i < length; i++) {
      buffer.write(basic[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  // Calculated properties
  double get _totalSavingsPool {
    double total = 0.0;
    for (final account in _allAccounts) {
      if (_selectedAccountIds.contains(account.id)) {
        total += account.current ?? account.available ?? 0.0;
      }
    }
    return total;
  }

  double get _totalAllocated {
    double total = 0.0;
    for (final goal in _goals) {
      total += goal.currentAmount;
    }
    for (final bucket in _buckets) {
      total += bucket.currentAmount;
    }
    return total;
  }

  double get _unallocatedAmount => _totalSavingsPool - _totalAllocated;

  // Account Selector Dialog
  void _showAccountSelector() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final depositoryAccounts = _allAccounts
                .where((a) => a.type.toLowerCase() == 'depository')
                .toList();

            Widget buildAccountRow(Account account) {
              final isChecked = _selectedAccountIds.contains(account.id);
              final balance = account.current ?? account.available ?? 0.0;

              return CheckboxListTile(
                title: Text(
                  account.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${account.officialName.isNotEmpty ? account.officialName : account.subetype} • ${_formatCurrency(balance)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                value: isChecked,
                activeColor: Colors.greenAccent,
                onChanged: (bool? checked) async {
                  if (checked == true) {
                    _selectedAccountIds.add(account.id);
                  } else {
                    _selectedAccountIds.remove(account.id);
                  }
                  setModalState(() {});
                  setState(() {});
                  await _db.saveSavingsSelectedAccountIds(_selectedAccountIds);
                },
              );
            }

            return AlertDialog(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Savings Pool Config'),
                  TextButton(
                    onPressed: () async {
                      final depositoryIds = depositoryAccounts
                          .map((a) => a.id)
                          .toList();
                      if (_selectedAccountIds.length == depositoryIds.length) {
                        _selectedAccountIds.clear();
                      } else {
                        _selectedAccountIds = List.from(depositoryIds);
                      }
                      setModalState(() {});
                      setState(() {});
                      await _db.saveSavingsSelectedAccountIds(
                        _selectedAccountIds,
                      );
                    },
                    child: Text(
                      _selectedAccountIds.length == depositoryAccounts.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select checking and savings accounts whose balances make up the savings pool.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 24),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [...depositoryAccounts.map(buildAccountRow)],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Interactive Goal Creator / Editor Dialog (Scenario Planner)
  void _showGoalDialog({SavingsGoal? goal}) {
    final isEdit = goal != null;
    final titleController = TextEditingController(text: goal?.title ?? '');
    final targetController = TextEditingController(
      text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '',
    );
    final monthlyController = TextEditingController(
      text: goal != null ? goal.monthlyContribution.toStringAsFixed(0) : '100',
    );

    bool hasDeadline = goal?.deadline != null;
    DateTime? selectedDeadline = goal?.deadline;
    double monthlyContribution = goal?.monthlyContribution ?? 100.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final targetAmount = double.tryParse(targetController.text) ?? 0.0;
            final currentAmount = goal?.currentAmount ?? 0.0;
            final remainingAmount = (targetAmount - currentAmount).clamp(
              0.0,
              double.infinity,
            );

            // Dynamically calculate needed monthly contribution when deadline is set
            if (hasDeadline) {
              if (selectedDeadline != null && remainingAmount > 0) {
                final double daysDiff = selectedDeadline!
                    .difference(DateTime.now())
                    .inDays
                    .toDouble();
                final double months = daysDiff > 0
                    ? (daysDiff / 30.4)
                    : (1.0 / 30.4);
                monthlyContribution = remainingAmount / months;
              } else {
                monthlyContribution = 0.0;
              }
            }

            // Scenario calculations for non-deadline case
            int monthsToTarget = 0;
            DateTime? projectedDate;

            if (!hasDeadline &&
                remainingAmount > 0 &&
                monthlyContribution > 0) {
              monthsToTarget = (remainingAmount / monthlyContribution).ceil();
              projectedDate = DateTime.now().add(
                Duration(days: (monthsToTarget * 30.4).round()),
              );
            }

            Future<void> selectDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDeadline ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) {
                setDialogState(() {
                  selectedDeadline = picked;
                });
              }
            }

            return AlertDialog(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              title: Text(isEdit ? 'Edit Savings Goal' : 'New Savings Goal'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Goal Title',
                          hintText: 'e.g., House Down Payment, Vacation',
                        ),
                        onChanged: (val) {
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target Amount',
                          prefixText: '\$ ',
                        ),
                        onChanged: (val) {
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      // Deadline switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Set Goal Deadline?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: hasDeadline,
                            activeThumbColor: Colors.greenAccent,
                            onChanged: (val) async {
                              setDialogState(() {
                                hasDeadline = val;
                                if (!val) {
                                  monthlyController.text = monthlyContribution
                                      .toStringAsFixed(0);
                                }
                              });
                              if (val && selectedDeadline == null) {
                                await selectDate();
                              }
                            },
                          ),
                        ],
                      ),
                      if (hasDeadline) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDeadline != null
                                  ? 'Target Date: ${selectedDeadline!.month}/${selectedDeadline!.day}/${selectedDeadline!.year}'
                                  : 'No Date Selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedDeadline != null
                                    ? theme.colorScheme.onSurface
                                    : Colors.orangeAccent,
                                fontWeight: selectedDeadline != null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: selectDate,
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                selectedDeadline != null ? 'Change' : 'Select',
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!hasDeadline) ...[
                        const Divider(height: 32),
                        // Monthly contribution slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Monthly Savings Plan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: monthlyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  prefixText: '\$ ',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.greenAccent,
                                ),
                                onChanged: (val) {
                                  final amount = double.tryParse(val) ?? 0.0;
                                  setDialogState(() {
                                    monthlyContribution = amount;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: monthlyContribution.clamp(
                            10.0,
                            targetAmount > 10
                                ? targetAmount.clamp(10.0, 5000.0)
                                : 1000.0,
                          ),
                          min: 10.0,
                          max: targetAmount > 10
                              ? targetAmount.clamp(10.0, 5000.0)
                              : 1000.0,
                          activeColor: Colors.greenAccent,
                          inactiveColor:
                              theme.colorScheme.surfaceContainerHighest,
                          onChanged: (val) {
                            setDialogState(() {
                              monthlyContribution = val.roundToDouble();
                              monthlyController.text = monthlyContribution
                                  .toStringAsFixed(0);
                            });
                          },
                        ),
                      ],
                      if (hasDeadline) const SizedBox(height: 16),
                      // Scenario Planner Helper Box
                      if (targetAmount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(128),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.query_stats_rounded,
                                    color: Colors.greenAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Projection Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (hasDeadline) ...[
                                if (selectedDeadline != null) ...[
                                  Text(
                                    'To reach your goal of ${_formatCurrency(targetAmount)} by ${selectedDeadline!.month}/${selectedDeadline!.day}/${selectedDeadline!.year}, you need to save:',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _formatCurrency(monthlyContribution),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                      const Text(
                                        ' / month',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const Text(
                                    'Please select a deadline to calculate the required monthly savings.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Text(
                                  'It will take $monthsToTarget months to reach your target.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (projectedDate != null) ...[
                                  Text(
                                    'Estimated completion: ${projectedDate.month}/${projectedDate.year}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      titleController.text.trim().isEmpty ||
                          targetAmount <= 0 ||
                          (hasDeadline && selectedDeadline == null)
                      ? null
                      : () async {
                          final currentAmount = goal?.currentAmount ?? 0.0;
                          final savedGoal = SavingsGoal(
                            id: goal?.id ?? '',
                            title: titleController.text.trim(),
                            targetAmount: targetAmount,
                            currentAmount: currentAmount,
                            deadline: hasDeadline ? selectedDeadline : null,
                            monthlyContribution: monthlyContribution,
                            createdAt: goal?.createdAt ?? DateTime.now(),
                          );
                          final navigator = Navigator.of(context);
                          await _db.saveSavingsGoal(savedGoal);
                          navigator.pop();
                          _loadData();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEdit ? 'Save Goal' : 'Create Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Bucket Creator / Editor Dialog
  void _showBucketDialog({SavingsBucket? bucket}) {
    final isEdit = bucket != null;
    final titleController = TextEditingController(text: bucket?.title ?? '');

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          title: Text(isEdit ? 'Edit Savings Bucket' : 'New Savings Bucket'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Bucket Name',
              hintText: 'e.g., General Savings, Christmas Fund',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final savedBucket = SavingsBucket(
                    id: bucket?.id ?? '',
                    title: title,
                    currentAmount: bucket?.currentAmount ?? 0.0,
                    createdAt: bucket?.createdAt ?? DateTime.now(),
                  );
                  final navigator = Navigator.of(context);
                  await _db.saveSavingsBucket(savedBucket);
                  navigator.pop();
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              child: Text(isEdit ? 'Save Bucket' : 'Create Bucket'),
            ),
          ],
        );
      },
    );
  }

  // Manual Transfer (Allocate / Withdraw Funds)
  void _showTransferDialog({SavingsGoal? goal, SavingsBucket? bucket}) {
    final isGoal = goal != null;
    final String title = isGoal ? goal.title : bucket!.title;
    final double maxWithdrawal = isGoal
        ? goal.currentAmount
        : bucket!.currentAmount;

    bool isAllocating = true; // Allocate TO vs Withdraw FROM
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              title: Text('Manage Funds: $title'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Allocate In'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Withdraw Out'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                    ],
                    selected: {isAllocating},
                    onSelectionChanged: (val) {
                      setDialogState(() {
                        isAllocating = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAllocating
                        ? 'Transfer money from the Unallocated Pool into this virtual pot.'
                        : 'Move money out of this virtual pot back to the Unallocated Pool.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAllocating ? 'Available Pool:' : 'Available in Pot:',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        isAllocating
                            ? _formatCurrency(_unallocatedAmount)
                            : _formatCurrency(maxWithdrawal),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAllocating
                              ? (_unallocatedAmount < 0
                                    ? Colors.redAccent
                                    : Colors.greenAccent)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Transfer Amount',
                      prefixText: '\$ ',
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (double.tryParse(amountController.text) ?? 0.0) <= 0 ||
                          (!isAllocating &&
                              (double.tryParse(amountController.text) ?? 0.0) >
                                  maxWithdrawal)
                      ? null
                      : () async {
                          final double amount =
                              double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0) return;
                          final navigator = Navigator.of(context);

                          if (isAllocating) {
                            // Deduct from unallocated, add to goal/bucket
                            if (isGoal) {
                              final updated = goal.copyWith(
                                currentAmount: goal.currentAmount + amount,
                              );
                              await _db.saveSavingsGoal(updated);
                            } else {
                              final updated = bucket!.copyWith(
                                currentAmount: bucket.currentAmount + amount,
                              );
                              await _db.saveSavingsBucket(updated);
                            }
                          } else {
                            // Withdraw from goal/bucket, return to unallocated pool
                            if (amount > maxWithdrawal) return;

                            if (isGoal) {
                              final updated = goal.copyWith(
                                currentAmount: goal.currentAmount - amount,
                              );
                              await _db.saveSavingsGoal(updated);
                            } else {
                              final updated = bucket!.copyWith(
                                currentAmount: bucket.currentAmount - amount,
                              );
                              await _db.saveSavingsBucket(updated);
                            }
                          }
                          navigator.pop();
                          _loadData();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Confirm Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete Confirmation
  void _showDeleteConfirmDialog({SavingsGoal? goal, SavingsBucket? bucket}) {
    final isGoal = goal != null;
    final String title = isGoal ? goal.title : bucket!.title;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          title: const Text('Delete Virtual Pot?'),
          content: Text(
            'Are you sure you want to delete "$title"? Any allocated savings in this pot will be returned to the Unallocated Pool.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (isGoal) {
                  await _db.deleteSavingsGoal(goal.id);
                } else {
                  await _db.deleteSavingsBucket(bucket!.id);
                }
                navigator.pop();
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasDeficit = _unallocatedAmount < 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            showBackButton: true,
            header: 'Savings Goals',
            sub: 'Track and plan your long-term savings goals',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      side: BorderSide(
                        color: hasDeficit
                            ? Colors.redAccent.withAlpha(128)
                            : theme.colorScheme.outlineVariant.withAlpha(51),
                        width: 1.5,
                      ),
                    ),
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL SAVINGS POOL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(_totalSavingsPool),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton.filledTonal(
                                onPressed: _showAccountSelector,
                                icon: const Icon(
                                  Icons.settings_suggest_rounded,
                                ),
                                tooltip: 'Configure Savings Pool Accounts',
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ALLOCATED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(_totalAllocated),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1.5,
                                height: 36,
                                color: theme.colorScheme.outlineVariant
                                    .withAlpha(100),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UNALLOCATED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(_unallocatedAmount),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: hasDeficit
                                            ? Colors.redAccent
                                            : Colors.greenAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (hasDeficit) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withAlpha(38),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.redAccent.withAlpha(128),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Overallocated! Your virtual pots exceed your physical account balances by ${_formatCurrency(_unallocatedAmount.abs())}. Please withdraw money from pots to balance.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Savings Goals Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Savings Goals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showGoalDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Goal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHigh,
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Goals List
                  if (_goals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(51),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No Savings Goals created yet.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final ratio = (goal.currentAmount / goal.targetAmount)
                            .clamp(0.0, 1.0);
                        final percent = (ratio * 100).toStringAsFixed(0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withAlpha(
                                51,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goal.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showGoalDialog(goal: goal);
                                        } else if (val == 'delete') {
                                          _showDeleteConfirmDialog(goal: goal);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit Goal'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Goal'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_formatCurrency(goal.currentAmount)} saved',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Goal: ${_formatCurrency(goal.targetAmount)} ($percent%)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: ratio,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.greenAccent,
                                      ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (goal.deadline != null)
                                            Text(
                                              'Target Date: ${goal.deadline!.month}/${goal.deadline!.year}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          Text(
                                            'Saving Plan: ${_formatCurrency(goal.monthlyContribution)}/mo',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _showTransferDialog(goal: goal),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Transfer'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  // Savings Buckets Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Savings Buckets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showBucketDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Bucket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHigh,
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Buckets List
                  if (_buckets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(51),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No Savings Buckets created yet.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _buckets.length,
                      itemBuilder: (context, index) {
                        final bucket = _buckets[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withAlpha(
                                51,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.folder_special_rounded,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bucket.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Balance: ${_formatCurrency(bucket.currentAmount)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          _showTransferDialog(bucket: bucket),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Transfer'),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showBucketDialog(bucket: bucket);
                                        } else if (val == 'delete') {
                                          _showDeleteConfirmDialog(
                                            bucket: bucket,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit Bucket'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Bucket'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
