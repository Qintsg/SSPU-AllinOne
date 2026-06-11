/*
 * Fluent 2 动效令牌 — 时长与缓动曲线
 * @Project : SSPU-AllinOne
 * @File : fluent_motion.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.8。与主题无关，light/dark 共用一份常量。
 */

import 'package:flutter/material.dart';

/// Fluent 2 动效令牌（时长 + 曲线）。
@immutable
class FluentMotion extends ThemeExtension<FluentMotion> {
  const FluentMotion();

  // —— 时长 ——
  /// 50ms — 极小状态反馈。
  Duration get durationUltraFast => const Duration(milliseconds: 50);

  /// 100ms — 悬停、按下。
  Duration get durationFaster => const Duration(milliseconds: 100);

  /// 150ms — 小元素进出。
  Duration get durationFast => const Duration(milliseconds: 150);

  /// 200ms — 默认转场。
  Duration get durationNormal => const Duration(milliseconds: 200);

  /// 300ms — 面板、抽屉。
  Duration get durationSlow => const Duration(milliseconds: 300);

  /// 400ms — 大面积转场。
  Duration get durationSlower => const Duration(milliseconds: 400);

  /// 500ms — 全屏转场。
  Duration get durationUltraSlow => const Duration(milliseconds: 500);

  /// 1200ms — 骨架屏 shimmer 周期。
  Duration get durationSkeleton => const Duration(milliseconds: 1200);

  // —— 曲线 ——
  /// 默认，进出对称。
  Cubic get curveEasyEase => const Cubic(0.33, 0, 0.67, 1);

  /// 元素进入。
  Cubic get curveDecelerateMid => const Cubic(0.1, 0.9, 0.2, 1);

  /// 元素退出。
  Cubic get curveAccelerateMid => const Cubic(0.7, 0, 1, 0.5);

  /// 进度、加载。
  Cubic get curveLinear => const Cubic(0, 0, 1, 1);

  @override
  FluentMotion copyWith() => const FluentMotion();

  @override
  FluentMotion lerp(ThemeExtension<FluentMotion>? other, double t) => this;
}
