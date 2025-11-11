import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/models/item.dart';
import 'package:flutter/material.dart';

class AccountCard extends StatefulWidget {
  MapEntry<String, (Item, List<Account>)> connection;
  AccountCard({
    super.key,
    required this.connection
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  late Account _account = widget.connection.value.$2[0];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.connection.value.$1.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _account.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${_account.available!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: <Widget>[
                SizedBox(
                  height: 40,
                  width: 140,
                  child: DropdownButtonFormField(
                    initialValue: widget.connection.value.$2[0],
                    dropdownColor: Theme.of(context).colorScheme.onPrimary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary, 
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.connection.value.$2.map<DropdownMenuItem<Account>>((Account value) {
                      return DropdownMenuItem<Account>(
                        value: value,
                        child: Text(value.subetype),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _account = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 1.0),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey[50],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Chart Placeholder\n(Use a package like fl_chart or charts_flutter here)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}