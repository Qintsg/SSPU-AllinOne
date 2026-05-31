/*
 * Fluent 2 颜色令牌 — 中性 / 品牌 / 状态色的 light & dark 别名令牌
 * @Project : SSPU-AllinOne
 * @File : fluent_color_tokens.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 取值真源：DESIGN.md §3.2 与 @fluentui/tokens。Global 令牌仅在本文件内固化，
 * UI 层只允许通过 context.fluentColors 引用别名令牌。
 */

import 'package:flutter/material.dart';

/// Fluent 2 颜色别名令牌集合。
///
/// 中性色与品牌色随明暗主题切换，提供 [light] / [dark] 两套预设；
/// 切换主题靠替换整个实例，[lerp] 保证过渡平滑。
@immutable
class FluentColors extends ThemeExtension<FluentColors> {
  const FluentColors({
    required this.neutralBackground1,
    required this.neutralBackground1Hover,
    required this.neutralBackground1Pressed,
    required this.neutralBackground2,
    required this.neutralBackground3,
    required this.neutralBackgroundCanvas,
    required this.neutralForeground1,
    required this.neutralForeground2,
    required this.neutralForeground3,
    required this.neutralForegroundDisabled,
    required this.neutralForegroundOnBrand,
    required this.neutralStroke1,
    required this.neutralStroke2,
    required this.neutralStrokeDivider,
    required this.subtleBackgroundHover,
    required this.subtleBackgroundPressed,
    required this.brandBackground,
    required this.brandBackgroundHover,
    required this.brandBackgroundPressed,
    required this.brandBackgroundSelected,
    required this.brandForeground1,
    required this.brandForeground2,
    required this.brandStroke1,
    required this.brandStroke2,
    required this.statusSuccessForeground,
    required this.statusSuccessBackground,
    required this.statusWarningForeground,
    required this.statusWarningBackground,
    required this.statusDangerForeground,
    required this.statusDangerBackground,
    required this.statusSevereForeground,
    required this.statusSevereBackground,
  });

  // —— 中性：表面 ——
  /// 主表面 / 页面底色。
  final Color neutralBackground1;

  /// 主表面悬停态。
  final Color neutralBackground1Hover;

  /// 主表面按下态。
  final Color neutralBackground1Pressed;

  /// 次级表面。
  final Color neutralBackground2;

  /// 卡片 / 分区底。
  final Color neutralBackground3;

  /// 应用画布背景。
  final Color neutralBackgroundCanvas;

  // —— 中性：文本 / 图标 ——
  /// 主文本 / 图标。
  final Color neutralForeground1;

  /// 次级文本。
  final Color neutralForeground2;

  /// 占位 / 弱文本。
  final Color neutralForeground3;

  /// 禁用文本。
  final Color neutralForegroundDisabled;

  /// 品牌填充上的前景（恒为高对比白）。
  final Color neutralForegroundOnBrand;

  // —— 中性：描边 ——
  /// 默认描边。
  final Color neutralStroke1;

  /// 弱描边。
  final Color neutralStroke2;

  /// 分割线。
  final Color neutralStrokeDivider;

  // —— 低强调交互填充 ——
  /// subtle / 工具栏元素悬停填充。
  final Color subtleBackgroundHover;

  /// subtle / 工具栏元素按下填充。
  final Color subtleBackgroundPressed;

  // —— 品牌 ——
  /// 主操作填充（Rest）。
  final Color brandBackground;

  /// 主操作悬停。
  final Color brandBackgroundHover;

  /// 主操作按下。
  final Color brandBackgroundPressed;

  /// 选中态。
  final Color brandBackgroundSelected;

  /// 品牌文本 / 图标。
  final Color brandForeground1;

  /// 品牌文本悬停。
  final Color brandForeground2;

  /// 品牌描边。
  final Color brandStroke1;

  /// 弱品牌描边。
  final Color brandStroke2;

  // —— 状态 ——
  /// 成功（绿）前景。
  final Color statusSuccessForeground;

  /// 成功（绿）背景。
  final Color statusSuccessBackground;

  /// 警示（黄）前景。
  final Color statusWarningForeground;

  /// 警示（黄）背景。
  final Color statusWarningBackground;

  /// 错误（红）前景。
  final Color statusDangerForeground;

