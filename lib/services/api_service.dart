import 'dart:async';
import 'dart:convert';

import 'package:financial_tracker/services/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:plaid_flutter/plaid_flutter.dart';

class ApiService {
  final String host = 'http://10.0.2.2:8080';
  // final String host = 'http://localhost:8080';

  StreamSubscription<LinkSuccess>? _onSuccessSubscription;
  StreamSubscription<LinkExit>? _onExitSubscription;

  Future<void> _createPlaidAccessToken(BuildContext context, String publicToken) async {
    final user = FirebaseAuth.instance.currentUser!;
    final idToken = await user.getIdToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final url = Uri.parse('$host/create/$publicToken');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      if(context.mounted) {
        SnackbarService(context).showSuccessSnackbar(message: 'Successfully to connected to bank!');
      }
    } else {
      if(context.mounted) {
        SnackbarService(context).showErrorSnackbar(message: 'Failed to connect to bank!');
      }
    }
  }

  Future<void> initPlaidIntegration(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final idToken = await user.getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      final url = Uri.parse('$host/init');

      final resopnse = await http.get(url, headers: headers);
      if (resopnse.statusCode == 200) {
        await _onSuccessSubscription?.cancel();
        await _onExitSubscription?.cancel();
        final data = json.decode(resopnse.body);
        LinkTokenConfiguration configuration = LinkTokenConfiguration(
            token: data['link_token'],
            noLoadingState: true,
        );
        await PlaidLink.create(configuration: configuration);
        _onSuccessSubscription =PlaidLink.onSuccess.listen((LinkSuccess event) async {
          final publicToken = event.toJson()['publicToken'];
          if(context.mounted) {
            _createPlaidAccessToken(context, publicToken);
          }
          _onSuccessSubscription?.cancel();
          _onExitSubscription?.cancel();
        });

        _onExitSubscription = PlaidLink.onExit.listen((LinkExit event) {
          _onSuccessSubscription?.cancel();
          _onExitSubscription?.cancel();
        });
        PlaidLink.open();
      } else {
        if(context.mounted) {
          SnackbarService(context).showErrorSnackbar(message: 'Failed to initiate connection process!');
        }
      }
    } catch (e) {
      if(context.mounted) {
        SnackbarService(context).showErrorSnackbar(message: 'Failed to initiate connection process!');
      }
    }
  }
}