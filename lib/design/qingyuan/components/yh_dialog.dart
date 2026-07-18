/* 清源对话框 — 统一模态决策与焦点归还。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';
import 'yh_button.dart';

class YhDialog extends StatelessWidget {
  const YhDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    bool danger = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: !danger,
      barrierLabel: '关闭对话框',
      barrierColor: context.yhTheme.color.scrim,
      transitionDuration: context.yhTheme.motion.base,
      pageBuilder: (dialogContext, animation, secondaryAnimation) => YhDialog(
        title: title,
        content: Text(message),
        actions: [
          YhButton(
            label: cancelText,
            variant: YhButtonVariant.secondary,
            autofocus: true,
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
          YhButton(
            label: confirmText,
            variant: danger ? YhButtonVariant.danger : YhButtonVariant.primary,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final disableAnimations =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (disableAnimations) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: context.yhTheme.motion.curve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Center(
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.surface,
                borderRadius: BorderRadius.circular(theme.radius.l),
                boxShadow: theme.elevation.e3,
              ),
              child: Padding(
                padding: EdgeInsets.all(theme.spacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.typography.h3.copyWith(
                          color: theme.color.foreground,
                        ),
                      ),
                    ),
                    SizedBox(height: theme.spacing.m),
                    DefaultTextStyle(
                      style: theme.typography.body.copyWith(
                        color: theme.color.muted,
                      ),
                      child: content,
                    ),
                    SizedBox(height: theme.spacing.l),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: theme.spacing.s,
                        runSpacing: theme.spacing.s,
                        children: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
