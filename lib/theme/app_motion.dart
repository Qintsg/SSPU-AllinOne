/*
 * Fluent 2 动效 Token — 统一反馈与页面过渡时长
 * @Project : SSPU-AllinOne
 * @File : app_motion.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/animation.dart';

/// Fluent 2 动效 Token。
class AppMotion {
  AppMotion._();

  /// durationFaster 100ms — 悬停、按下等小型状态变化。
  static const Duration short = Duration(milliseconds: 100);

  /// durationNormal 200ms — 默认转场。
  static const Duration medium = Duration(milliseconds: 200);

  /// durationSlow 300ms — 面板、抽屉等较大范围变化。
  static const Duration long = Duration(milliseconds: 300);

  /// Fluent 2 curveEasyEase — 进出对称的默认缓动。
  static const Curve emphasized = Cubic(0.33, 0, 0.67, 1);
}
