/*
 * Fluent 2 开关 — 胶囊轨道 / 圆形滑块 / 焦点环均走令牌
 * @Project : SSPU-AllinOne
 * @File : fluent_switch.dart
 * @Author : Qintsg
 * @Date : 2026-05-29
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 开关控件。
class FluentSwitch extends StatefulWidget {
  const FluentSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  /// 当前开关值。
  final bool value;

  /// 值变化回调；为空时进入禁用态。
  final ValueChanged<bool>? onChanged;

  /// 无障碍语义标签。
  final String? semanticLabel;

  @override
  State<FluentSwitch> createState() => _FluentSwitchState();
}

class _FluentSwitchState extends State<FluentSwitch> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final stroke = context.fluentStroke;
    final motion = context.fluentMotion;

    final Color trackColor = !_enabled
        ? colors.neutralBackground3
        : widget.value
        ? (_pressed ? colors.brandBackgroundPressed : colors.brandBackground)
        : (_hovered ? colors.neutralBackground3 : colors.neutralBackground2);
    final Color trackBorder = !_enabled
        ? colors.neutralStroke2
        : widget.value
        ? colors.brandStroke1
        : colors.neutralStroke1;
    final Color thumbColor = !_enabled
        ? colors.neutralForegroundDisabled
        : widget.value
        ? colors.neutralForegroundOnBrand
        : colors.neutralForeground3;

    final switchVisual = AnimatedContainer(
      duration: motion.durationFast,
      curve: motion.curveEasyEase,
      width: 40,
      height: 20,
      padding: EdgeInsets.all(stroke.thick),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(radii.circular),
        border: Border.all(color: trackBorder, width: stroke.thin),
      ),
      child: AnimatedAlign(
        duration: motion.durationFast,
        curve: motion.curveEasyEase,
        alignment: widget.value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: AnimatedContainer(
          duration: motion.durationFast,
          curve: motion.curveEasyEase,
          width: _pressed ? 18 : 14,
          height: 14,
          decoration: BoxDecoration(
            color: thumbColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    final focusable = AnimatedContainer(
      duration: motion.durationFaster,
      curve: motion.curveEasyEase,
      padding: EdgeInsets.all(_focused ? stroke.thick : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          radii.circular + (_focused ? stroke.thick : 0),
        ),
        border: _focused
            ? Border.all(color: colors.brandStroke1, width: stroke.thick)
            : null,
      ),
      child: switchVisual,
    );

    return Semantics(
      label: widget.semanticLabel,
      toggled: widget.value,
      enabled: _enabled,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        onShowHoverHighlight: (hovered) => setState(() {
          _hovered = hovered;
          if (!hovered) _pressed = false;
        }),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onChanged?.call(!widget.value);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? () => widget.onChanged?.call(!widget.value) : null,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(child: focusable),
          ),
        ),
      ),
    );
  }
}
