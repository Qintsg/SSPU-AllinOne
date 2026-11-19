/*
 * 清源开关 — 即时生效的二元状态控件
 * @Project : SSPU-AllinOne
 * @File : yh_switch.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';
import 'yh_miuix.dart';

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
    final enabled = !disabled && onChanged != null;
    return YhPressable(
      semanticLabel: semanticLabel,
      toggled: value,
      onPressed: enabled ? () => onChanged!(!value) : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: YhMiuixTheme(
            child: MediaQuery.maybeDisableAnimationsOf(context) == true
                ? _InstantSwitchTrack(value: value, enabled: enabled)
                : miuix.MiuixSwitch(
                    value: value,
                    enabled: enabled,
                    onChanged: enabled ? onChanged : null,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 在系统要求减少动态时，以相同的 Miuix 颜色和尺寸直接绘制目标状态。
class _InstantSwitchTrack extends StatelessWidget {
  const _InstantSwitchTrack({required this.value, required this.enabled});

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = miuix.MiuixSwitchDefaults.switchColors(context);
    final (track, thumb) = switch ((value, enabled)) {
      (true, true) => (colors.checkedTrackColor, colors.checkedThumbColor),
      (false, true) => (colors.uncheckedTrackColor, colors.uncheckedThumbColor),
      (true, false) => (
        colors.disabledCheckedTrackColor,
        colors.disabledCheckedThumbColor,
      ),
      (false, false) => (
        colors.disabledUncheckedTrackColor,
        colors.disabledUncheckedThumbColor,
      ),
    };
    return SizedBox(
      width: miuix.MiuixSwitchDefaults.trackWidth,
      height: miuix.MiuixSwitchDefaults.trackHeight,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: track, shape: const StadiumBorder()),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: miuix.MiuixSwitchDefaults.thumbOffsetOff,
          ),
          child: Align(
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: SizedBox.square(
              dimension: miuix.MiuixSwitchDefaults.thumbSize,
              child: DecoratedBox(
                decoration: BoxDecoration(color: thumb, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
