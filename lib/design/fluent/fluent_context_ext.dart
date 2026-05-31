/*
 * Fluent 2 令牌访问扩展 — 让组件以强类型简洁引用令牌
 * @Project : SSPU-AllinOne
 * @File : fluent_context_ext.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * UI 层唯一令牌入口：context.fluentColors / fluentType / fluentSpacing / ...
 * tokens/ 目录之外不得出现 Global 令牌。
 */

import 'package:flutter/material.dart';

import 'tokens/fluent_color_tokens.dart';
import 'tokens/fluent_elevation.dart';
import 'tokens/fluent_motion.dart';
import 'tokens/fluent_radii.dart';
import 'tokens/fluent_spacing.dart';
import 'tokens/fluent_stroke.dart';
import 'tokens/fluent_typography.dart';

/// Fluent 2 令牌的 [BuildContext] 便捷访问扩展。
extension FluentThemeX on BuildContext {
  /// 颜色令牌（随明暗主题切换）。
  FluentColors get fluentColors =>
      Theme.of(this).extension<FluentColors>() ?? FluentColors.light;

  /// 字阶令牌。
  FluentTypography get fluentType =>
      Theme.of(this).extension<FluentTypography>() ??
      const FluentTypography();

  /// 间距令牌。
  FluentSpacing get fluentSpacing =>
      Theme.of(this).extension<FluentSpacing>() ?? const FluentSpacing();

  /// 圆角令牌。
  FluentRadii get fluentRadii =>
      Theme.of(this).extension<FluentRadii>() ?? const FluentRadii();

  /// 描边宽度令牌。
  FluentStroke get fluentStroke =>
      Theme.of(this).extension<FluentStroke>() ?? const FluentStroke();

  /// 阴影令牌（随明暗主题切换）。
  FluentElevation get fluentElevation =>
      Theme.of(this).extension<FluentElevation>() ?? FluentElevation.light;

  /// 动效令牌。
  FluentMotion get fluentMotion =>
      Theme.of(this).extension<FluentMotion>() ?? const FluentMotion();
}
