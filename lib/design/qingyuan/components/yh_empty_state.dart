/* 清源空状态。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhEmptyState extends StatelessWidget {
  const YhEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: theme.spacing.xl2, color: theme.color.muted),
            SizedBox(height: theme.spacing.m),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.typography.h2.copyWith(
                  color: theme.color.foreground,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.body.copyWith(color: theme.color.muted),
            ),
            if (action != null) ...[SizedBox(height: theme.spacing.l), action!],
          ],
        ),
      ),
    );
  }
}
