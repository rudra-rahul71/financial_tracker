import 'package:flutter/material.dart';

class BasicCard extends StatefulWidget {
  final String title;
  final Widget body;
  final Widget? action;

  const BasicCard({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  State<BasicCard> createState() => _BasicCardState();
}

class _BasicCardState extends State<BasicCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 20.0,
              spacing: 20.0,
              children: [
                Text(widget.title),
                ?widget.action,
              ]
            ),
            const SizedBox(height: 12.0),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: widget.body,
            )
          ],
        ),
      ),
    );
  }
}