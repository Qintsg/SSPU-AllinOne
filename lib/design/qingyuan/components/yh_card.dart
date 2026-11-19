/*
 * 清源卡片 — 内容分组的统一表面
 * @Project : SSPU-AllinOne
 * @File : yh_card.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

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
      decoration: ShapeDecoration(
        color: state?.pressed == true
            ? theme.color.sunken
            : theme.color.surface,
        shape: miuix.MiuixSquircleBorder(
          cornerRadius: radius ?? theme.radius.l,
          side: state?.hovered == true || state?.focused == true
              ? BorderSide(
                  color: theme.color.brand,
                  width: theme.layout.divider,
                )
              : (borderWidth ?? 0) > 0
              ? BorderSide(color: theme.color.border, width: borderWidth!)
              : BorderSide.none,
        ),
        shadows: elevated
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
