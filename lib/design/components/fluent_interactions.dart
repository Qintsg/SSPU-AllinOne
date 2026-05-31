/*
 * Fluent 2 交互辅助组件 — 悬停与按下状态统一封装
 * @Project : SSPU-AllinOne
 * @File : fluent_interactions.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:flutter/material.dart';

/// Fluent 2 悬停按钮状态。
class FluentHoverButtonStates {
  const FluentHoverButtonStates({
    required this.isHovered,
    required this.isPressed,
  });

  /// 是否悬停。
  final bool isHovered;

  /// 是否按下。
  final bool isPressed;
}

/// Fluent 2 无默认视觉的悬停按钮。
class FluentHoverButton extends StatefulWidget {
  const FluentHoverButton({
    super.key,
    required this.onPressed,
    required this.builder,
  });

  /// 点击回调。
  final VoidCallback? onPressed;

  /// 状态构建器。
  final Widget Function(BuildContext context, FluentHoverButtonStates states)
  builder;

  @override
  State<FluentHoverButton> createState() => _FluentHoverButtonState();
}

class _FluentHoverButtonState extends State<FluentHoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onPressed == null
            ? null
            : () => setState(() => _pressed = false),
        child: widget.builder(
          context,
          FluentHoverButtonStates(isHovered: _hovered, isPressed: _pressed),
        ),
      ),
    );
  }
}
