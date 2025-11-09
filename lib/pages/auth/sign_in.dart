import 'package:financial_tracker/main.dart';
import 'package:financial_tracker/services/api_service.dart';
import 'package:financial_tracker/services/snackbar.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key});

  final ApiService _apiService = getIt<ApiService>();

  static AuthStateChangeAction<UserCreated> _userCreated() {
    return AuthStateChangeAction<UserCreated>((context, state) {
      context.push('/auth/verify-email');
      SnackbarService(context).showSuccessSnackbar(message: 'User successfully created!');
    });
  }

  AuthStateChangeAction<SignedIn> _userSignIn() {
    return AuthStateChangeAction<SignedIn>((context, state) {
      _apiService.searchAccounts(context);
      context.push('/home');
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