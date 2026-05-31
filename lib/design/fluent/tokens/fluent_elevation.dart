/*
 * Fluent 2 高度与阴影令牌 — Elevation Ramp
 * @Project : SSPU-AllinOne
 * @File : fluent_elevation.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.7 与 @fluentui/tokens。每个阴影由环境光层 + 方向光层
 * 叠加；暗色主题加深不透明度。UI 层禁止手写 BoxShadow，只允许引用本令牌。
 */

import 'package:flutter/material.dart';

/// Fluent 2 阴影令牌集合，提供 light / dark 两套预设。
@immutable
class FluentElevation extends ThemeExtension<FluentElevation> {
  const FluentElevation({
    required this.shadow2,
    required this.shadow4,
    required this.shadow8,
    required this.shadow16,
    required this.shadow28,
    required this.shadow64,
  });

  /// 轻浮起（悬停态卡片）。
  final List<BoxShadow> shadow2;

  /// 卡片默认。
  final List<BoxShadow> shadow4;

  /// 下拉、菜单。
  final List<BoxShadow> shadow8;

  /// 弹出层、Flyout。
  final List<BoxShadow> shadow16;

  /// 对话框。
  final List<BoxShadow> shadow28;

  /// 全屏覆盖层。
  final List<BoxShadow> shadow64;

  static List<BoxShadow> _pair(
    double ambientBlur,
    double ambientAlpha,
    double keyOffsetY,
    double keyBlur,
    double keyAlpha,
  ) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, ambientAlpha),
        blurRadius: ambientBlur,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, keyAlpha),
        offset: Offset(0, keyOffsetY),
        blurRadius: keyBlur,
      ),
    ];
  }

  /// 亮色阴影预设。
  static final FluentElevation light = FluentElevation(
    shadow2: _pair(2, 0.12, 1, 2, 0.14),
    shadow4: _pair(2, 0.12, 2, 4, 0.14),
    shadow8: _pair(2, 0.12, 4, 8, 0.14),
    shadow16: _pair(8, 0.12, 8, 16, 0.14),
    shadow28: _pair(8, 0.20, 14, 28, 0.24),
    shadow64: _pair(8, 0.20, 32, 64, 0.24),
  );

  /// 暗色阴影预设（不透明度加深约 1.7x）。
  static final FluentElevation dark = FluentElevation(
    shadow2: _pair(2, 0.24, 1, 2, 0.28),
    shadow4: _pair(2, 0.24, 2, 4, 0.28),
    shadow8: _pair(2, 0.24, 4, 8, 0.28),
    shadow16: _pair(8, 0.24, 8, 16, 0.28),
    shadow28: _pair(8, 0.40, 14, 28, 0.48),
    shadow64: _pair(8, 0.40, 32, 64, 0.48),
  );

  @override
  FluentElevation copyWith({
    List<BoxShadow>? shadow2,
    List<BoxShadow>? shadow4,
    List<BoxShadow>? shadow8,
    List<BoxShadow>? shadow16,
    List<BoxShadow>? shadow28,
    List<BoxShadow>? shadow64,
  }) {
    return FluentElevation(
      shadow2: shadow2 ?? this.shadow2,
      shadow4: shadow4 ?? this.shadow4,
      shadow8: shadow8 ?? this.shadow8,
      shadow16: shadow16 ?? this.shadow16,
      shadow28: shadow28 ?? this.shadow28,
      shadow64: shadow64 ?? this.shadow64,
    );
  }

  @override
  FluentElevation lerp(ThemeExtension<FluentElevation>? other, double t) {
    if (other is! FluentElevation) return this;
    return t < 0.5 ? this : other;
  }
}
