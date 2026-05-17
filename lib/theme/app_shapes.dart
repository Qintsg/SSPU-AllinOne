/*
 * Material 3 圆角 Token — 统一组件形状半径
 * @Project : SSPU-AllinOne
 * @File : app_shapes.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/material.dart';

/// Material 3 圆角 Token。
class AppShapes {
  AppShapes._();

  /// Extra small — 4dp。
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4));

  /// Small — 8dp。
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));

  /// Medium — 12dp。
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));

  /// Large — 16dp。
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));

  /// Extra large — 28dp。
  static const BorderRadius xl = BorderRadius.all(Radius.circular(28));

  /// 卡片默认形状。
  static const ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: lg,
  );
}
