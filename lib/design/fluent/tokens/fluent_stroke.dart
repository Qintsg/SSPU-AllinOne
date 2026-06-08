/*
 * Fluent 2 描边宽度令牌 — Stroke Width
 * @Project : SSPU-AllinOne
 * @File : fluent_stroke.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.6。与主题无关，light/dark 共用一份常量。
 */

import 'package:flutter/material.dart';

/// Fluent 2 描边宽度令牌。
@immutable
class FluentStroke extends ThemeExtension<FluentStroke> {
  const FluentStroke();

  /// 1 — 默认边框、分割线。
  double get thin => 1;

  /// 2 — 焦点环、选中态。
  double get thick => 2;

  /// 3 — 强调态。
  double get thicker => 3;

  /// 4 — 特殊强调。
  double get thickest => 4;

  @override
  FluentStroke copyWith() => const FluentStroke();

  @override
  FluentStroke lerp(ThemeExtension<FluentStroke>? other, double t) => this;
}
