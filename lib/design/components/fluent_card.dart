/*
 * Fluent 卡片兼容层 — 包装外部 fluent_ui Card / HoverButton
 * @Project : SSPU-AllinOne
 * @File : fluent_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

/// Fluent 卡片。
class FluentCard extends StatelessWidget {
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

  /// 点击回调。
  final VoidCallback? onPressed;

  /// 固定宽度。
  final double? width;

  /// 最小高度。
  final double? minHeight;

  /// 是否保持较高层级；外部 Card 负责默认卡片视觉。
  final bool elevated;

  /// 是否显示边框。
  final bool bordered;

  /// 交互态无障碍语义标签。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = _outer(_card(context));
    if (onPressed == null) return content;

    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      child: HoverButton(
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        builder: (context, states) => _outer(_card(context, states: states)),
      ),
    );
  }

  Widget _outer(Widget child) {
    return Padding(
      padding: margin,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: onPressed == null ? 0 : 48,
          minHeight: minHeight ?? (onPressed == null ? 0 : 48),
        ),
        child: SizedBox(width: width, child: child),
      ),
    );
  }

  Widget _card(BuildContext context, {Set<WidgetState> states = const {}}) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final resources = FluentTheme.of(context).resources;
    final hovered = states.isHovered || states.isFocused;

    return Card(
      padding: padding ?? EdgeInsets.all(spacing.l),
      borderRadius: radii.largeBorder,
      backgroundColor: hovered
          ? resources.subtleFillColorSecondary
          : FluentTheme.of(context).cardColor,
      borderColor: bordered || states.isFocused
          ? (hovered ? colors.brandStroke1 : resources.controlStrokeColorDefault)
          : null,
      child: child,
    );
  }
}
