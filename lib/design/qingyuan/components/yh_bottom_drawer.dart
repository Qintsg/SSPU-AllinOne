/* 清源底部抽屉 — compact 低频入口与短表单容器。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhBottomDrawer extends StatelessWidget {
  const YhBottomDrawer({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) {
    final theme = context.yhTheme;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭$title',
      barrierColor: theme.color.scrim,
      transitionDuration: theme.motion.base,
      pageBuilder: (drawerContext, animation, secondaryAnimation) => Align(
        alignment: Alignment.bottomCenter,
        child: YhBottomDrawer(title: title, child: builder(drawerContext)),
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
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.breakpoint.medium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.color.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(theme.radius.l),
            ),
            boxShadow: theme.elevation.e3,
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.typography.h2.copyWith(
                      color: theme.color.foreground,
                    ),
                  ),
                ),
                SizedBox(height: theme.spacing.m),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