  /// 错误（红）背景。
  final Color statusDangerBackground;

  /// 严重（深橙）前景。
  final Color statusSevereForeground;

  /// 严重（深橙）背景。
  final Color statusSevereBackground;

  @override
  FluentColors copyWith({
    Color? neutralBackground1,
    Color? neutralBackground1Hover,
    Color? neutralBackground1Pressed,
    Color? neutralBackground2,
    Color? neutralBackground3,
    Color? neutralBackgroundCanvas,
    Color? neutralForeground1,
    Color? neutralForeground2,
    Color? neutralForeground3,
    Color? neutralForegroundDisabled,
    Color? neutralForegroundOnBrand,
    Color? neutralStroke1,
    Color? neutralStroke2,
    Color? neutralStrokeDivider,
    Color? subtleBackgroundHover,
    Color? subtleBackgroundPressed,
    Color? brandBackground,
    Color? brandBackgroundHover,
    Color? brandBackgroundPressed,
    Color? brandBackgroundSelected,
    Color? brandForeground1,
    Color? brandForeground2,
    Color? brandStroke1,
    Color? brandStroke2,
    Color? statusSuccessForeground,
    Color? statusSuccessBackground,
    Color? statusWarningForeground,
    Color? statusWarningBackground,
    Color? statusDangerForeground,
    Color? statusDangerBackground,
    Color? statusSevereForeground,
    Color? statusSevereBackground,
  }) {
    return FluentColors(
      neutralBackground1: neutralBackground1 ?? this.neutralBackground1,
      neutralBackground1Hover:
          neutralBackground1Hover ?? this.neutralBackground1Hover,
      neutralBackground1Pressed:
          neutralBackground1Pressed ?? this.neutralBackground1Pressed,
      neutralBackground2: neutralBackground2 ?? this.neutralBackground2,
      neutralBackground3: neutralBackground3 ?? this.neutralBackground3,
      neutralBackgroundCanvas:
          neutralBackgroundCanvas ?? this.neutralBackgroundCanvas,
      neutralForeground1: neutralForeground1 ?? this.neutralForeground1,
      neutralForeground2: neutralForeground2 ?? this.neutralForeground2,
      neutralForeground3: neutralForeground3 ?? this.neutralForeground3,
      neutralForegroundDisabled:
          neutralForegroundDisabled ?? this.neutralForegroundDisabled,
      neutralForegroundOnBrand:
          neutralForegroundOnBrand ?? this.neutralForegroundOnBrand,
      neutralStroke1: neutralStroke1 ?? this.neutralStroke1,
      neutralStroke2: neutralStroke2 ?? this.neutralStroke2,
      neutralStrokeDivider: neutralStrokeDivider ?? this.neutralStrokeDivider,
      subtleBackgroundHover:
          subtleBackgroundHover ?? this.subtleBackgroundHover,
      subtleBackgroundPressed:
          subtleBackgroundPressed ?? this.subtleBackgroundPressed,
      brandBackground: brandBackground ?? this.brandBackground,
      brandBackgroundHover: brandBackgroundHover ?? this.brandBackgroundHover,
      brandBackgroundPressed:
          brandBackgroundPressed ?? this.brandBackgroundPressed,
      brandBackgroundSelected:
          brandBackgroundSelected ?? this.brandBackgroundSelected,
      brandForeground1: brandForeground1 ?? this.brandForeground1,
      brandForeground2: brandForeground2 ?? this.brandForeground2,
      brandStroke1: brandStroke1 ?? this.brandStroke1,
      brandStroke2: brandStroke2 ?? this.brandStroke2,
      statusSuccessForeground:
          statusSuccessForeground ?? this.statusSuccessForeground,
      statusSuccessBackground:
          statusSuccessBackground ?? this.statusSuccessBackground,
      statusWarningForeground:
          statusWarningForeground ?? this.statusWarningForeground,
      statusWarningBackground:
          statusWarningBackground ?? this.statusWarningBackground,
      statusDangerForeground:
          statusDangerForeground ?? this.statusDangerForeground,
      statusDangerBackground:
          statusDangerBackground ?? this.statusDangerBackground,
      statusSevereForeground:
          statusSevereForeground ?? this.statusSevereForeground,
      statusSevereBackground:
          statusSevereBackground ?? this.statusSevereBackground,
    );
  }

