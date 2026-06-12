import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigatorScafold extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const NavigatorScafold({
    super.key,
    required this.child,
    this.currentPath = '/home',
  });

  @override
  State<NavigatorScafold> createState() => _NavigatorScafoldState();
}

class _NavigatorScafoldState extends State<NavigatorScafold> {
  bool _extendRail = false;

  int? get _selectedBottomIndex {
    final path = widget.currentPath;
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/transactions')) return 1;
    if (path.startsWith('/analytics')) return 2;
    if (path.startsWith('/vault') ||
        path.startsWith('/budgets') ||
        path.startsWith('/subscriptions') ||
        path.startsWith('/savings')) {
      return 3;
    }
    return null;
  }

  int? get _selectedRailIndex {
    final bottomIndex = _selectedBottomIndex;
    if (bottomIndex == null) return null;
    return bottomIndex + 1;
  }

  void _navigate(int index, BuildContext context, {required bool isRail}) {
    final targetIndex = isRail ? index - 1 : index;
    switch (targetIndex) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/analytics');
        break;
      case 3:
        context.go('/vault');
        break;
    }
  }

  Widget _buildBottomIsland(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final islandWidth = width < 600 ? double.infinity : 480.0;
    final theme = Theme.of(context);

    final double tabHorizontalPadding = width < 400
        ? (width < 340 ? 6.0 : 10.0)
        : 16.0;
    final double containerHorizontalPadding = width < 400 ? 8.0 : 12.0;

    final destinations = [
      _Destination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Overview',
      ),
      _Destination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'Transactions',
      ),
      _Destination(
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        label: 'Analytics',
      ),
      _Destination(
        icon: Icons.savings_outlined,
        selectedIcon: Icons.savings,
        label: 'Vaults',
      ),
    ];

    return Center(
      heightFactor: 1.0,
      child: Container(
        width: islandWidth,
        margin: EdgeInsets.only(
          left: width < 340 ? 8.0 : (width < 600 ? 16.0 : 0.0),
          right: width < 340 ? 8.0 : (width < 600 ? 16.0 : 0.0),
          bottom: width < 360 ? 16.0 : 24.0,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1A1A1A,
          ).withAlpha(216), // Dark premium glass background
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: containerHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final isSelected = _selectedBottomIndex == index;

              final item = InkWell(
                onTap: () => _navigate(index, context, isRail: false),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: tabHorizontalPadding,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(38)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? destination.selectedIcon
                            : destination.icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        size: 24,
                      ),
                      if (isSelected) ...[
                        SizedBox(width: width < 400 ? 6.0 : 8.0),
                        Flexible(
                          child: Text(
                            destination.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: width < 360 ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );

              return isSelected ? Flexible(child: item) : item;
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = [
      NavigationRailDestination(
        icon: Icon(_extendRail ? Icons.menu_open : Icons.menu),
        label: const Text('Financial Tracker'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Overview'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long_rounded),
        label: Text('Transactions'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights_rounded),
        label: Text('Analytics'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.savings_outlined),
        selectedIcon: Icon(Icons.savings),
        label: Text('Vaults'),
      ),
    ];

    return NavigationRail(
      extended: _extendRail,
      minWidth: 60,
      minExtendedWidth: 180,
      backgroundColor: theme.colorScheme.onPrimary,
      selectedIndex: _selectedRailIndex,
      groupAlignment: -1.0,
      destinations: destinations,
      onDestinationSelected: (int index) {
        if (index == 0) {
          setState(() {
            _extendRail = !_extendRail;
          });
        } else {
          _navigate(index, context, isRail: true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            if (isWide) ...[
              _buildSidebar(context),
              const VerticalDivider(thickness: 1, width: 1),
            ],
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(top: false, child: _buildBottomIsland(context)),
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
