/*
 * Fluent 2 按钮 — 5 外观 × 3 尺寸，交互态 / 禁用态 / 焦点环全走令牌
 * @Project : SSPU-AllinOne
 * @File : fluent_button.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 令牌映射见 DESIGN.md §6.1。
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';
import '../fluent/tokens/fluent_color_tokens.dart';

/// 按钮外观。
enum FluentButtonAppearance {
  /// 主操作，一屏至多一个：brandBackground 填充 + 白前景。
  primary,

  /// 常规操作（默认）：neutralBackground1 + neutralStroke1 1px。
  secondary,

  /// 次要操作：透明 + neutralStroke1 1px。
  outline,

  /// 工具栏 / 低强调：透明无边框 + neutralForeground2。
  subtle,

  /// 类链接操作：透明无边框 + brandForeground1。
  transparent,
}

/// 按钮尺寸。
enum FluentButtonSize {
  /// 24 高 / 内边距 spacingS / caption1。
  small,

  /// 32 高 / 内边距 spacingM / body1（默认）。
  medium,

  /// 40 高 / 内边距 spacingL / body1Strong。
  large,
}

/// Fluent 2 按钮。
class FluentButton extends StatefulWidget {
  const FluentButton({
    super.key,
    required this.child,
    this.onPressed,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.icon,
    this.expand = false,
    this.semanticLabel,
  });

  /// 主操作便捷构造。
  const FluentButton.primary({
    super.key,
    required this.child,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.icon,
    this.expand = false,
    this.semanticLabel,
  }) : appearance = FluentButtonAppearance.primary;

  /// 常规操作便捷构造。
  const FluentButton.secondary({
    super.key,
    required this.child,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.icon,
    this.expand = false,
    this.semanticLabel,
  }) : appearance = FluentButtonAppearance.secondary;

  /// 描边操作便捷构造。
  const FluentButton.outline({
    super.key,
    required this.child,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.icon,
    this.expand = false,
    this.semanticLabel,
  }) : appearance = FluentButtonAppearance.outline;

  /// 低强调操作便捷构造。
  const FluentButton.subtle({
    super.key,
    required this.child,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.icon,
    this.expand = false,
    this.semanticLabel,
  }) : appearance = FluentButtonAppearance.subtle;

  /// 透明操作便捷构造。
  const FluentButton.transparent({
    super.key,
    required this.child,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.icon,
    this.expand = false,
    this.semanticLabel,
  }) : appearance = FluentButtonAppearance.transparent;

  /// 主操作图标按钮便捷构造。
  FluentButton.primaryIcon({
    super.key,
    required Widget icon,
    required Widget label,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.expand = false,
    this.semanticLabel,
  }) : child = _FluentInlineButtonContent(icon: icon, label: label),
       icon = null,
       appearance = FluentButtonAppearance.primary;

  /// 常规图标按钮便捷构造。
  FluentButton.secondaryIcon({
    super.key,
    required Widget icon,
    required Widget label,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.expand = false,
    this.semanticLabel,
  }) : child = _FluentInlineButtonContent(icon: icon, label: label),
       icon = null,
       appearance = FluentButtonAppearance.secondary;

  /// 描边图标按钮便捷构造。
  FluentButton.outlineIcon({
    super.key,
    required Widget icon,
    required Widget label,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.expand = false,
    this.semanticLabel,
  }) : child = _FluentInlineButtonContent(icon: icon, label: label),
       icon = null,
       appearance = FluentButtonAppearance.outline;

  /// 透明图标按钮便捷构造。
  FluentButton.transparentIcon({
    super.key,
    required Widget icon,
    required Widget label,
    this.onPressed,
    this.size = FluentButtonSize.medium,
    this.expand = false,
    this.semanticLabel,
  }) : child = _FluentInlineButtonContent(icon: icon, label: label),
       icon = null,
       appearance = FluentButtonAppearance.transparent;

  /// 子内容（通常为文本）。
  final Widget child;

  /// 点击回调；为空时为禁用态。
  final VoidCallback? onPressed;

  /// 外观。
  final FluentButtonAppearance appearance;

  /// 尺寸。
  final FluentButtonSize size;

  /// 可选前置图标。
  final IconData? icon;

  /// 是否占满可用宽度。
  final bool expand;

  /// 无障碍语义标签。
  final String? semanticLabel;

  @override
  State<FluentButton> createState() => _FluentButtonState();
}

class _FluentButtonState extends State<FluentButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final type = context.fluentType;
    final motion = context.fluentMotion;

    final double height;
    final double padH;
    final TextStyle textStyle;
    switch (widget.size) {
      case FluentButtonSize.small:
        height = 24;
        padH = spacing.s;
        textStyle = type.caption1;
      case FluentButtonSize.medium:
        height = 32;
        padH = spacing.m;
        textStyle = type.body1;
      case FluentButtonSize.large:
        height = 40;
        padH = spacing.l;
        textStyle = type.body1Strong;
    }

    final _Visual v = _resolveVisual(colors);

    final Widget label = DefaultTextStyle.merge(
      style: textStyle.copyWith(color: v.foreground),
      child: IconTheme.merge(
        data: IconThemeData(color: v.foreground, size: 16),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon),
              SizedBox(width: spacing.s),
            ],
            Flexible(child: widget.child),
          ],
        ),
      ),
    );

    final Widget visual = AnimatedContainer(
      duration: motion.durationFaster,
      curve: motion.curveEasyEase,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padH),
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: radii.mediumBorder,
        border: v.border == null
            ? null
            : Border.all(color: v.border!, width: stroke.thin),
      ),
      child: Center(widthFactor: widget.expand ? null : 1, child: label),
    );

    // 焦点环：strokeWidthThick + brandStroke1（DESIGN.md §6.1 / §7）。
    final Widget focusable = AnimatedContainer(
      duration: motion.durationFaster,
      curve: motion.curveEasyEase,
      padding: EdgeInsets.all(_focused ? stroke.thick : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          radii.medium + (_focused ? stroke.thick : 0),
        ),
        border: _focused
            ? Border.all(color: colors.brandStroke1, width: stroke.thick)
            : null,
      ),
      child: visual,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      // FocusableActionDetector 统一焦点 / 悬停 / 键盘激活：
      // ActivateIntent 由 Flutter 默认快捷键映射 Enter / Space（DESIGN.md §7）。
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (f) => setState(() => _focused = f),
        onShowHoverHighlight: (h) => setState(() {
          _hovered = h;
          if (!h) _pressed = false;
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
          onTapDown: _enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: _enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: _enabled
              ? () => setState(() => _pressed = false)
              : null,
          // 命中区域最小 48dp（DESIGN.md §7）。
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              heightFactor: 1,
              widthFactor: widget.expand ? null : 1,
              child: focusable,
            ),
          ),
        ),
      ),
    );
  }

  _Visual _resolveVisual(FluentColors c) {
    if (!_enabled) {
      final Color disabledFg = c.neutralForegroundDisabled;
      switch (widget.appearance) {
        case FluentButtonAppearance.primary:
        case FluentButtonAppearance.secondary:
          return _Visual(c.neutralBackground3, disabledFg, c.neutralStroke2);
        case FluentButtonAppearance.outline:
          return _Visual(Colors.transparent, disabledFg, c.neutralStroke2);
        case FluentButtonAppearance.subtle:
        case FluentButtonAppearance.transparent:
          return _Visual(Colors.transparent, disabledFg, null);
      }
    }

    switch (widget.appearance) {
      case FluentButtonAppearance.primary:
        final Color bg = _pressed
            ? c.brandBackgroundPressed
            : _hovered
            ? c.brandBackgroundHover
            : c.brandBackground;
        return _Visual(bg, c.neutralForegroundOnBrand, null);
      case FluentButtonAppearance.secondary:
        final Color bg = _pressed
            ? c.neutralBackground1Pressed
            : _hovered
            ? c.neutralBackground1Hover
            : c.neutralBackground1;
        return _Visual(bg, c.neutralForeground1, c.neutralStroke1);
      case FluentButtonAppearance.outline:
        final Color bg = _pressed
            ? c.subtleBackgroundPressed
            : _hovered
            ? c.subtleBackgroundHover
            : Colors.transparent;
        return _Visual(bg, c.neutralForeground1, c.neutralStroke1);
      case FluentButtonAppearance.subtle:
        final Color bg = _pressed
            ? c.subtleBackgroundPressed
            : _hovered
            ? c.subtleBackgroundHover
            : Colors.transparent;
        return _Visual(bg, c.neutralForeground2, null);
      case FluentButtonAppearance.transparent:
        final Color fg = _pressed
            ? c.brandForeground2
            : c.brandForeground1;
        final Color bg = _hovered
            ? c.subtleBackgroundHover
            : Colors.transparent;
        return _Visual(bg, fg, null);
    }
  }
}

class _Visual {
  const _Visual(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color? border;
}

class _FluentInlineButtonContent extends StatelessWidget {
  const _FluentInlineButtonContent({required this.icon, required this.label});

  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [icon, SizedBox(width: spacing.sNudge), label],
    );
  }
}
