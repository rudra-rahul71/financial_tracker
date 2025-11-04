import 'package:financial_tracker/services/snackbar.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static AuthStateChangeAction<UserCreated> _userCreated() {
    return AuthStateChangeAction<UserCreated>((context, state) {
      context.push('/auth/sign-in');

      SnackbarService(context).showSuccessSnackbar(message: 'User successfully created!\nPlease sign in.');
    });
  }

  static AuthStateChangeAction<SignedIn> _userSignIn() {
    return AuthStateChangeAction<SignedIn>((context, state) {
      if(!state.user!.emailVerified) {
        context.push('/auth/verify-email');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [EmailAuthProvider()],
      actions: [
        _userCreated(),
        _userSignIn(),
      ],
    );
  }
}