import 'package:financial_tracker/core/widgets/basic_card.dart';
import 'package:financial_tracker/core/charts/spending_tracker.dart';
import 'package:financial_tracker/core/charts/transaction_history.dart';
import 'package:financial_tracker/core/charts/transaction_table.dart';
import 'package:financial_tracker/core/widgets/date_filter_dropdown.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:financial_tracker/core/network/api_service.dart';
import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ApiService _apiService = getIt<ApiService>();
  Iterable<MapEntry<String, (Item, Account, List<TransactionEntry>)>>
  _groupedTransactions = [];
  Iterable<MapEntry<String, (Item, Account, List<TransactionEntry>)>>
  _selectedTransactions = [];
  Set<String> _selectedAccountKeys = {};
  List<TransactionEntry> transactions = [];
  String category = 'Balance';
  String tableCategory = 'All Categories';
  bool _loading = false;
  double totalSpent = 0;
  double totalIncome = 0;
  double avgTransactions = 0;
  int totalTransactions = 0;

  _updateInfoCards() {
    totalSpent = 0;
    totalIncome = 0;
    avgTransactions = 0;
    totalTransactions = 0;

    for (final entry in _selectedTransactions) {
      for (final transaction in entry.value.$3) {
        if (transaction.isHidden) continue;

        if (transaction.amount > 0) {
          totalSpent += transaction.amount;
          totalTransactions++;
        } else {
          totalIncome += transaction.amount.abs();
        }
      }
    }

    avgTransactions = totalTransactions > 0
        ? totalSpent / totalTransactions
        : 0;
  }

  Future<void> _updateDateFilter(DateFilter filter) async {
    ApiService.setDateFilter(filter);
    setState(() {
      _loading = true;
    });

    await _apiService.searchAccounts(context);
    if (!mounted) return;
    await _updateTransactions();
  }

  void _toggleAccountSelection(String key) {
    setState(() {
      if (_selectedAccountKeys.contains(key)) {
        _selectedAccountKeys.remove(key);
      } else {
        _selectedAccountKeys.add(key);
      }
      _selectedTransactions = _groupedTransactions.where(
        (e) => _selectedAccountKeys.contains(e.key),
      );
      _updateInfoCards();
    });
  }

  void _selectAllAccounts() {
    setState(() {
      _selectedAccountKeys = _groupedTransactions.map((e) => e.key).toSet();
      _selectedTransactions = _groupedTransactions;
      _updateInfoCards();
    });
  }

  void _clearAllAccounts() {
    setState(() {
      _selectedAccountKeys.clear();
      _selectedTransactions = [];
      _updateInfoCards();
    });
  }

  Future<void> _updateTransactions({bool showLoader = true}) async {
    if (showLoader) {
      if (!mounted) return;
      setState(() {
        _loading = true;
      });
    }

    try {
      final Map<String, (Item, Account, List<TransactionEntry>)>
      groupedTransactions = {};

      final dateRange = ApiService.currentFilter.getDateTimeRange();
      final threshold = dateRange.start;

      // Fetch all required data in parallel once
      final results = await Future.wait([
        _databaseService.getTransactions(since: threshold),
        _databaseService.getAccounts(),
        _databaseService.getItems(),
      ]);

      if (!mounted) return;

      List<TransactionEntry> allTransactions =
          results[0] as List<TransactionEntry>;
      List<Account> accounts = results[1] as List<Account>;
      List<Item> items = results[2] as List<Item>;

      // Create high-performance in-memory lookup maps
      final Map<String, Account> accountMap = {for (var a in accounts) a.id: a};
      final Map<String, Item> itemMap = {for (var i in items) i.id: i};

      transactions = allTransactions.where((t) {
        final tDate = DateTime.tryParse(t.date);
        if (tDate == null) return false;
        return tDate.isBefore(dateRange.end.add(const Duration(seconds: 1)));
      }).toList();

      for (final transaction in transactions) {
        if (transaction.accountId.isEmpty) {
          continue;
        }

        final Account? accoount = accountMap[transaction.accountId];
        if (accoount == null) continue;

        final Item? item = itemMap[accoount.itemId];
        if (item == null) continue;

        groupedTransactions
            .putIfAbsent(transaction.accountId, () => (item, accoount, []))
            .$3
            .add(transaction);
      }
      setState(() {
        _groupedTransactions = groupedTransactions.entries;
        if (_selectedAccountKeys.isEmpty) {
          _selectedAccountKeys = groupedTransactions.keys.toSet();
        } else {
          _selectedAccountKeys = _selectedAccountKeys.intersection(
            groupedTransactions.keys.toSet(),
          );
          if (_selectedAccountKeys.isEmpty && groupedTransactions.isNotEmpty) {
            _selectedAccountKeys = groupedTransactions.keys.toSet();
          }
        }
        _selectedTransactions = _groupedTransactions.where(
          (e) => _selectedAccountKeys.contains(e.key),
        );
        _updateInfoCards();
      });
    } finally {
      if (showLoader) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    }
  }

  Widget categoryDropdown() {
    return IntrinsicWidth(
      child: SizedBox(
        height: 40,
        child: DropdownButtonFormField<String>(
          initialValue: category,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (String? newValue) {
            setState(() {
              category = newValue!;
            });
          },
          items: ['Balance', 'Spending'].map<DropdownMenuItem<String>>((
            String value,
          ) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          dropdownColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget tableCategoryDropdown() {
    List<String> categoryList =
        _selectedTransactions
            .expand((entry) => entry.value.$3)
            .map((t) => t.type)
            .toSet()
            .toList()
          ..sort();
    categoryList.insert(0, 'All Categories');

    if (!categoryList.contains(tableCategory)) {
      tableCategory = 'All Categories';
    }

    return IntrinsicWidth(
      child: SizedBox(
        height: 40,
        child: DropdownButtonFormField<String>(
          initialValue: tableCategory,
          isExpanded: true,
          icon: const Icon(Icons.filter_list, size: 20),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (String? newValue) {
            setState(() {
              tableCategory = newValue!;
            });
          },
          items: categoryList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value == 'All Categories' ? value : getCategoryLabel(value),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          dropdownColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _showMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Select Accounts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _selectAllAccounts();
                              });
                            },
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text(
                              'Select All',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _clearAllAccounts();
                              });
                            },
                            icon: const Icon(Icons.deselect, size: 16),
                            label: const Text(
                              'Clear All',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView(
                          shrinkWrap: true,
                          children: _groupedTransactions.map((entry) {
                            final key = entry.key;
                            final isSelected = _selectedAccountKeys.contains(
                              key,
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3)
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  '${entry.value.$1.name} - ${entry.value.$2.name}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: isSelected,
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                onChanged: (bool? checked) {
                                  setDialogState(() {
                                    _toggleAccountSelection(key);
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget accountSelector() {
    String label;
    if (_selectedAccountKeys.length == _groupedTransactions.length &&
        _groupedTransactions.isNotEmpty) {
      label = 'All Accounts';
    } else if (_selectedAccountKeys.isEmpty) {
      label = 'No Accounts';
    } else if (_selectedAccountKeys.length == 1) {
      final selectedEntry = _groupedTransactions.firstWhere(
        (e) => _selectedAccountKeys.contains(e.key),
      );
      label = '${selectedEntry.value.$1.name} - ${selectedEntry.value.$2.name}';
    } else {
      label = '${_selectedAccountKeys.length} Accounts';
    }

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _showMultiSelectDialog,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _updateTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(
            showProfileButton: true,
            wrapAction: false,
            header: 'Transactions',
            sub: 'Track and manage all your transactions',
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? Center(child: Text('No Analytics'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DateFilterDropdown(
                              initialFilter: ApiService.currentFilter,
                              filterUpdated: _updateDateFilter,
                            ),
                            const SizedBox(width: 12),
                            accountSelector(),
                          ],
                        ),
                        SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InfoCard(
                                title: 'Total Spent',
                                value: '\$${totalSpent.toStringAsFixed(2)}',
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                              ),
                              InfoCard(
                                title: 'Total Income',
                                value: '\$${totalIncome.toStringAsFixed(2)}',
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                              InfoCard(
                                title: 'Avg Transaction',
                                value:
                                    '\$${avgTransactions.abs().toStringAsFixed(2)}',
                              ),
                              InfoCard(
                                title: 'Total Transactions',
                                value: totalTransactions.toString(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        category == 'Balance'
                            ? BasicCard(
                                title: 'Balance History',
                                body: TransactionHistory(
                                  groupedTransactions: _selectedTransactions,
                                ),
                                action: categoryDropdown(),
                              )
                            : BasicCard(
                                title: 'Track Spending',
                                body: SpendingTracker(
                                  transactions: _selectedTransactions
                                      .expand((entry) => entry.value.$3)
                                      .toList(),
                                ),
                                action: categoryDropdown(),
                              ),
                        BasicCard(
                          title: 'All Transactions',
                          action: tableCategoryDropdown(),
                          body: TransactionTable(
                            selectedCategory: tableCategory,
                            showBalance: _selectedTransactions.length == 1,
                            transactions: _selectedTransactions
                                .expand((entry) => entry.value.$3)
                                .toList(),
                            total: _selectedTransactions.length == 1
                                ? (_selectedTransactions
                                              .first
                                              .value
                                              .$2
                                              .available ??
                                          0)
                                      .toDouble()
                                : 0.0,
                            onCategoryChanged: () async {
                              await _updateTransactions(showLoader: false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
