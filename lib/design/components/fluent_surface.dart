/*
 * Fluent 通用表面兼容层 — 包装外部 fluent_ui Card / HoverButton
 * @Project : SSPU-AllinOne
 * @File : fluent_surface.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

/// Fluent 表面容器，支持悬停 / 点击交互。
class FluentSurface extends StatelessWidget {
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

  /// 强调色（悬停描边）；默认外部 Fluent 强调色。
  final Color? accentColor;

  /// 点击回调。
  final VoidCallback? onPressed;

  /// 是否使用更轻背景。
  final bool subtle;

  /// 是否保持较高层级；外部 Card 负责默认卡片视觉。
  final bool elevated;

  /// 圆角；默认 radiusLarge。
  final BorderRadiusGeometry? borderRadius;

  /// 交互态无障碍语义标签。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = _outer(_surface(context));
    if (onPressed == null) return content;

    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      child: HoverButton(
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        builder: (context, states) => _outer(_surface(context, states: states)),
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

  Widget _surface(BuildContext context, {Set<WidgetState> states = const {}}) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final hovered = states.isHovered || states.isFocused;
    final accent = accentColor ?? theme.accentColor.defaultBrushFor(theme.brightness);

    final Color background = hovered
        ? resources.subtleFillColorSecondary
        : subtle
        ? resources.systemFillColorSolidNeutralBackground
        : theme.cardColor;

    return Card(
      padding: padding ?? EdgeInsets.all(spacing.l),
      borderRadius: borderRadius ?? radii.largeBorder,
      backgroundColor: background,
      borderColor: hovered || states.isFocused
          ? accent
          : colors.neutralStroke2,
      child: child,
    );
  }
}

/// Fluent 图标锚点容器，用于摘要 / 操作卡片的统一视觉锚点。
class FluentSurfaceIcon extends StatelessWidget {
  const FluentSurfaceIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  /// 图标。
  final IconData icon;

  /// 图标与背景强调色；默认外部 Fluent 强调色。
  final Color? color;

  /// 容器尺寸。
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final radii = context.fluentRadii;
    final accent = color ?? theme.accentColor.defaultBrushFor(theme.brightness);

    return Card(
      padding: EdgeInsets.zero,
      borderRadius: radii.mediumBorder,
      backgroundColor: theme.resources.controlAltFillColorSecondary,
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, color: accent, size: size * 0.5),
      ),
    );
  }
}
