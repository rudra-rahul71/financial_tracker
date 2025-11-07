import 'package:flutter/material.dart';

class PageHeader extends StatefulWidget {
  final String header;
  final String sub;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.header,
    required this.sub,
    this.action, 
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.header,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
              Text(
                widget.sub,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
              
          ?widget.action
        ],
      ),
    );
  }
}