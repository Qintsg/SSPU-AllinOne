/*
 * 应用主题 — 委托至 Fluent 2 令牌驱动主题
 * @Project : SSPU-AllinOne
 * @File : app_theme.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 历史 AppTheme 入口保留，内部统一委托给 design/fluent 的 buildFluentTheme，
 * 使全应用未封装的 Flutter 底层控件也呈现 Fluent 2 视觉。
 */

import 'package:flutter/material.dart';

import '../design/fluent/fluent_theme.dart';

/// 应用主题工厂，内部走 Fluent 2 令牌。
class AppTheme {
  AppTheme._();

  /// 全局字体族。
  static const String fontFamily = kFluentFontFamily;

  /// 构建指定亮度的 Fluent 2 主题。
  static ThemeData build(Brightness brightness) =>
      buildFluentTheme(brightness);
}
