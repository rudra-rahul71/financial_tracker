import 'package:flutter/material.dart';

class SnackbarService {
  BuildContext context;

  SnackbarService(this.context);

  void showSuccessSnackbar({required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check),
            Expanded(child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            textAlign: TextAlign.right,
          ),),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        behavior: SnackBarBehavior.floating,
      )
    );
  }
}