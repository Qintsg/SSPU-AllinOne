/*
 * Material 3 响应式断点 — 根据窗口宽度选择布局结构
 * @Project : SSPU-AllinOne
 * @File : app_breakpoints.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/widgets.dart';

/// Material 3 窗口尺寸等级。
enum WindowSizeClass {
  /// Compact：0–599dp。
  compact,

  /// Medium：600–839dp。
  medium,

  /// Expanded：840–1199dp。
  expanded,

  /// Large：1200–1599dp。
  large,

  /// Extra-large：≥1600dp。
  extraLarge,
}

/// 响应式断点工具。
class AppBreakpoints {
  AppBreakpoints._();

  /// Compact 上限。
  static const double compactMax = 600;

  /// Medium 上限。
  static const double mediumMax = 840;

  /// Expanded 上限。
  static const double expandedMax = 1200;

  /// Large 上限。
  static const double largeMax = 1600;

  /// 根据上下文返回窗口尺寸等级。
  static WindowSizeClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// 根据窗口宽度返回尺寸等级。
  static WindowSizeClass fromWidth(double width) {
    if (width < compactMax) return WindowSizeClass.compact;
    if (width < mediumMax) return WindowSizeClass.medium;
    if (width < expandedMax) return WindowSizeClass.expanded;
    if (width < largeMax) return WindowSizeClass.large;
    return WindowSizeClass.extraLarge;
  }
}
