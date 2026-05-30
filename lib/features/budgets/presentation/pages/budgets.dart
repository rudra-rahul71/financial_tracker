import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/features/budgets/domain/entities/budget.dart';
import 'package:financial_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:financial_tracker/core/utils/formatters.dart';
import 'package:financial_tracker/core/utils/snackbar.dart';
import 'package:flutter/material.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Budget> _budgets = [];
  List<TransactionEntry> _transactions = [];
  bool _loading = true;

  // Onboarding Form Controller/State
  String? _onboardingCategory;
  final TextEditingController _onboardingCustomCategoryController = TextEditingController();
  final TextEditingController _onboardingLimitController = TextEditingController();
  bool _onboardingIsCustom = false;
  bool _onboardingLimitFocused = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _onboardingCustomCategoryController.dispose();
    _onboardingLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final budgets = await _databaseService.getBudgets();
      
      // Load recent transactions to calculate budget spending
      DateTime now = DateTime.now();
      DateTime threshold = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 30));
      
      final transactions = await _databaseService.getTransactions(since: threshold);

      setState(() {
        _budgets = budgets;
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        SnackbarService(context).showErrorSnackbar(
          message: 'Failed to load budgets data: $e',
        );
      }
    }
  }

  double _calculateSpent(String category) {
    double spent = 0.0;
    for (final t in _transactions) {
      if (t.isHidden) continue;
      // Filter by positive amount (spending) and matching category
      if (t.type == category && t.amount > 0) {
        spent += t.amount;
      }
    }
    return spent;
  }

  Set<String> _getAvailableCategories() {
    final Set<String> categories = {
      'FOOD_AND_DRINK',
      'ENTERTAINMENT',
      'GENERAL_MERCHANDISE',
      'PERSONAL_CARE',
      'TRAVEL',
      'TRANSPORTATION',
      'RENT_AND_UTILITIES',
      'HOME_IMPROVEMENT',
      'MEDICAL',
      'GENERAL_SERVICES',
    };
    for (final t in _transactions) {
      if (t.type.isNotEmpty) {
        categories.add(t.type);
      }
    }
    // Remove categories that are already budgeted to avoid duplicate budgets
    for (final b in _budgets) {
      categories.remove(b.category);
    }
    return categories;
  }

  Future<void> _addBudget({
    required String category,
    required double limit,
  }) async {
    final newBudget = Budget(
      id: '', // Firestore will auto-generate
      category: category,
      limitAmount: limit,
    );

    await _databaseService.saveBudget(newBudget);
    await _loadData();

    if (mounted) {
      SnackbarService(context).showSuccessSnackbar(
        message: 'Budget for ${getCategoryLabel(category)} successfully created!',
      );
    }
  }

  Future<void> _editBudget(Budget budget, double newLimit) async {
    final updated = budget.copyWith(limitAmount: newLimit);
    await _databaseService.saveBudget(updated);
    await _loadData();

    if (mounted) {
      SnackbarService(context).showSuccessSnackbar(
        message: 'Budget updated successfully!',
      );
    }
  }

  Future<void> _deleteBudget(String id, String categoryLabel) async {
    await _databaseService.deleteBudget(id);
    await _loadData();

    if (mounted) {
      SnackbarService(context).showSuccessSnackbar(
        message: 'Deleted budget for $categoryLabel.',
      );
    }
  }

  void _showCreateDialog() {
    final availableCategories = _getAvailableCategories();
    String? selectedCategory = availableCategories.isNotEmpty ? availableCategories.first : null;
    bool isCustom = false;
    final customCategoryController = TextEditingController();
    final limitController = TextEditingController();
    bool createLimitFocused = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Create New Budget',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: isCustom ? 'CUSTOM_OPTION' : selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: Theme.of(context).colorScheme.onPrimary,
                      items: [
                        ...availableCategories.map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(getCategoryLabel(c), style: const TextStyle(fontSize: 14)),
                            )),
                        const DropdownMenuItem<String>(
                          value: 'CUSTOM_OPTION',
                          child: Text('+ Add Custom Category...', style: TextStyle(fontSize: 14, color: Colors.greenAccent)),
                        ),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == 'CUSTOM_OPTION') {
                            isCustom = true;
                          } else {
                            isCustom = false;
                            selectedCategory = val;
                          }
                        });
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Custom Category Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: customCategoryController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g., Subscriptions',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Monthly Limit Amount',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Focus(
                      onFocusChange: (hasFocus) {
                        setStateDialog(() {
                          createLimitFocused = hasFocus;
                        });
                      },
                      child: TextField(
                        controller: limitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: createLimitFocused || limitController.text.isNotEmpty ? '\$ ' : null,
                          hintText: createLimitFocused ? '500.00' : null,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final limitText = limitController.text.trim();
                    final double? limit = double.tryParse(limitText);

                    if (limit == null || limit <= 0) {
                      SnackbarService(context).showErrorSnackbar(
                        message: 'Please enter a valid monthly limit amount.',
                      );
                      return;
                    }

                    String categoryKey = '';
                    if (isCustom) {
                      final customName = customCategoryController.text.trim();
                      if (customName.isEmpty) {
                        SnackbarService(context).showErrorSnackbar(
                          message: 'Please enter a custom category name.',
                        );
                        return;
                      }
                      categoryKey = customName.toUpperCase().replaceAll(' ', '_');
                    } else {
                      if (selectedCategory == null) {
                        SnackbarService(context).showErrorSnackbar(
                          message: 'Please select a category.',
                        );
                        return;
                      }
                      categoryKey = selectedCategory!;
                    }

                    Navigator.pop(context);
                    await _addBudget(category: categoryKey, limit: limit);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(Budget budget) {
    final limitController = TextEditingController(text: budget.limitAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Edit ${getCategoryLabel(budget.category)} Budget',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Limit Amount',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: limitController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final limitText = limitController.text.trim();
                final double? limit = double.tryParse(limitText);

                if (limit == null || limit <= 0) {
                  SnackbarService(context).showErrorSnackbar(
                    message: 'Please enter a valid monthly limit amount.',
                  );
                  return;
                }

                Navigator.pop(context);
                await _editBudget(budget, limit);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Budget budget) {
    final label = getCategoryLabel(budget.category);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text('Delete Budget', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete the budget for $label? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteBudget(budget.id, label);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnboardingFlow() {
    final availableCategories = _getAvailableCategories();
    if (_onboardingCategory == null && availableCategories.isNotEmpty) {
      _onboardingCategory = availableCategories.first;
    }

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.track_changes,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Budgets',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Take control of your finances by setting custom limits for your spending categories. To unlock the dashboard, set your first category budget below!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 30),
              const Text(
                'Select Spending Category',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _onboardingIsCustom ? 'CUSTOM_ONBOARD' : _onboardingCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                dropdownColor: Theme.of(context).colorScheme.onPrimary,
                items: [
                  ...availableCategories.map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(getCategoryLabel(c), style: const TextStyle(fontSize: 14)),
                      )),
                  const DropdownMenuItem<String>(
                    value: 'CUSTOM_ONBOARD',
                    child: Text('+ Add Custom Category...', style: TextStyle(fontSize: 14, color: Colors.greenAccent)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val == 'CUSTOM_ONBOARD') {
                      _onboardingIsCustom = true;
                    } else {
                      _onboardingIsCustom = false;
                      _onboardingCategory = val;
                    }
                  });
                },
              ),
              if (_onboardingIsCustom) ...[
                const SizedBox(height: 16),
                const Text(
                  'Custom Category Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _onboardingCustomCategoryController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Subscriptions',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Monthly Limit Amount',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Focus(
                onFocusChange: (hasFocus) {
                  setState(() {
                    _onboardingLimitFocused = hasFocus;
                  });
                },
                child: TextField(
                  controller: _onboardingLimitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: _onboardingLimitFocused || _onboardingLimitController.text.isNotEmpty ? '\$ ' : null,
                    hintText: _onboardingLimitFocused ? '500.00' : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  final limitText = _onboardingLimitController.text.trim();
                  final double? limit = double.tryParse(limitText);

                  if (limit == null || limit <= 0) {
                    SnackbarService(context).showErrorSnackbar(
                      message: 'Please enter a valid monthly limit amount.',
                    );
                    return;
                  }

                  String categoryKey = '';
                  if (_onboardingIsCustom) {
                    final customName = _onboardingCustomCategoryController.text.trim();
                    if (customName.isEmpty) {
                      SnackbarService(context).showErrorSnackbar(
                        message: 'Please enter a custom category name.',
                      );
                      return;
                    }
                    categoryKey = customName.toUpperCase().replaceAll(' ', '_');
                  } else {
                    if (_onboardingCategory == null) {
                      SnackbarService(context).showErrorSnackbar(
                        message: 'Please select a category.',
                      );
                      return;
                    }
                    categoryKey = _onboardingCategory!;
                  }

                  setState(() {
                    _loading = true;
                  });

                  await _addBudget(category: categoryKey, limit: limit);

                  // Reset inputs
                  _onboardingLimitController.clear();
                  _onboardingCustomCategoryController.clear();
                  _onboardingIsCustom = false;
                  _onboardingCategory = null;
                },
                icon: const Icon(Icons.rocket_launch, size: 20),
                label: const Text(
                  'Activate Budgets Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    double totalBudgeted = 0;
    double totalSpent = 0;

    final budgetDetails = _budgets.map((budget) {
      final spent = _calculateSpent(budget.category);
      totalBudgeted += budget.limitAmount;
      totalSpent += spent;
      return _BudgetCardDetail(
        budget: budget,
        spent: spent,
      );
    }).toList();

    // Sort budget cards:
    // 1. By how much they are over budget by the most (highest overAmount first).
    // 2. If not over budget, by how close they are to reaching the limit (highest ratio first).
    budgetDetails.sort((a, b) {
      final aOver = a.spent - a.budget.limitAmount;
      final bOver = b.spent - b.budget.limitAmount;
      final aIsOver = aOver > 0;
      final bIsOver = bOver > 0;

      if (aIsOver && bIsOver) {
        return bOver.compareTo(aOver);
      } else if (aIsOver && !bIsOver) {
        return -1;
      } else if (!aIsOver && bIsOver) {
        return 1;
      } else {
        final aRatio = a.budget.limitAmount > 0 ? (a.spent / a.budget.limitAmount) : 0.0;
        final bRatio = b.budget.limitAmount > 0 ? (b.spent / b.budget.limitAmount) : 0.0;
        return bRatio.compareTo(aRatio);
      }
    });

    double remainingOverall = totalBudgeted - totalSpent;
    bool isOverBudgetOverall = remainingOverall < 0;
    final bool anyCategoryOver = budgetDetails.any((d) => d.spent > d.budget.limitAmount);

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Specialized Premium Budget Health Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Status Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;
                          
                          final statusIcon = Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOverBudgetOverall || anyCategoryOver
                                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15)
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOverBudgetOverall || anyCategoryOver
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: isOverBudgetOverall || anyCategoryOver
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                          );
                          
                          final statusText = Column(
                            crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOverBudgetOverall
                                    ? 'Budget Status: Critical'
                                    : anyCategoryOver
                                        ? 'Budget Status: Warning'
                                        : 'Budget Status: Healthy',
                                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isOverBudgetOverall
                                      ? Theme.of(context).colorScheme.error
                                      : anyCategoryOver
                                          ? Colors.orangeAccent
                                          : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isOverBudgetOverall
                                    ? 'You have exceeded your overall monthly spending limit.'
                                    : anyCategoryOver
                                        ? 'You have exceeded spending limits in some specific categories.'
                                        : 'Awesome! Your spending is well within limits in all categories.',
                                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                statusIcon,
                                const SizedBox(height: 16),
                                statusText,
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                statusIcon,
                                const SizedBox(width: 16),
                                Expanded(child: statusText),
                              ],
                            );
                          }
                        },
                      ),
                      


                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Budgets List Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Limits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...budgetDetails.map((detail) {
                    final b = detail.budget;
                    final spent = detail.spent;
                    final ratio = b.limitAmount > 0 ? (spent / b.limitAmount) : 0.0;
                    final percentage = (ratio * 100).toStringAsFixed(0);
                    final isOverBudget = spent > b.limitAmount;
                    final remaining = b.limitAmount - spent;

                    // Progress Bar Color Mapping
                    Color progressColor;
                    if (ratio < 0.7) {
                      progressColor = Colors.greenAccent;
                    } else if (ratio <= 1.0) {
                      progressColor = Colors.orangeAccent;
                    } else {
                      progressColor = Colors.redAccent;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: progressColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isOverBudget ? Icons.warning : Icons.donut_large,
                                          color: progressColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              getCategoryLabel(b.category),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              isOverBudget
                                                  ? '\$${remaining.abs().toStringAsFixed(2)} over budget'
                                                  : '\$${remaining.toStringAsFixed(2)} remaining',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isOverBudget ? Colors.redAccent : Colors.grey,
                                                fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditDialog(b);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(b);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Limit', style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete Budget',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${spent.toStringAsFixed(2)} spent',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '$percentage% of \$${b.limitAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showOnboarding = !_loading && _budgets.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(
            header: 'Budgets',
            sub: showOnboarding
                ? 'Onboarding setup flow'
                : 'Set and track your monthly category spending limits',
            action: showOnboarding
                ? null
                : ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Create Budget',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      foregroundColor: Theme.of(context).colorScheme.inverseSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : showOnboarding
                    ? _buildOnboardingFlow()
                    : Column(
                        children: [
                          _buildDashboard(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

}

class _BudgetCardDetail {
  final Budget budget;
  final double spent;

  _BudgetCardDetail({required this.budget, required this.spent});
}
