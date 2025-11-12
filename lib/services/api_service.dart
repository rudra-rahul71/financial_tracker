import 'dart:async';
import 'dart:convert';

import 'package:financial_tracker/models/account.dart';
import 'package:financial_tracker/models/connection.dart';
import 'package:financial_tracker/models/item.dart';
import 'package:financial_tracker/models/transaction.dart';
import 'package:financial_tracker/services/db_service.dart';
import 'package:financial_tracker/services/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:plaid_flutter/plaid_flutter.dart';

class ApiService {
  // final String host = 'http://10.0.2.2:8080';
  final String host = 'http://localhost:8080';

  final DatabaseService _databaseService = DatabaseService.instance;

  StreamSubscription<LinkSuccess>? _onSuccessSubscription;
  StreamSubscription<LinkExit>? _onExitSubscription;

  static int _interval = 30;
  static int get interval => _interval;
  static void setMyVariable(int newValue) {
    _interval = newValue;
  }

  Future<void> searchAccounts(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser!;
    final idToken = await user.getIdToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final url = Uri.parse('$host/search/$_interval');

    final response = await http.get(url, headers: headers);
    if(response.statusCode != 200) {
      if(context.mounted) {
        SnackbarService(context).showErrorSnackbar(message: 'Please connect account to view financial data!');
      }
    } else {
      final data = json.decode(response.body);
      final connections = Connection.fromJsonList(data);
      _databaseService.clearTable(Item.tableName);
      _databaseService.clearTable(Account.tableName);
      _databaseService.clearTable(TransactionEntry.tableName);
      for(final connection in connections) {
        _databaseService.updateTable(Item.tableName, connection.item);
        for(final account in connection.accounts) {
          _databaseService.updateTable(Account.tableName, account);
        }
        for(final transaction in connection.transactions) {
          _databaseService.updateTable(TransactionEntry.tableName, transaction);
        }
      }

      if(connections.isEmpty) {
        if(context.mounted) {
          SnackbarService(context).showErrorSnackbar(message: 'Please connect account to view financial data!');
        }
      }
    }
  }

  Future<void> createPlaidAccessToken(BuildContext context, String publicToken) async {
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

  Future<dynamic> initPlaidIntegration(BuildContext context) async {
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
        await PlaidLink.open();
        return await Future.any([
          PlaidLink.onSuccess.first,
          PlaidLink.onExit.first,
        ]);
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
    return null;
  }
}