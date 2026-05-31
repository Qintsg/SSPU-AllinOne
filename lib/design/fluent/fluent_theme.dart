/*
 * Fluent 2 主题构建 — Flutter ThemeData 底座叠加 Fluent 令牌扩展
 * @Project : SSPU-AllinOne
 * @File : fluent_theme.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * DESIGN.md §4.3：以 ThemeData 为底座，通过 ThemeExtension 叠加 Fluent 2 令牌。
 * ColorScheme 由 Fluent 令牌派生，使底层 Flutter 控件也呈现 Fluent 视觉。
 */

import 'package:flutter/material.dart';

import 'tokens/fluent_color_tokens.dart';
import 'tokens/fluent_elevation.dart';
import 'tokens/fluent_motion.dart';
import 'tokens/fluent_radii.dart';
import 'tokens/fluent_spacing.dart';
import 'tokens/fluent_stroke.dart';
import 'tokens/fluent_typography.dart';

/// 默认字体族。
///
/// DESIGN.md §1.2 建议桌面优先 Segoe UI；本项目面向中文用户并已内置覆盖
/// w300–w700 的 MiSans，Segoe UI 缺乏 CJK 字形必然回退，故以 MiSans 为主族
/// 并由系统字体兜底。此为对 §1.2 的合理本地化偏离。
const String kFluentFontFamily = 'MiSans';

