/*
 * Fluent 按钮兼容层 — 旧项目 API 包装外部 fluent_ui 按钮控件
 * @Project : SSPU-AllinOne
 * @File : fluent_button.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

/// 按钮外观。
enum FluentButtonAppearance {
  /// 主操作。
  primary,

  /// 常规操作。
  secondary,

  /// 描边操作。
  outline,

  /// 低强调操作。
  subtle,

  /// 链接/透明操作。
  transparent,
}

/// 按钮尺寸。
enum FluentButtonSize {
  /// 小按钮。
  small,

  /// 默认按钮。
  medium,

  /// 大按钮。
  large,
}

/// Fluent 按钮兼容组件，内部统一使用外部 `fluent_ui` 按钮控件。
class FluentButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final button = ButtonTheme.merge(
      data: ButtonThemeData.all(_styleFor(context)),
      child: _buildButton(_contentFor(context)),
    );

    final result = Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: expand ? null : 1,
          child: SizedBox(width: expand ? double.infinity : null, child: button),
        ),
      ),
    );
    return result;
  }

  Widget _buildButton(Widget content) {
    return switch (appearance) {
      FluentButtonAppearance.primary => FilledButton(
        onPressed: onPressed,
        child: content,
      ),
      FluentButtonAppearance.secondary => Button(
        onPressed: onPressed,
        child: content,
      ),
      FluentButtonAppearance.outline => OutlinedButton(
        onPressed: onPressed,
        child: content,
      ),
      FluentButtonAppearance.subtle => Button(
        onPressed: onPressed,
        child: content,
      ),
      FluentButtonAppearance.transparent => HyperlinkButton(
        onPressed: onPressed,
        child: content,
      ),
    };
  }

  Widget _contentFor(BuildContext context) {
    if (icon == null) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        SizedBox(width: context.fluentSpacing.s),
        Flexible(child: child),
      ],
    );
  }

  ButtonStyle _styleFor(BuildContext context) {
    final type = context.fluentType;
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;

    final EdgeInsetsGeometry padding;
    final TextStyle textStyle;
    switch (size) {
      case FluentButtonSize.small:
        padding = EdgeInsetsDirectional.symmetric(
          horizontal: spacing.s,
          vertical: 3,
        );
        textStyle = type.caption1;
      case FluentButtonSize.medium:
        padding = EdgeInsetsDirectional.symmetric(
          horizontal: spacing.m,
          vertical: 5,
        );
        textStyle = type.body1;
      case FluentButtonSize.large:
        padding = EdgeInsetsDirectional.symmetric(
          horizontal: spacing.l,
          vertical: 8,
        );
        textStyle = type.body1Strong;
    }

    return ButtonStyle(
      padding: WidgetStatePropertyAll(padding),
      textStyle: WidgetStatePropertyAll(textStyle),
      iconSize: const WidgetStatePropertyAll(16),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radii.mediumBorder),
      ),
      backgroundColor: appearance == FluentButtonAppearance.subtle
          ? WidgetStateProperty.resolveWith((states) {
              if (states.isDisabled) return Colors.transparent;
              if (states.isPressed) return colors.subtleBackgroundPressed;
              if (states.isHovered || states.isFocused) {
                return colors.subtleBackgroundHover;
              }
              return Colors.transparent;
            })
          : null,
      foregroundColor: appearance == FluentButtonAppearance.subtle
          ? WidgetStateProperty.resolveWith((states) {
              if (states.isDisabled) return colors.neutralForegroundDisabled;
              return colors.neutralForeground2;
            })
          : null,
    );
  }
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
