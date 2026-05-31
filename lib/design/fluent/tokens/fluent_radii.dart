/*
 * Fluent 2 圆角令牌 — Corner Radius
 * @Project : SSPU-AllinOne
 * @File : fluent_radii.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.5。与主题无关，light/dark 共用一份常量。
 */

import 'package:flutter/material.dart';

/// Fluent 2 圆角令牌。
@immutable
class FluentRadii extends ThemeExtension<FluentRadii> {
  const FluentRadii();

  /// 0 — 无圆角。
  double get none => 0;

  /// 2 — 小控件、标签。
  double get small => 2;

  /// 4 — 按钮、输入框默认。
  double get medium => 4;

  /// 6 — 卡片。
  double get large => 6;

  /// 8 — 弹层、对话框、面板。
  double get xLarge => 8;

  /// 9999 — 头像、胶囊、圆形按钮。
  double get circular => 9999;

  /// 小控件圆角的 [BorderRadius]。
  BorderRadius get smallBorder => BorderRadius.circular(small);

  /// 按钮 / 输入框默认 [BorderRadius]。
  BorderRadius get mediumBorder => BorderRadius.circular(medium);

  /// 卡片 [BorderRadius]。
  BorderRadius get largeBorder => BorderRadius.circular(large);

  /// 弹层 / 对话框 [BorderRadius]。
  BorderRadius get xLargeBorder => BorderRadius.circular(xLarge);

  @override
  FluentRadii copyWith() => const FluentRadii();

  @override
  FluentRadii lerp(ThemeExtension<FluentRadii>? other, double t) => this;
}
