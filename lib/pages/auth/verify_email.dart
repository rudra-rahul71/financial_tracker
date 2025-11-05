import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  static AuthCancelledAction _cancel() {
    return AuthCancelledAction((context) {
      context.pop();
    });
  }

  static EmailVerifiedAction _verified(BuildContext context) {
    return EmailVerifiedAction(() {
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return EmailVerificationScreen(
      actions: [
        _cancel(),
        _verified(context),
      ],
    );
  }
}