  @override
  FluentColors lerp(ThemeExtension<FluentColors>? other, double t) {
    if (other is! FluentColors) return this;
    return FluentColors(
      neutralBackground1:
          Color.lerp(neutralBackground1, other.neutralBackground1, t)!,
      neutralBackground1Hover: Color.lerp(
        neutralBackground1Hover,
        other.neutralBackground1Hover,
        t,
      )!,
      neutralBackground1Pressed: Color.lerp(
        neutralBackground1Pressed,
        other.neutralBackground1Pressed,
        t,
      )!,
      neutralBackground2:
          Color.lerp(neutralBackground2, other.neutralBackground2, t)!,
      neutralBackground3:
          Color.lerp(neutralBackground3, other.neutralBackground3, t)!,
      neutralBackgroundCanvas: Color.lerp(
        neutralBackgroundCanvas,
        other.neutralBackgroundCanvas,
        t,
      )!,
      neutralForeground1:
          Color.lerp(neutralForeground1, other.neutralForeground1, t)!,
      neutralForeground2:
          Color.lerp(neutralForeground2, other.neutralForeground2, t)!,
      neutralForeground3:
          Color.lerp(neutralForeground3, other.neutralForeground3, t)!,
      neutralForegroundDisabled: Color.lerp(
        neutralForegroundDisabled,
        other.neutralForegroundDisabled,
        t,
      )!,
      neutralForegroundOnBrand: Color.lerp(
        neutralForegroundOnBrand,
        other.neutralForegroundOnBrand,
        t,
      )!,
      neutralStroke1: Color.lerp(neutralStroke1, other.neutralStroke1, t)!,
      neutralStroke2: Color.lerp(neutralStroke2, other.neutralStroke2, t)!,
      neutralStrokeDivider: Color.lerp(
        neutralStrokeDivider,
        other.neutralStrokeDivider,
        t,
      )!,
      subtleBackgroundHover: Color.lerp(
        subtleBackgroundHover,
        other.subtleBackgroundHover,
        t,
      )!,
      subtleBackgroundPressed: Color.lerp(
        subtleBackgroundPressed,
        other.subtleBackgroundPressed,
        t,
      )!,
      brandBackground: Color.lerp(brandBackground, other.brandBackground, t)!,
      brandBackgroundHover: Color.lerp(
        brandBackgroundHover,
        other.brandBackgroundHover,
        t,
      )!,
      brandBackgroundPressed: Color.lerp(
        brandBackgroundPressed,
        other.brandBackgroundPressed,
        t,
      )!,
      brandBackgroundSelected: Color.lerp(
        brandBackgroundSelected,
        other.brandBackgroundSelected,
        t,
      )!,
      brandForeground1:
          Color.lerp(brandForeground1, other.brandForeground1, t)!,
      brandForeground2:
          Color.lerp(brandForeground2, other.brandForeground2, t)!,
      brandStroke1: Color.lerp(brandStroke1, other.brandStroke1, t)!,
      brandStroke2: Color.lerp(brandStroke2, other.brandStroke2, t)!,
      statusSuccessForeground: Color.lerp(
        statusSuccessForeground,
        other.statusSuccessForeground,
        t,
      )!,
      statusSuccessBackground: Color.lerp(
        statusSuccessBackground,
        other.statusSuccessBackground,
        t,
      )!,
      statusWarningForeground: Color.lerp(
        statusWarningForeground,
        other.statusWarningForeground,
        t,
      )!,
      statusWarningBackground: Color.lerp(
        statusWarningBackground,
        other.statusWarningBackground,
        t,
      )!,
      statusDangerForeground: Color.lerp(
        statusDangerForeground,
        other.statusDangerForeground,
        t,
      )!,
      statusDangerBackground: Color.lerp(
        statusDangerBackground,
        other.statusDangerBackground,
        t,
      )!,
      statusSevereForeground: Color.lerp(
        statusSevereForeground,
        other.statusSevereForeground,
        t,
      )!,
      statusSevereBackground: Color.lerp(
        statusSevereBackground,
        other.statusSevereBackground,
        t,
      )!,
    );
  }

