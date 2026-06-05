/*
 * Fluent 主题构建 — 外部 fluent_ui 主题叠加历史兼容令牌扩展
 * @Project : SSPU-AllinOne
 * @File : fluent_theme.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 应用主题底座已迁移为外部 fluent_ui 的 FluentThemeData。
 * 历史 ThemeExtension 仅用于未完成迁移的业务组合件兼容访问。
 */

import 'package:fluent_ui/fluent_ui.dart';

import 'tokens/fluent_color_tokens.dart';
import 'tokens/fluent_elevation.dart';
import 'tokens/fluent_motion.dart';
import 'tokens/fluent_radii.dart';
import 'tokens/fluent_spacing.dart';
import 'tokens/fluent_stroke.dart';
import 'tokens/fluent_typography.dart';

/// 默认字体族。
const String kFluentFontFamily = 'MiSans';

/// 构建指定亮度的外部 Fluent 主题。
FluentThemeData buildFluentTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final FluentColors colors = isDark ? FluentColors.dark : FluentColors.light;
  final FluentElevation elevation = isDark
      ? FluentElevation.dark
      : FluentElevation.light;
  const FluentRadii radii = FluentRadii();
  const FluentSpacing spacing = FluentSpacing();
  const FluentStroke stroke = FluentStroke();
  const FluentMotion motion = FluentMotion();
  final FluentTypography typography = const FluentTypography(
    fontFamily: kFluentFontFamily,
  );

  return FluentThemeData(
    brightness: brightness,
    fontFamily: kFluentFontFamily,
    accentColor: Colors.blue,
    scaffoldBackgroundColor: colors.neutralBackground1,
    cardColor: colors.neutralBackground1,
    inactiveColor: colors.neutralForeground1,
    inactiveBackgroundColor: colors.neutralBackground3,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    extensions: <ThemeExtension<dynamic>>[
      colors,
      elevation,
      radii,
      spacing,
      stroke,
      motion,
      typography,
    ],
  );
}
