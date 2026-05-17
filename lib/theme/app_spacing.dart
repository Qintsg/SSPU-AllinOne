/*
 * Material 3 间距 Token — 统一 4dp 基准网格
 * @Project : SSPU-AllinOne
 * @File : app_spacing.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/widgets.dart';

/// Material 3 间距 Token。
class AppSpacing {
  AppSpacing._();

  /// 4dp — 紧凑元素间距。
  static const double xs = 4;

  /// 8dp — 元素内部间距。
  static const double sm = 8;

  /// 16dp — 默认页面边距与卡片内边距。
  static const double md = 16;

  /// 24dp — 分区间距与中等以上页面边距。
  static const double lg = 24;

  /// 32dp — 大段落间距。
  static const double xl = 32;

  /// 48dp — 页面级分隔。
  static const double xxl = 48;

  /// 默认卡片内边距。
  static const EdgeInsetsDirectional cardPadding = EdgeInsetsDirectional.all(md);

  /// 紧凑窗口页面边距。
  static const EdgeInsetsDirectional compactPagePadding =
      EdgeInsetsDirectional.all(md);

  /// 中等及以上窗口页面边距。
  static const EdgeInsetsDirectional regularPagePadding =
      EdgeInsetsDirectional.all(lg);
}
