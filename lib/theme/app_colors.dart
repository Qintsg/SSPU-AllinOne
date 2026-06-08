/*
 * 品牌颜色 Token — 对齐 Fluent 2 通信蓝
 * @Project : SSPU-AllinOne
 * @File : app_colors.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:flutter/material.dart';

/// 品牌颜色 Token（对齐 Fluent 2 brand ramp）。
class AppColors {
  AppColors._();

  /// 主题种子色，对齐 Fluent 2 通信蓝 brand[80]。
  static const Color seed = Color(0xFF0F6CBD);

  /// SSPU-AllinOne 固定品牌蓝（Fluent 2 brand[80]），用于 logo 等不随主题变化的资源。
  static const Color brandBlue = Color(0xFF0F6CBD);
}
