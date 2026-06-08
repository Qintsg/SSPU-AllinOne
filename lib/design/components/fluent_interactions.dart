/*
 * Fluent 2 交互辅助组件 — 悬停与按下状态统一封装
 * @Project : SSPU-AllinOne
 * @File : fluent_interactions.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:fluent_ui/fluent_ui.dart' as fluent hide FluentIcons;

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
class FluentHoverButton extends fluent.StatelessWidget {
  const FluentHoverButton({
    super.key,
    required this.onPressed,
    required this.builder,
  });

  /// 点击回调。
  final fluent.VoidCallback? onPressed;

  /// 状态构建器。
  final fluent.Widget Function(
    fluent.BuildContext context,
    FluentHoverButtonStates states,
  )
  builder;

  @override
  fluent.Widget build(fluent.BuildContext context) {
    return fluent.HoverButton(
      onPressed: onPressed,
      builder: (context, states) => builder(
        context,
        FluentHoverButtonStates(
          isHovered: states.contains(fluent.WidgetState.hovered),
          isPressed: states.contains(fluent.WidgetState.pressed),
        ),
      ),
    );
  }
}
