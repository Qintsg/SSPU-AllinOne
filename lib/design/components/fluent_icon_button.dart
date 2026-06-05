/*
 * Fluent 图标按钮兼容层 — 包装外部 fluent_ui IconButton / Tooltip
 * @Project : SSPU-AllinOne
 * @File : fluent_icon_button.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

/// Fluent 图标按钮外观。
enum FluentIconButtonAppearance {
  /// 透明背景。
  transparent,

  /// 描边背景。
  outline,
}

/// Fluent 图标按钮。
class FluentIconButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      iconSize: WidgetStatePropertyAll(iconSize),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radii.mediumBorder),
      ),
      backgroundColor: appearance == FluentIconButtonAppearance.outline
          ? WidgetStateProperty.resolveWith((states) {
              if (states.isPressed) return colors.subtleBackgroundPressed;
              if (states.isHovered || states.isFocused) {
                return colors.subtleBackgroundHover;
              }
              return FluentTheme.of(context).cardColor;
            })
          : null,
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) return colors.neutralForegroundDisabled;
        return colors.neutralForeground2;
      }),
    );

    Widget result = Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? tooltip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: SizedBox.square(
            dimension: size,
            child: IconButton(
              icon: IconTheme.merge(
                data: IconThemeData(size: iconSize),
                child: icon,
              ),
              onPressed: onPressed,
              style: style,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }
    return result;
  }
}
