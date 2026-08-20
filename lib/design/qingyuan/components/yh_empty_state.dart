/* 清源空状态。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhEmptyState extends StatelessWidget {
  const YhEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? theme.spacing.m : theme.spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? theme.typography.h1.fontSize : theme.spacing.xl2,
              color: theme.color.muted,
            ),
            SizedBox(height: compact ? theme.spacing.s : theme.spacing.m),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: (compact ? theme.typography.h3 : theme.typography.h2)
                    .copyWith(color: theme.color.foreground),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: compact ? theme.spacing.xs : theme.spacing.s),
              Text(
                message!,
                textAlign: TextAlign.center,
                style:
                    (compact ? theme.typography.small : theme.typography.body)
                        .copyWith(color: theme.color.muted),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? theme.spacing.m : theme.spacing.l),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
