import 'package:financial_tracker/core/page_header.dart';
import 'package:flutter/material.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  Future<void> _initPlaidIntegration() async {
    // setState(() {
    //   _isLoading = true;
    // });

    // await _apiService.initPlaidIntegration();
    // final SharedPreferences prefs = await SharedPreferences.getInstance();

    // setState(() {
    //   accessTokens = prefs.getStringList('accessTokens');
    //   _isLoading = false;
    // });
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
           Text('No Accounts'),
           ))
        ],
      ),
    );
  }
}