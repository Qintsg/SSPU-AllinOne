/*
 * 清源主题下的 Miuix 表面与操作控件
 * @Project : SSPU-AllinOne
 * @File : yh_miuix.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';

/// 将品牌主题映射到 Miuix 的颜色角色。
miuix.MiuixColors yhMiuixColors(YhColorTokens color) {
  final isDark = color.background.computeLuminance() < 0.5;
  final scheme = isDark ? miuix.darkColorScheme() : miuix.lightColorScheme();
  return scheme.copy(
    primary: color.brandStrong,
    onPrimary: color.onBrand,
    primaryContainer: color.brandTint,
    onPrimaryContainer: color.brandInk,
    secondaryVariant: color.brandTint,
    onSecondaryVariant: color.brandInk,
    background: color.background,
    onBackground: color.foreground,
    surface: color.surface,
    onSurface: color.foreground,
    surfaceVariant: color.sunken,
    surfaceContainer: color.surface,
    onSurfaceContainer: color.foreground,
    onSurfaceVariantSummary: color.muted,
    outline: color.border,
    dividerLine: color.border,
    error: color.danger,
    errorContainer: color.dangerTint,
    windowDimming: color.scrim,
  );
}

/// 让使用清源语义令牌的页面跟随 Miuix 动态色。
YhTheme yhThemeWithMonet(YhTheme base, miuix.MiuixColors palette) {
  final color = base.color;
  return base.copyWith(
    color: YhColorTokens(
      background: palette.background,
      surface: palette.surfaceContainer,
      sunken: palette.surfaceContainerHigh,
      foreground: palette.onBackground,
      muted: palette.onSurfaceVariantSummary,
      border: palette.dividerLine,
      brand: palette.primary,
      brandStrong: palette.primary,
      brandTint: palette.primaryContainer,
      brandInk: palette.onPrimaryContainer,
      onBrand: palette.onPrimary,
      structural: palette.secondary,
      onStructural: palette.onSecondary,
      success: color.success,
      successTint: color.successTint,
      warning: color.warning,
      warningTint: color.warningTint,
      danger: palette.error,
      dangerTint: palette.errorContainer,
      serviceAcademic: color.serviceAcademic,
      serviceSchedule: color.serviceSchedule,
      serviceNews: color.serviceNews,
      serviceMail: color.serviceMail,
      serviceFinance: color.serviceFinance,
      serviceSports: color.serviceSports,
      serviceSecondClass: color.serviceSecondClass,
      serviceQuickLink: color.serviceQuickLink,
      scrim: palette.windowDimming,
    ),
  );
}

/// 为独立使用的组件提供主题，应用内部使用根节点统一生成的主题。
class YhMiuixTheme extends StatelessWidget {
  const YhMiuixTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<miuix.MiuixTheme>() !=
        null) {
      return child;
    }
    final color = context.yhTheme.color;
    final isDark = color.background.computeLuminance() < 0.5;
    return miuix.MiuixTheme(
      data: miuix.MiuixThemeData.of(
        isDark ? Brightness.dark : Brightness.light,
        textStyles: miuix.defaultTextStyles(),
        fontWeightAdjustment: MediaQuery.boldTextOf(context) ? 100 : 0,
      ).copyWith(colors: yhMiuixColors(color)),
      child: child,
    );
  }
}

/// 以 Miuix 超椭圆表面承载同一组内容。
class YhMiuixCard extends StatelessWidget {
  const YhMiuixCard({
    super.key,
    this.padding,
    this.color,
    this.foreground,
    required this.child,
  });

  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return miuix.MiuixCard(
      insideMargin: padding ?? EdgeInsets.all(theme.spacing.l),
      colors: miuix.MiuixCardColors(
        color: color ?? theme.color.surface,
        contentColor: foreground ?? theme.color.foreground,
      ),
      child: child,
    );
  }
}

/// 页面的大标题及同一层级的操作。
class YhPageHeading extends StatelessWidget {
  const YhPageHeading({
    super.key,
    required this.title,
    this.summary,
    this.trailing,
  });

  final String title;
  final String? summary;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: theme.typography.h1),
              ),
              if (summary case final text? when text.isNotEmpty) ...[
                SizedBox(height: theme.spacing.xs),
                Text(
                  text,
                  style: theme.typography.body.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[SizedBox(width: theme.spacing.s), trailing!],
      ],
    );
  }
}

/// 支持换行和键盘操作的 Miuix 标签按钮。
class YhMiuixButton extends StatelessWidget {
  const YhMiuixButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhMiuixTheme(
      child: miuix.MiuixButton(
        onPressed: onPressed,
        minHeight: theme.control.minimumTarget,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              miuix.MiuixIcon(icon: icon),
              SizedBox(width: theme.spacing.s),
            ],
            Flexible(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

/// 带操作含义和简短说明的 Miuix 查询入口。
class YhMiuixQueryRow extends StatelessWidget {
  const YhMiuixQueryRow({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhMiuixTheme(
      child: miuix.MiuixBasicComponent(
        title: title,
        summary: detail,
        onClick: onPressed,
        enabled: onPressed != null,
        insideMargin: EdgeInsets.symmetric(
          horizontal: theme.spacing.s,
          vertical: theme.spacing.s,
        ),
        startAction: Padding(
          padding: EdgeInsetsDirectional.only(end: theme.spacing.s),
          child: Icon(icon, color: theme.color.serviceAcademic),
        ),
        endActions: [
          Icon(
            icon == YhIcons.open ? YhIcons.open : YhIcons.chevronRight,
            color: theme.color.muted,
            size: theme.spacing.m,
          ),
        ],
      ),
    );
  }
}
