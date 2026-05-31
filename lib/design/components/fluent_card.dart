/*
 * Fluent 2 卡片 — 表面 / 圆角 / 内边距 / 阴影全走令牌
 * @Project : SSPU-AllinOne
 * @File : fluent_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 令牌映射见 DESIGN.md §6.3：表面 neutralBackground1；圆角 radiusLarge；
 * 内边距 spacingL；默认 shadow4，可悬停卡片 hover 升至 shadow8。
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 卡片。
class FluentCard extends StatefulWidget {
  const FluentCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.onPressed,
    this.width,
    this.minHeight,
    this.elevated = true,
    this.bordered = false,
    this.semanticLabel,
  });

  /// 卡片内容。
  final Widget child;

  /// 内边距；默认 spacingL。
  final EdgeInsetsGeometry? padding;

  /// 外边距。
  final EdgeInsetsGeometry margin;

  /// 点击回调；非空时悬停升高阴影。
  final VoidCallback? onPressed;

  /// 固定宽度。
  final double? width;

  /// 最小高度。
  final double? minHeight;

  /// 是否带默认阴影 shadow4。
  final bool elevated;

  /// 是否改用描边而非阴影（用于嵌套 / 弱层级）。
  final bool bordered;

  /// 交互态无障碍语义标签。
  final String? semanticLabel;

  @override
  State<FluentCard> createState() => _FluentCardState();
}

class _FluentCardState extends State<FluentCard> {
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

    final List<BoxShadow> shadows;
    if (widget.bordered || !widget.elevated) {
      shadows = const <BoxShadow>[];
    } else if (_interactive && _hovered) {
      shadows = elevation.shadow8;
    } else {
      shadows = elevation.shadow4;
    }

    Widget content = AnimatedContainer(
      duration: motion.durationFast,
      curve: motion.curveEasyEase,
      width: widget.width,
      margin: widget.margin,
      padding: widget.padding ?? EdgeInsets.all(spacing.l),
      constraints: widget.minHeight == null
          ? null
          : BoxConstraints(minHeight: widget.minHeight!),
      decoration: BoxDecoration(
        color: colors.neutralBackground1,
        borderRadius: radii.largeBorder,
        border: widget.bordered || (_interactive && _focused)
            ? Border.all(
                color: (_hovered || _focused) && _interactive
                    ? colors.brandStroke1
                    : colors.neutralStroke2,
                width: _focused ? stroke.thick : stroke.thin,
              )
            : null,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    content = AnimatedScale(
      scale: _pressed ? 0.995 : 1,
      duration: motion.durationFaster,
      curve: motion.curveEasyEase,
      child: content,
    );

    if (!_interactive) return content;

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
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
