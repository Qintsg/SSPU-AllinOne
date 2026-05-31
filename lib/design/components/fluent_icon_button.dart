/*
 * Fluent 2 图标按钮 — 工具栏与轻量操作的无涟漪图标按钮
 * @Project : SSPU-AllinOne
 * @File : fluent_icon_button.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 图标按钮外观。
enum FluentIconButtonAppearance {
  /// 透明背景，悬停时显示 subtle 背景。
  transparent,

  /// 描边背景，用于更明确的边界。
  outline,
}

/// Fluent 2 图标按钮。
class FluentIconButton extends StatefulWidget {
  const FluentIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 32,
    this.iconSize = 16,
    this.appearance = FluentIconButtonAppearance.transparent,
    this.semanticLabel,
  });

  /// 图标内容。
  final Widget icon;

  /// 点击回调；为空时禁用。
  final VoidCallback? onPressed;

  /// 可选提示文本。
  final String? tooltip;

  /// 按钮视觉尺寸。
  final double size;

  /// 默认图标尺寸。
  final double iconSize;

  /// 外观。
  final FluentIconButtonAppearance appearance;

  /// 无障碍标签。
  final String? semanticLabel;

  @override
  State<FluentIconButton> createState() => _FluentIconButtonState();
}

class _FluentIconButtonState extends State<FluentIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final stroke = context.fluentStroke;
    final motion = context.fluentMotion;

    final Color foreground = _enabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;
    final Color background = !_enabled
        ? Colors.transparent
        : _pressed
        ? colors.subtleBackgroundPressed
        : _hovered
        ? colors.subtleBackgroundHover
        : widget.appearance == FluentIconButtonAppearance.outline
        ? colors.neutralBackground1
        : Colors.transparent;
    final Color? border = widget.appearance == FluentIconButtonAppearance.outline
        ? (_focused ? colors.brandStroke1 : colors.neutralStroke1)
        : (_focused ? colors.brandStroke1 : null);

    Widget result = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.tooltip,
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
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: AnimatedContainer(
                duration: motion.durationFaster,
                curve: motion.curveEasyEase,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: radii.mediumBorder,
                  border: border == null
                      ? null
                      : Border.all(
                          color: border,
                          width: _focused ? stroke.thick : stroke.thin,
                        ),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground, size: widget.iconSize),
                  child: Center(child: widget.icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}
