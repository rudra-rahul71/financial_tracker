import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigatorScafold extends StatefulWidget {
  final Widget child;
  
  const NavigatorScafold({
    super.key,
    required this.child,
  });

  @override
  State<NavigatorScafold> createState() => _NavigatorScafoldState();
}

class _NavigatorScafoldState extends State<NavigatorScafold> {
  int _selectedIndex = 0;
  bool extendRail = false;

  void _toggleRail() {
    setState(() {
      extendRail = !extendRail;
    });
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
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              extended: extendRail,
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              selectedIndex: _selectedIndex,
              groupAlignment: -1.0,
              destinations: <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: extendRail ? const Icon(Icons.menu_open) : const Icon(Icons.menu),
                  label: const Text('Financial Tracker'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.account_circle),
                  label: Text('Profile'),
                ),
              ],
              onDestinationSelected: (int index) {
                if(index == 0) {
                  _toggleRail();
                } else {
                  _navigate(index, context);
                }
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}