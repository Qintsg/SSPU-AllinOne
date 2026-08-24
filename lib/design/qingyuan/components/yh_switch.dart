/*
 * 清源开关 — 即时生效的二元状态控件
 * @Project : SSPU-AllinOne
 * @File : yh_switch.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

class YhSwitch extends StatelessWidget {
  const YhSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.semanticLabel = '开关',
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.base,
      disableAnimations: disableAnimations,
    );
    final enabled = !disabled && onChanged != null;
    final trackWidth = theme.control.regular - theme.spacing.xs;
    final trackHeight = theme.spacing.l + theme.spacing.xs / 2;
    final thumbSize = theme.spacing.l - theme.spacing.xs;
    return YhPressable(
      semanticLabel: semanticLabel,
      toggled: value,
      onPressed: enabled ? () => onChanged!(!value) : null,
      builder: (context, state, child) =>
          Opacity(opacity: state.disabled ? 0.4 : 1, child: child),
      child: SizedBox(
        width: theme.control.minimumTarget,
        height: theme.control.minimumTarget,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: theme.motion.curve,
            width: trackWidth,
            height: trackHeight,
            padding: EdgeInsets.all(theme.spacing.xs * 0.75),
            decoration: BoxDecoration(
              color: value ? theme.color.brandStrong : theme.color.border,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: theme.motion.curve,
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.color.onStructural,
                  shape: BoxShape.circle,
                  boxShadow: theme.elevation.e1,
                ),
                child: SizedBox.square(dimension: thumbSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
