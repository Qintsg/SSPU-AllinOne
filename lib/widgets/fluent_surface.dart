/*
 * Material 3 通用视觉组件 — 统一页面 surface、图标与标题样式
 * @Project : SSPU-AllinOne
 * @File : fluent_surface.dart
 * @Author : Qintsg
 * @Date : 2026-05-09
 */

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';

/// Material 3 卡片 surface。
/// 保留旧类名以降低迁移期间调用方改动，内部已改为 Material 3 token。
class FluentSurface extends StatefulWidget {
  /// surface 内部内容。
  final Widget child;

  /// 内边距。
  final EdgeInsetsGeometry padding;

  /// 外边距。
  final EdgeInsetsGeometry margin;

  /// 宽度。
  final double? width;

  /// 最小高度。
  final double? minHeight;

  /// 强调色，用于悬停边框与淡色填充。
  final Color? accentColor;

  /// 点击回调；为空时仅作为静态容器。
  final VoidCallback? onPressed;

  /// 是否使用更轻的背景，适合嵌套摘要行。
  final bool subtle;

  /// 是否启用阴影层级。
  final bool elevated;

  /// 圆角。
  final BorderRadiusGeometry borderRadius;

  const FluentSurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.width,
    this.minHeight,
    this.accentColor,
    this.onPressed,
    this.subtle = false,
    this.elevated = true,
    this.borderRadius = AppShapes.lg,
  });

  @override
  State<FluentSurface> createState() => _FluentSurfaceState();
}

class _FluentSurfaceState extends State<FluentSurface> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isInteractive => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = widget.accentColor ?? colorScheme.primary;
    final backgroundColor = _resolveBackgroundColor(colorScheme, accentColor);
    final borderColor = _resolveBorderColor(colorScheme, accentColor);

    Widget surfaceContent = AnimatedContainer(
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: widget.borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: widget.child,
    );

    if (widget.minHeight != null) {
      surfaceContent = ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight!),
        child: surfaceContent,
      );
    }

    if (widget.width != null) {
      surfaceContent = SizedBox(width: widget.width, child: surfaceContent);
    }

    final surface = AnimatedScale(
      scale: _isPressed ? 0.995 : (_isHovered && _isInteractive ? 1.004 : 1),
      duration: AppMotion.short,
      curve: Curves.easeOutCubic,
      child: surfaceContent,
    );

    return MouseRegion(
      cursor: _isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: _isInteractive ? (_) => setState(() => _isPressed = true) : null,
        onTapCancel: _isInteractive ? () => setState(() => _isPressed = false) : null,
        onTapUp: _isInteractive ? (_) => setState(() => _isPressed = false) : null,
        child: surface,
      ),
    );
  }

  Color _resolveBackgroundColor(ColorScheme colorScheme, Color accentColor) {
    if (_isHovered && _isInteractive) {
      return accentColor.withValues(alpha: 0.10);
    }
    if (widget.subtle) {
      return colorScheme.surfaceContainerHighest;
    }
    return widget.elevated
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;
  }

  Color _resolveBorderColor(ColorScheme colorScheme, Color accentColor) {
    if (_isHovered && _isInteractive) {
      return accentColor.withValues(alpha: 0.32);
    }
    return colorScheme.outlineVariant;
  }
}

/// Material 3 图标容器，用于页面摘要和操作卡片的统一视觉锚点。
class FluentSurfaceIcon extends StatelessWidget {
  /// 图标。
  final IconData icon;

  /// 图标与背景强调色。
  final Color color;

  /// 容器尺寸。
  final double size;

  const FluentSurfaceIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppShapes.md,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// 页面分区标题，统一标题、说明和右侧操作的横向排列。
class FluentSectionHeader extends StatelessWidget {
  /// 标题文本。
  final String title;

  /// 说明文本。
  final String? subtitle;

  /// 左侧图标。
  final IconData? icon;

  /// 图标强调色。
  final Color? accentColor;

  /// 右侧操作组件。
  final Widget? action;

  const FluentSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resolvedAccentColor = accentColor ?? colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          FluentSurfaceIcon(icon: icon!, color: resolvedAccentColor),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: textTheme.titleMedium),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.md),
          action!,
        ],
      ],
    );
  }
}
