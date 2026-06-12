import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageHeader extends StatefulWidget {
  final String header;
  final String sub;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool wrapAction;
  final bool showProfileButton;

  const PageHeader({
    super.key,
    required this.header,
    required this.sub,
    this.actions,
    this.showBackButton = false,
    this.wrapAction = true,
    this.showProfileButton = false,
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  Widget _buildActions(
    BuildContext context, {
    required bool isWrapped,
    double? maxWidth,
  }) {
    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;
    if (!hasActions && !widget.showProfileButton) {
      return const SizedBox.shrink();
    }

    final children = [
      if (hasActions) ...widget.actions!,
      if (widget.showProfileButton) ...[
        if (hasActions && !isWrapped) const SizedBox(width: 12),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.account_circle, size: 28),
          tooltip: 'View Profile',
        ),
      ],
    ];

    if (isWrapped) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Wrap(
          spacing: 12.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double paddingOffset = 40.0;
        final double backButtonOffset = widget.showBackButton ? 72.0 : 0.0;
        final double maxTextWidth =
            (constraints.maxWidth - paddingOffset - backButtonOffset).clamp(
              120.0,
              double.infinity,
            );

        if (widget.wrapAction) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 20.0,
                spacing: 20.0,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.showBackButton) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                context.go('/vault');
                              }
                            },
                          ),
                        ),
                      ],
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxTextWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.header,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.sub,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.inversePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildActions(
                    context,
                    isWrapped: true,
                    maxWidth: constraints.maxWidth - paddingOffset,
                  ),
                ],
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.showBackButton) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                context.go('/vault');
                              }
                            },
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.header,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.sub,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.inversePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if ((widget.actions != null && widget.actions!.isNotEmpty) ||
                    widget.showProfileButton) ...[
                  const SizedBox(width: 16),
                  _buildActions(context, isWrapped: false),
                ],
              ],
            ),
          );
        }
      },
    );
  }
}
