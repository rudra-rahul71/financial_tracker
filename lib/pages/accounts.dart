import 'package:financial_tracker/core/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:financial_tracker/services/db_service.dart';
import 'package:financial_tracker/services/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ApiService _apiService = getIt<ApiService>();
  Iterable<MapEntry<String, List<Account>>> _accounts = {};
  bool _loading = false;

  Future<void> _initPlaidIntegration(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    dynamic resopnse = await _apiService.initPlaidIntegration(context);
    if(resopnse != null && context.mounted && resopnse is LinkSuccess) {
      final publicToken = resopnse.toJson()['publicToken'];
      await _apiService.createPlaidAccessToken(context, publicToken);

      if(context.mounted) {
        await _apiService.searchAccounts(context);
      }

      await _updateAccounts();
    } else {
      if(context.mounted) {
        SnackbarService(context).showErrorSnackbar(message: 'Failed to connect to bank!');
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateAccounts() async {
    List<Account> accounts = await _databaseService.getAccounts();

    Map<String, List<Account>> groupedAccounts = {};
    for(final account in accounts) {
      groupedAccounts
        .putIfAbsent(account.itemId, () => [])
        .add(account);
    }

    setState(() {
      _accounts = groupedAccounts.entries;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(header: 'Accounts', sub: 'Manage your financial accounts', 
            action: ElevatedButton.icon(
              onPressed: () {
                _initPlaidIntegration(context);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Theme.of(context).colorScheme.inverseSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Expanded(child: Center(child:
            _loading ? CircularProgressIndicator() :
            _accounts.isEmpty ? Text('No Accounts') :
            Text('${_accounts.length}'),
          ))
        ],
      ),
    );
  }
}