  // —— 主题预设：数值固化在此，UI 层不可见 Global Token ——

  /// 亮色预设（DESIGN.md §3.2 Light 列）。
  static const FluentColors light = FluentColors(
    neutralBackground1: Color(0xFFFFFFFF),
    neutralBackground1Hover: Color(0xFFF5F5F5),
    neutralBackground1Pressed: Color(0xFFE0E0E0),
    neutralBackground2: Color(0xFFFAFAFA),
    neutralBackground3: Color(0xFFF5F5F5),
    neutralBackgroundCanvas: Color(0xFFF0F0F0),
    neutralForeground1: Color(0xFF242424),
    neutralForeground2: Color(0xFF424242),
    neutralForeground3: Color(0xFF616161),
    neutralForegroundDisabled: Color(0xFFBDBDBD),
    neutralForegroundOnBrand: Color(0xFFFFFFFF),
    neutralStroke1: Color(0xFFD1D1D1),
    neutralStroke2: Color(0xFFE0E0E0),
    neutralStrokeDivider: Color(0xFFEBEBEB),
    subtleBackgroundHover: Color(0xFFF5F5F5),
    subtleBackgroundPressed: Color(0xFFE0E0E0),
    brandBackground: Color(0xFF0F6CBD),
    brandBackgroundHover: Color(0xFF115EA3),
    brandBackgroundPressed: Color(0xFF0F548C),
    brandBackgroundSelected: Color(0xFF0F548C),
    brandForeground1: Color(0xFF0F6CBD),
    brandForeground2: Color(0xFF115EA3),
    brandStroke1: Color(0xFF0F6CBD),
    brandStroke2: Color(0xFFB4D6FA),
    statusSuccessForeground: Color(0xFF0E700E),
    statusSuccessBackground: Color(0xFFF1FAF1),
    statusWarningForeground: Color(0xFFBC4B09),
    statusWarningBackground: Color(0xFFFFF9F5),
    statusDangerForeground: Color(0xFFB10E1C),
    statusDangerBackground: Color(0xFFFDF3F4),
    statusSevereForeground: Color(0xFFDA3B01),
    statusSevereBackground: Color(0xFFFDF6F3),
  );

  /// 暗色预设（DESIGN.md §3.2 Dark 列；品牌别名整体上移约一阶）。
  static const FluentColors dark = FluentColors(
    neutralBackground1: Color(0xFF292929),
    neutralBackground1Hover: Color(0xFF3D3D3D),
    neutralBackground1Pressed: Color(0xFF1F1F1F),
    neutralBackground2: Color(0xFF1F1F1F),
    neutralBackground3: Color(0xFF141414),
    neutralBackgroundCanvas: Color(0xFF0A0A0A),
    neutralForeground1: Color(0xFFFFFFFF),
    neutralForeground2: Color(0xFFD6D6D6),
    neutralForeground3: Color(0xFFADADAD),
    neutralForegroundDisabled: Color(0xFF5C5C5C),
    neutralForegroundOnBrand: Color(0xFFFFFFFF),
    neutralStroke1: Color(0xFF666666),
    neutralStroke2: Color(0xFF525252),
    neutralStrokeDivider: Color(0xFF3D3D3D),
    subtleBackgroundHover: Color(0xFF3D3D3D),
    subtleBackgroundPressed: Color(0xFF525252),
    brandBackground: Color(0xFF115EA3),
    brandBackgroundHover: Color(0xFF0F6CBD),
    brandBackgroundPressed: Color(0xFF2886DE),
    brandBackgroundSelected: Color(0xFF2886DE),
    brandForeground1: Color(0xFF479EF5),
    brandForeground2: Color(0xFF62ABF5),
    brandStroke1: Color(0xFF479EF5),
    brandStroke2: Color(0xFF0F6CBD),
    statusSuccessForeground: Color(0xFF54B054),
    statusSuccessBackground: Color(0xFF052505),
    statusWarningForeground: Color(0xFFFAA06B),
    statusWarningBackground: Color(0xFF2B1709),
    statusDangerForeground: Color(0xFFDC626D),
    statusDangerBackground: Color(0xFF3B1A1C),
    statusSevereForeground: Color(0xFFFF7A45),
    statusSevereBackground: Color(0xFF3B1A0A),
  );
}
