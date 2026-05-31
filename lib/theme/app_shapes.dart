/*
 * Fluent 2 圆角 Token — 统一组件形状半径
 * @Project : SSPU-AllinOne
 * @File : app_shapes.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/material.dart';

/// Fluent 2 圆角 Token。
class AppShapes {
  AppShapes._();

  /// radiusSmall — 2dp（小控件、标签）。
  static const BorderRadius xs = BorderRadius.all(Radius.circular(2));

  /// radiusMedium — 4dp（按钮、输入框默认）。
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));

  /// radiusLarge — 6dp（卡片）。
  static const BorderRadius md = BorderRadius.all(Radius.circular(6));

  /// radiusLarge — 6dp（卡片）。
  static const BorderRadius lg = BorderRadius.all(Radius.circular(6));

  /// radiusXLarge — 8dp（弹层、对话框、面板）。
  static const BorderRadius xl = BorderRadius.all(Radius.circular(8));

  /// 卡片默认形状。
  static const ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: lg,
  );
}
