import 'package:financial_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:financial_tracker/core/widgets/net_worth.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/core/network/api_service.dart';
import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'dart:io' show Platform;

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ApiService _apiService = getIt<ApiService>();
  Iterable<MapEntry<String, (Item, List<Account>)>> _connections = {};
  double _totalValue = 0.0;
  int _totalAccounts = 0;
  bool _loading = false;

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Bank Account'),
                subtitle: const Text('Checking or Savings'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _initPlaidIntegration(context, 'depository');
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Credit Card'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _initPlaidIntegration(context, 'credit');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _initPlaidIntegration(
    BuildContext context,
    String accountType,
  ) async {
    if (Platform.isMacOS) {
      SnackbarService(context).showErrorSnackbar(
        message:
            "Adding accounts aren't supported on macOS, try iPhone/Android",
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    dynamic resopnse = await _apiService.initPlaidIntegration(
      context,
      accountType,
    );
    if (resopnse != null && context.mounted && resopnse is LinkSuccess) {
      final publicToken = resopnse.toJson()['publicToken'];
      await _apiService.createPlaidAccessToken(context, publicToken);

      // Brief delay to allow Plaid to prepare transaction data
      await Future.delayed(const Duration(seconds: 3));

      if (context.mounted) {
        await _apiService.searchAccounts(context);
      }

      await _updateAccounts();
    } else {
      if (context.mounted) {
        SnackbarService(
          context,
        ).showErrorSnackbar(message: 'Failed to connect to bank!');
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateAccounts() async {
    List<Account> accounts = await _databaseService.getAccounts();

    _totalAccounts = accounts.length;
    _totalValue = accounts.fold(0.0, (double previousSum, Account account) {
      if (account.type == 'credit') {
        // Credit card balances are debt — subtract from net worth
        return previousSum - (account.current ?? 0.0);
      }
      return previousSum + (account.available ?? 0.0);
    });

    Map<String, (Item, List<Account>)> groupedAccounts = {};
    for (final account in accounts) {
      final itemId = account.itemId;

      _databaseService.getItemById(itemId);
      final item = await _databaseService.getItemById(itemId);

      if (item == null) {
        continue;
      }

      groupedAccounts.update(
        itemId,
        (existingTuple) => (existingTuple.$1, [...existingTuple.$2, account]),
        ifAbsent: () => (item, [account]),
      );
    }

    setState(() {
      _connections = groupedAccounts.entries;
    });
  }

  @override
  void initState() {
    super.initState();

    _updateAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(
            header: 'Accounts',
            sub: 'Manage your financial accounts',
            action: ElevatedButton.icon(
              onPressed: () {
                _showAddAccountDialog(context);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Account',
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
            child: Center(
              child: _loading
                  ? CircularProgressIndicator()
                  : _connections.isEmpty
                  ? Text('No Accounts')
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          NetWorth(
                            totalAccounts: _totalAccounts,
                            totalValue: _totalValue,
                          ),
                          ..._connections.map((account) {
                            return AccountCard(connection: account);
                          }),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
