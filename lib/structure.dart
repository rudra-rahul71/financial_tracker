import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldStruct extends StatelessWidget {
  const ScaffoldStruct({required this.child, super.key,});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem( icon: Icon(Icons.home), label: 'Home' ),
          BottomNavigationBarItem( icon: Icon(Icons.account_circle), label: 'Profile' ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) {
          _onItemTapped(index, context);
        },
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/profile')) {
      return 1;
    } else {
      return 0;
    }
  }

  // Helper method to navigate to the correct route when a tab is tapped.
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/profile');
        break;
    }
  }
}