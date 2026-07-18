/* 清源卡片 — 内容分组的统一表面。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

class YhCard extends StatelessWidget {
  const YhCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.onTap,
    this.semanticLabel,
    this.padding,
  });

  final Widget child;
  final bool elevated;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    Widget surface(YhPressableState? state) => AnimatedContainer(
      duration: theme.motion.fast,
      curve: theme.motion.curve,
      padding: padding ?? EdgeInsets.all(theme.spacing.l),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: elevated
            ? null
            : Border.all(
                color: state?.hovered == true
                    ? theme.color.brand
                    : theme.color.border,
                width: theme.layout.divider,
              ),
        borderRadius: BorderRadius.circular(theme.radius.l),
        boxShadow: elevated
            ? (state?.hovered == true ? theme.elevation.e2 : theme.elevation.e1)
            : const [],
      ),
      child: child,
    );

    if (onTap == null) return surface(null);
    return YhPressable(
      semanticLabel: semanticLabel ?? '打开卡片',
      onPressed: onTap,
      builder: (context, state, child) => surface(state),
      child: child,
    );
  }
}
