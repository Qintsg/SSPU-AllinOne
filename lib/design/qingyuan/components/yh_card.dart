/*
 * 清源卡片 — 内容分组的统一表面
 * @Project : SSPU-AllinOne
 * @File : yh_card.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

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
    this.radius,
    this.borderWidth,
  });

  final Widget child;
  final bool elevated;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.fast,
      disableAnimations: disableAnimations,
    );
    Widget surface(YhPressableState? state) => AnimatedContainer(
      duration: duration,
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
                width: borderWidth ?? theme.layout.divider,
              ),
        borderRadius: BorderRadius.circular(radius ?? theme.radius.l),
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
