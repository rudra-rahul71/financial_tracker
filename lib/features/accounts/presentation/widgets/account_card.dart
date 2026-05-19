import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:financial_tracker/features/accounts/domain/entities/item.dart';
import 'package:flutter/material.dart';

class AccountCard extends StatefulWidget {
  final MapEntry<String, (Item, List<Account>)> connection;
  const AccountCard({super.key, required this.connection});

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  late final _totalValue = widget.connection.value.$2.fold(
    0.0,
    (double previousSum, Account account) =>
        previousSum + (account.available ?? 0.0),
  );

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

  Widget _buildTotalBalance(BuildContext context, {CrossAxisAlignment alignment = CrossAxisAlignment.end}) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'Total Balance',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$${_totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
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
                  _buildTotalBalance(context, alignment: CrossAxisAlignment.start),
                ] else ...[
                  // Horizontal layout for wider screens
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildInstitutionInfo(context)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildTotalBalance(context)),
                    ],
                  ),
                ],
                const SizedBox(height: 12.0),
                const Divider(height: 24.0),
                ...widget.connection.value.$2.map((account) {
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
                              Text(
                                account.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                account.subetype,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Current: \$${(account.current ?? 0.0).toStringAsFixed(2)}',
                            ),
                            Text(
                              'Available: \$${(account.available ?? 0.0).toStringAsFixed(2)}',
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
}
