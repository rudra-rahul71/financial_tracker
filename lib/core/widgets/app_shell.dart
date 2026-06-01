import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigatorScafold extends StatefulWidget {
  final Widget child;

  const NavigatorScafold({super.key, required this.child});

  @override
  State<NavigatorScafold> createState() => _NavigatorScafoldState();
}

class _NavigatorScafoldState extends State<NavigatorScafold>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  bool extendRail = false;

  late final AnimationController _overlayController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _overlayController, curve: Curves.easeOutCubic),
      );
  late final Animation<double> _scrimAnimation = CurvedAnimation(
    parent: _overlayController,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  void _toggleRail() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    setState(() {
      extendRail = !extendRail;
    });

    if (isSmallScreen) {
      if (extendRail) {
        _overlayController.forward();
      } else {
        _overlayController.reverse();
      }
    }
  }

  void _collapseOverlay() {
    setState(() {
      extendRail = false;
    });
    _overlayController.reverse();
  }

  void _navigate(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        context.go('/home');
        break;
      case 2:
        context.go('/transactions');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/budgets');
        break;
      case 5:
        context.go('/accounts');
        break;
      case 6:
        context.go('/subscriptions');
        break;
      case 7:
        context.go('/profile');
        break;
    }
  }

  static const _destinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.menu),
      label: Text('Financial Tracker'),
    ),
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
    NavigationRailDestination(
      icon: Icon(Icons.credit_card),
      label: Text('Transactions'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.insights),
      label: Text('Analytics'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.track_changes),
      label: Text('Budgets'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance),
      label: Text('Accounts'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.subscriptions),
      label: Text('Subscriptions'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_circle),
      label: Text('Profile'),
    ),
  ];

  Widget _buildRail(
    BuildContext context, {
    required bool extended,
    bool autoCollapse = false,
  }) {
    return NavigationRail(
      extended: extended,
      minWidth: 60,
      minExtendedWidth: 180,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      selectedIndex: _selectedIndex,
      groupAlignment: -1.0,
      destinations: _destinations,
      onDestinationSelected: (int index) {
        if (index == 0) {
          _toggleRail();
        } else {
          if (autoCollapse && extendRail) {
            _collapseOverlay();
          }
          _navigate(index, context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Base layer: collapsed rail + page content
            Row(
              children: <Widget>[
                if (isSmallScreen)
                  _buildRail(context, extended: false)
                else
                  _buildRail(context, extended: extendRail),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.child),
              ],
            ),
            // Overlay layer: animated scrim + sliding rail (small screens only)
            if (isSmallScreen) ...[
              // Scrim fades in/out
              IgnorePointer(
                ignoring: !extendRail,
                child: FadeTransition(
                  opacity: _scrimAnimation,
                  child: GestureDetector(
                    onTap: _collapseOverlay,
                    child: Container(color: Colors.black54),
                  ),
                ),
              ),
              // Rail slides in from the left
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Material(
                    elevation: 16,
                    child: _buildRail(
                      context,
                      extended: true,
                      autoCollapse: true,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
