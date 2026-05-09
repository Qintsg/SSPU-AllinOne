/*
 * Fluent 2 通用视觉组件 — 统一页面 surface、图标与标题样式
 * @Project : SSPU-all-in-one
 * @File : fluent_surface.dart
 * @Author : Qintsg
 * @Date : 2026-05-09
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../theme/fluent_tokens.dart';

/// Fluent 2 卡片 surface。
/// 集中处理浅/暗色背景、描边、阴影、悬停和按压反馈，避免各页面重复硬编码视觉状态。
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
    this.padding = const EdgeInsets.all(FluentSpacing.xl),
    this.margin = EdgeInsets.zero,
    this.width,
    this.minHeight,
    this.accentColor,
    this.onPressed,
    this.subtle = false,
    this.elevated = true,
    this.borderRadius = FluentRadius.card,
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
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.accentColor ?? theme.accentColor;
    final backgroundColor = _resolveBackgroundColor(theme, isDark, accentColor);
    final borderColor = _resolveBorderColor(isDark, accentColor);
    final shadows = _resolveShadows(isDark);

    final surface = AnimatedScale(
      scale: _isPressed ? 0.995 : (_isHovered && _isInteractive ? 1.004 : 1),
      duration: FluentDuration.fast,
      curve: FluentEasing.decelerate,
      child: AnimatedContainer(
        width: widget.width,
        constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
        duration: FluentDuration.normal,
        curve: FluentEasing.decelerate,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: widget.borderRadius,
          border: Border.all(color: borderColor),
          boxShadow: widget.elevated ? shadows : null,
        ),
        child: widget.child,
      ),
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
        onTapDown: _isInteractive
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapCancel: _isInteractive
            ? () => setState(() => _isPressed = false)
            : null,
        onTapUp: _isInteractive
            ? (_) => setState(() => _isPressed = false)
            : null,
        child: surface,
      ),
    );
  }

  Color _resolveBackgroundColor(
    FluentThemeData theme,
    bool isDark,
    Color accentColor,
  ) {
    if (_isHovered && _isInteractive) {
      return accentColor.withValues(alpha: isDark ? 0.16 : 0.08);
    }
    if (widget.subtle) {
      return theme.resources.controlAltFillColorSecondary;
    }
    return isDark
        ? FluentDarkColors.backgroundCard
        : FluentLightColors.backgroundCard;
  }

  Color _resolveBorderColor(bool isDark, Color accentColor) {
    if (_isHovered && _isInteractive) {
      return accentColor.withValues(alpha: isDark ? 0.42 : 0.28);
    }
    return isDark
        ? FluentDarkColors.borderSubtle
        : FluentLightColors.borderSubtle;
  }

  List<BoxShadow> _resolveShadows(bool isDark) {
    if (_isPressed && _isInteractive) {
      return isDark
          ? FluentElevation.cardPressedDark
          : FluentElevation.cardPressed;
    }
    if (_isHovered && _isInteractive) {
      return isDark ? FluentElevation.cardHoverDark : FluentElevation.cardHover;
    }
    return isDark ? FluentElevation.cardRestDark : FluentElevation.cardRest;
  }
}

/// Fluent 2 图标容器，用于页面摘要和操作卡片的统一视觉锚点。
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
        borderRadius: BorderRadius.circular(FluentRadius.xLarge),
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
    final theme = FluentTheme.of(context);
    final resolvedAccentColor = accentColor ?? theme.accentColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          FluentSurfaceIcon(icon: icon!, color: resolvedAccentColor),
          const SizedBox(width: FluentSpacing.m),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.typography.bodyStrong),
              if (subtitle != null) ...[
                const SizedBox(height: FluentSpacing.xxs),
                Text(
                  subtitle!,
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: FluentSpacing.m),
          action!,
        ],
      ],
    );
  }
}
