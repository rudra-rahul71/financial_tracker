import 'package:financial_tracker/pages/auth/sign_in.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

User? user;

SignedOutAction _signOut() {
  return SignedOutAction((context) {
    user = FirebaseAuth.instance.currentUser;
    context.go('/auth/sign-in');
  });
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return user != null ? ProfileScreen(
      actions: [
        _signOut(),
      ],
    ) : SignInPage();
  }
}