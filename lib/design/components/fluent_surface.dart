/*
 * Fluent 2 通用表面 — 卡片容器 / 图标锚点，令牌驱动
 * @Project : SSPU-AllinOne
 * @File : fluent_surface.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 表面容器，支持悬停 / 按下交互态。
class FluentSurface extends StatefulWidget {
  const FluentSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.width,
    this.minHeight,
    this.accentColor,
    this.onPressed,
    this.subtle = false,
    this.elevated = true,
    this.borderRadius,
    this.semanticLabel,
  });

  /// 内容。
  final Widget child;

  /// 内边距；默认 spacingL。
  final EdgeInsetsGeometry? padding;

  /// 外边距。
  final EdgeInsetsGeometry margin;

  /// 固定宽度。
  final double? width;

  /// 最小高度。
  final double? minHeight;

  /// 强调色（悬停描边 / 淡填充）；默认 brandStroke1。
  final Color? accentColor;

  /// 点击回调。
  final VoidCallback? onPressed;

  /// 是否使用更轻背景（嵌套摘要行）。
  final bool subtle;

  /// 是否启用阴影层级。
  final bool elevated;

  /// 圆角；默认 radiusLarge。
  final BorderRadiusGeometry? borderRadius;

  /// 交互态无障碍语义标签。
  final String? semanticLabel;

  @override
  State<FluentSurface> createState() => _FluentSurfaceState();
}

class _FluentSurfaceState extends State<FluentSurface> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _interactive => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final elevation = context.fluentElevation;
    final motion = context.fluentMotion;
    final Color accent = widget.accentColor ?? colors.brandStroke1;

    final Color background;
    if (_interactive && _hovered) {
      background = colors.subtleBackgroundHover;
    } else if (widget.subtle) {
      background = colors.neutralBackground2;
    } else {
      background = colors.neutralBackground1;
    }

    final Color border = _interactive && (_hovered || _focused)
        ? accent
        : colors.neutralStroke2;
    final double borderWidth = _interactive && _focused
        ? stroke.thick
        : stroke.thin;

    final List<BoxShadow> shadows = widget.elevated && !widget.subtle
        ? (_interactive && _hovered ? elevation.shadow8 : elevation.shadow4)
        : const <BoxShadow>[];

    Widget surface = AnimatedContainer(
      duration: motion.durationNormal,
      curve: motion.curveEasyEase,
      margin: widget.margin,
      padding: widget.padding ?? EdgeInsets.all(spacing.l),
      width: widget.width,
      constraints: widget.minHeight == null
          ? null
          : BoxConstraints(minHeight: widget.minHeight!),
      decoration: BoxDecoration(
        color: background,
        borderRadius: widget.borderRadius ?? radii.largeBorder,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    surface = AnimatedScale(
      scale: _pressed ? 0.995 : (_hovered && _interactive ? 1.004 : 1),
      duration: motion.durationFaster,
      curve: motion.curveEasyEase,
      child: surface,
    );

    if (!_interactive) return surface;

    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
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
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: surface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fluent 2 图标锚点容器，用于摘要 / 操作卡片的统一视觉锚点。
class FluentSurfaceIcon extends StatelessWidget {
  const FluentSurfaceIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  /// 图标。
  final IconData icon;

  /// 图标与背景强调色；默认 brandForeground1。
  final Color? color;

  /// 容器尺寸。
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final Color accent = color ?? colors.brandForeground1;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.neutralBackground3,
        borderRadius: radii.mediumBorder,
      ),
      child: Icon(icon, color: accent, size: size * 0.5),
    );
  }
}
