import 'package:financial_tracker/core/page_header.dart';
import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:flutter/material.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final ApiService _apiService = getIt<ApiService>();
  bool _loading = false;

  Future<void> _initPlaidIntegration() async {
    setState(() {
      _loading = true;
    });

    await _apiService.initPlaidIntegration();

    setState(() {
      _loading = false;
    });
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
                _initPlaidIntegration();
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
            _loading ? null : Text('No Accounts'),
          ))
        ],
      ),
    );
  }
}