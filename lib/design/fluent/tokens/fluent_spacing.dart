/*
 * Fluent 2 间距令牌 — 4px 基准的 4x 比例阶梯
 * @Project : SSPU-AllinOne
 * @File : fluent_spacing.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.4。与主题无关，light/dark 共用一份常量。
 */

import 'package:flutter/material.dart';

/// Fluent 2 间距阶梯令牌。
@immutable
class FluentSpacing extends ThemeExtension<FluentSpacing> {
  const FluentSpacing();

  /// 0
  double get none => 0;

  /// 2 — 补偿图标内边距。
  double get xxs => 2;

  /// 4
  double get xs => 4;

  /// 6 — 对齐 4px 网格的微调。
  double get sNudge => 6;

  /// 8
  double get s => 8;

  /// 10 — 对齐 4px 网格的微调。
  double get mNudge => 10;

  /// 12
  double get m => 12;

  /// 16
  double get l => 16;

  /// 20
  double get xl => 20;

  /// 24
  double get xxl => 24;

  /// 32
  double get xxxl => 32;

  @override
  FluentSpacing copyWith() => const FluentSpacing();

  @override
  FluentSpacing lerp(ThemeExtension<FluentSpacing>? other, double t) => this;
}
