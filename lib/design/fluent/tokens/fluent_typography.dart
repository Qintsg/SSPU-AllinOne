/*
 * Fluent 2 字阶令牌 — Type Ramp 映射为 TextStyle
 * @Project : SSPU-AllinOne
 * @File : fluent_typography.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.3。height = 行高 ÷ 字号；UI 层禁止直接写 fontSize。
 */

import 'package:flutter/material.dart';

/// Fluent 2 字阶令牌集合，产出带语义角色的 [TextStyle]。
@immutable
class FluentTypography extends ThemeExtension<FluentTypography> {
  const FluentTypography({this.fontFamily});

  /// 字体族；桌面优先 Segoe UI，缺失回退系统字体。
  final String? fontFamily;

  TextStyle _style(double size, double lineHeight, FontWeight weight) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// 极小辅助文字。
  TextStyle get caption2 => _style(10, 14, FontWeight.w400);

  /// 极小强调。
  TextStyle get caption2Strong => _style(10, 14, FontWeight.w600);

  /// 辅助说明、标签。
  TextStyle get caption1 => _style(12, 16, FontWeight.w400);

  /// 辅助强调。
  TextStyle get caption1Strong => _style(12, 16, FontWeight.w600);

  /// 辅助最强强调。
  TextStyle get caption1Stronger => _style(12, 16, FontWeight.w700);

  /// 正文默认。
  TextStyle get body1 => _style(14, 20, FontWeight.w400);

  /// 正文强调。
  TextStyle get body1Strong => _style(14, 20, FontWeight.w600);

  /// 正文最强强调。
  TextStyle get body1Stronger => _style(14, 20, FontWeight.w700);

  /// 卡片标题。
  TextStyle get subtitle2 => _style(16, 22, FontWeight.w600);

  /// 卡片标题强调。
  TextStyle get subtitle2Stronger => _style(16, 22, FontWeight.w700);

  /// 区块标题。
  TextStyle get subtitle1 => _style(20, 26, FontWeight.w600);

  /// 页面小标题。
  TextStyle get title3 => _style(24, 32, FontWeight.w600);

  /// 页面标题。
  TextStyle get title2 => _style(28, 36, FontWeight.w600);

  /// 大标题。
  TextStyle get title1 => _style(32, 40, FontWeight.w600);

  /// 着陆页标题。
  TextStyle get largeTitle => _style(40, 52, FontWeight.w600);

  /// 营销大字。
  TextStyle get display => _style(68, 92, FontWeight.w600);

  @override
  FluentTypography copyWith({String? fontFamily}) =>
      FluentTypography(fontFamily: fontFamily ?? this.fontFamily);

  @override
  FluentTypography lerp(ThemeExtension<FluentTypography>? other, double t) =>
      this;
}
