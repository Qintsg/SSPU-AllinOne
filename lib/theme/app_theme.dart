/*
 * Material 3 应用主题 — 构建亮色与暗色 ThemeData
 * @Project : SSPU-AllinOne
 * @File : app_theme.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shapes.dart';

/// Material 3 应用主题工厂。
class AppTheme {
  AppTheme._();

  /// 全局字体族。
  static const String fontFamily = 'MiSans';

  /// 构建指定亮度的 Material 3 主题。
  static ThemeData build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 3,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      cardTheme: const CardThemeData(shape: AppShapes.cardShape),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: fontFamily),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontFamily: fontFamily,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontFamily: fontFamily,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}