/// 构建指定亮度的 Fluent 2 主题。
ThemeData buildFluentTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final FluentColors colors = isDark ? FluentColors.dark : FluentColors.light;
  final FluentElevation elevation =
      isDark ? FluentElevation.dark : FluentElevation.light;
  const FluentRadii radii = FluentRadii();
  const FluentSpacing spacing = FluentSpacing();
  const FluentStroke stroke = FluentStroke();
  const FluentMotion motion = FluentMotion();
  final FluentTypography typography =
      const FluentTypography(fontFamily: kFluentFontFamily);

  // ColorScheme 由 Fluent 别名令牌派生，承接未封装的 Flutter 底层控件。
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: colors.brandBackground,
    onPrimary: colors.neutralForegroundOnBrand,
    primaryContainer: colors.brandBackgroundSelected,
    onPrimaryContainer: colors.neutralForegroundOnBrand,
    secondary: colors.brandForeground1,
    onSecondary: colors.neutralForegroundOnBrand,
    secondaryContainer: colors.neutralBackground3,
    onSecondaryContainer: colors.neutralForeground1,
    tertiary: colors.statusWarningForeground,
    onTertiary: colors.neutralForegroundOnBrand,
    tertiaryContainer: colors.statusWarningBackground,
    onTertiaryContainer: colors.statusWarningForeground,
    error: colors.statusDangerForeground,
    onError: colors.neutralForegroundOnBrand,
    errorContainer: colors.statusDangerBackground,
    onErrorContainer: colors.statusDangerForeground,
    surface: colors.neutralBackground1,
    onSurface: colors.neutralForeground1,
    surfaceDim: colors.neutralBackgroundCanvas,
    surfaceBright: colors.neutralBackground1,
    surfaceContainerLowest: colors.neutralBackground1,
    surfaceContainerLow: colors.neutralBackground2,
    surfaceContainer: colors.neutralBackground2,
    surfaceContainerHigh: colors.neutralBackground3,
    surfaceContainerHighest: colors.neutralBackground3,
    onSurfaceVariant: colors.neutralForeground2,
    outline: colors.neutralStroke1,
    outlineVariant: colors.neutralStrokeDivider,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: colors.neutralForeground1,
    onInverseSurface: colors.neutralBackground1,
    inversePrimary: colors.brandForeground2,
    surfaceTint: colors.brandBackground,
  );

  final TextTheme textTheme = _buildTextTheme(typography, colors);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kFluentFontFamily,
    scaffoldBackgroundColor: colors.neutralBackground1,
    canvasColor: colors.neutralBackground1,
    dividerColor: colors.neutralStrokeDivider,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[
      colors,
      elevation,
      radii,
      spacing,
      stroke,
      motion,
      typography,
    ],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colors.neutralBackground1,
      foregroundColor: colors.neutralForeground1,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: typography.subtitle1.copyWith(
        color: colors.neutralForeground1,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.neutralStrokeDivider,
      thickness: stroke.thin,
      space: stroke.thin,
    ),
    cardTheme: CardThemeData(
      color: colors.neutralBackground1,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radii.largeBorder),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.neutralBackground2,
      indicatorColor: colors.brandBackgroundSelected,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final Color color = states.contains(WidgetState.selected)
            ? colors.brandForeground1
            : colors.neutralForeground2;
        return typography.caption1.copyWith(color: color);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final Color color = states.contains(WidgetState.selected)
            ? colors.neutralForegroundOnBrand
            : colors.neutralForeground2;
        return IconThemeData(color: color, size: 22);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.neutralBackground2,
      indicatorColor: colors.brandBackgroundSelected,
      selectedIconTheme: IconThemeData(color: colors.neutralForegroundOnBrand),
      unselectedIconTheme: IconThemeData(color: colors.neutralForeground2),
      selectedLabelTextStyle: typography.body1Strong.copyWith(
        color: colors.neutralForeground1,
      ),
      unselectedLabelTextStyle: typography.body1.copyWith(
        color: colors.neutralForeground2,
      ),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colors.neutralBackground2,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.brandBackgroundSelected,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.neutralBackground1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radii.xLargeBorder),
      titleTextStyle: typography.subtitle1.copyWith(
        color: colors.neutralForeground1,
      ),
      contentTextStyle: typography.body1.copyWith(
        color: colors.neutralForeground2,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.neutralForeground1,
      contentTextStyle: typography.body1.copyWith(
        color: colors.neutralBackground1,
      ),
      shape: RoundedRectangleBorder(borderRadius: radii.mediumBorder),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.neutralBackground3,
        borderRadius: radii.mediumBorder,
        border: Border.all(color: colors.neutralStroke2, width: stroke.thin),
      ),
      textStyle: typography.caption1.copyWith(
        color: colors.neutralForeground1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.neutralBackground1,
      hintStyle: typography.body1.copyWith(color: colors.neutralForeground3),
      labelStyle: typography.body1.copyWith(color: colors.neutralForeground2),
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing.m,
        vertical: spacing.s,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radii.mediumBorder,
        borderSide: BorderSide(
          color: colors.neutralStroke1,
          width: stroke.thin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radii.mediumBorder,
        borderSide: BorderSide(
          color: colors.brandStroke1,
          width: stroke.thick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radii.mediumBorder,
        borderSide: BorderSide(
          color: colors.statusDangerForeground,
          width: stroke.thin,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radii.mediumBorder,
        borderSide: BorderSide(
          color: colors.statusDangerForeground,
          width: stroke.thick,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.neutralForegroundOnBrand;
        }
        return colors.neutralForeground3;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.brandBackground;
        }
        return colors.neutralBackground3;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.brandBackground;
        }
        return colors.neutralStroke1;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: radii.smallBorder),
      side: BorderSide(color: colors.neutralStroke1, width: stroke.thin),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.brandBackground;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(colors.neutralForegroundOnBrand),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.brandBackground;
        }
        return colors.neutralStroke1;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.brandBackground,
      linearTrackColor: colors.neutralBackground3,
      circularTrackColor: colors.neutralBackground3,
    ),
    iconTheme: IconThemeData(color: colors.neutralForeground1, size: 20),
    listTileTheme: ListTileThemeData(
      iconColor: colors.neutralForeground2,
      textColor: colors.neutralForeground1,
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radii.mediumBorder),
    ),
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}

/// 由 Fluent 字阶派生 Material [TextTheme]，承接未封装控件的文本样式。
TextTheme _buildTextTheme(FluentTypography t, FluentColors c) {
  final Color fg = c.neutralForeground1;
  final Color fg2 = c.neutralForeground2;
  return TextTheme(
    displayLarge: t.display.copyWith(color: fg),
    displayMedium: t.largeTitle.copyWith(color: fg),
    displaySmall: t.title1.copyWith(color: fg),
    headlineLarge: t.title1.copyWith(color: fg),
    headlineMedium: t.title2.copyWith(color: fg),
    headlineSmall: t.title3.copyWith(color: fg),
    titleLarge: t.subtitle1.copyWith(color: fg),
    titleMedium: t.subtitle2.copyWith(color: fg),
    titleSmall: t.body1Strong.copyWith(color: fg),
    bodyLarge: t.body1.copyWith(color: fg),
    bodyMedium: t.body1.copyWith(color: fg2),
    bodySmall: t.caption1.copyWith(color: fg2),
    labelLarge: t.body1Strong.copyWith(color: fg),
    labelMedium: t.caption1Strong.copyWith(color: fg2),
    labelSmall: t.caption2.copyWith(color: fg2),
  );
}
