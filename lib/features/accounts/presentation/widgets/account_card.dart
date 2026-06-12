import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:financial_tracker/core/database/db_service.dart';
import 'package:flutter/material.dart';

class AccountCard extends StatefulWidget {
  final MapEntry<String, (Item, List<Account>)> connection;
  final VoidCallback onAccountUpdated;
  const AccountCard({
    super.key,
    required this.connection,
    required this.onAccountUpdated,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool get _isCreditCard =>
      widget.connection.value.$2.any((account) => account.type == 'credit');

  late final _totalValue = widget.connection.value.$2.fold(0.0, (
    double previousSum,
    Account account,
  ) {
    if (account.type == 'credit') {
      // Credit card: negate the current balance (it's debt)
      return previousSum - (account.current ?? 0.0);
    }
    return previousSum + (account.available ?? 0.0);
  });

  Color _balanceColor(BuildContext context, double value) {
    if (value > 0) return Theme.of(context).colorScheme.inversePrimary;
    if (value < 0) return Theme.of(context).colorScheme.onError;
    return Colors.grey;
  }

  Widget _buildInstitutionInfo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.connection.value.$1.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                '${widget.connection.value.$2.length} accounts',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalance(
    BuildContext context, {
    CrossAxisAlignment alignment = CrossAxisAlignment.end,
  }) {
    final displayValue = _totalValue;
    final absValue = displayValue.abs().toStringAsFixed(2);

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _isCreditCard ? 'Total Owed' : 'Total Balance',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$$absValue',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _balanceColor(context, displayValue),
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 340;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isCompact) ...[
                  // Vertical layout for narrow screens
                  _buildInstitutionInfo(context),
                  const SizedBox(height: 12.0),
                  _buildTotalBalance(
                    context,
                    alignment: CrossAxisAlignment.start,
                  ),
                ] else ...[
                  // Horizontal layout for wider screens
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildInstitutionInfo(context)),
                      const SizedBox(width: 8),
                      _buildTotalBalance(context),
                    ],
                  ),
                ],
                const SizedBox(height: 12.0),
                const Divider(height: 24.0),
                ...widget.connection.value.$2.map((account) {
                  final isCreditType = account.type == 'credit';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      account.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 14),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showRenameDialog(context, account),
                                  ),
                                ],
                              ),
                              Text(
                                account.subetype,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCreditType)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBalanceRow(
                                'Balance Owed',
                                account.current ?? 0.0,
                              ),
                              if (account.available != null)
                                _buildBalanceRow(
                                  'Credit Limit',
                                  (account.available ?? 0.0) +
                                      (account.current ?? 0.0),
                                ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBalanceRow(
                                'Current',
                                account.current ?? 0.0,
                              ),
                              _buildBalanceRow(
                                'Available',
                                account.available ?? 0.0,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, double value) {
    final prefix = value < 0 ? '-\$' : '\$';
    final absValue = value.abs().toStringAsFixed(2);
    return Text('$label: $prefix$absValue');
  }

  void _showRenameDialog(BuildContext context, Account account) {
    final textController = TextEditingController(text: account.displayName);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename Account'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Enter new account name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  await DatabaseService.instance.updateAccountName(account.id, newName);
                  widget.onAccountUpdated();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
