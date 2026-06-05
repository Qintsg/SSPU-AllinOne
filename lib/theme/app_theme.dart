/*
 * 应用主题 — 委托至外部 fluent_ui 主题
 * @Project : SSPU-AllinOne
 * @File : app_theme.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 历史 AppTheme 入口保留，内部统一委托给 design/fluent 的 buildFluentTheme。
 */

import 'package:fluent_ui/fluent_ui.dart';

import '../design/fluent/fluent_theme.dart';

/// 应用主题工厂，内部走 Fluent 2 令牌。
class AppTheme {
  AppTheme._();

  /// 全局字体族。
  static const String fontFamily = kFluentFontFamily;

  /// 构建指定亮度的外部 Fluent 主题。
  static FluentThemeData build(Brightness brightness) =>
      buildFluentTheme(brightness);
}
