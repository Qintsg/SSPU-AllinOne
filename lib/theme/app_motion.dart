/*
 * Material 3 动效 Token — 统一反馈与页面过渡时长
 * @Project : SSPU-AllinOne
 * @File : app_motion.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/animation.dart';

/// Material 3 动效 Token。
class AppMotion {
  AppMotion._();

  /// 150ms — 小型状态变化。
  static const Duration short = Duration(milliseconds: 150);

  /// 300ms — 组件进入、退出、展开和折叠。
  static const Duration medium = Duration(milliseconds: 300);

  /// 500ms — 较大范围页面变化。
  static const Duration long = Duration(milliseconds: 500);

  /// Material 强调缓动。
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}
