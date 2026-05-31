/*
 * Fluent 2 主题视图 — 基于 ThemeExtension 暴露语义化访问器
 * @Project : SSPU-AllinOne
 * @File : fluent_theme_view.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:flutter/material.dart';

import 'fluent_context_ext.dart';
import 'tokens/fluent_color_tokens.dart';
import 'tokens/fluent_typography.dart';

/// Fluent 2 主题访问入口。
class FluentTheme {
  FluentTheme._();

  /// 返回当前上下文的 Fluent 2 主题视图。
  static FluentThemeData of(BuildContext context) {
    return FluentThemeData(
      brightness: Theme.of(context).brightness,
      colors: context.fluentColors,
      typography: context.fluentType,
    );
  }
}

/// Fluent 2 主题视图。
class FluentThemeData {
  const FluentThemeData({
    required this.brightness,
    required FluentColors colors,
    required FluentTypography typography,
  }) : _colors = colors,
       _typography = typography;

  final FluentColors _colors;
  final FluentTypography _typography;

  /// 当前亮度。
  final Brightness brightness;

  /// 品牌强调色。
  Color get accentColor => _colors.brandBackground;

  /// 次级前景色。
  Color get inactiveColor => _colors.neutralForeground2;

  /// Fluent 2 字阶视图。
  FluentTypographyView get typography => FluentTypographyView(_typography);

  /// Fluent 2 资源色视图。
  FluentResourceColors get resources => FluentResourceColors(_colors);
}

/// Fluent 2 常用字阶访问器。
class FluentTypographyView {
  const FluentTypographyView(this._type);

  final FluentTypography _type;

  TextStyle? get title => _type.title3;
  TextStyle? get display => _type.display;
  TextStyle? get subtitle => _type.subtitle1;
  TextStyle? get bodyLarge => _type.body1;
  TextStyle? get body => _type.body1;
  TextStyle? get bodyStrong => _type.body1Strong;
  TextStyle? get caption => _type.caption1;
}

/// Fluent 2 常用资源色访问器。
class FluentResourceColors {
  const FluentResourceColors(this._colors);

  final FluentColors _colors;

  Color get textFillColorSecondary => _colors.neutralForeground2;
  Color get textFillColorDisabled => _colors.neutralForegroundDisabled;
  Color get controlAltFillColorSecondary => _colors.neutralBackground3;
  Color get controlFillColorDisabled => _colors.neutralBackground3;
  Color get systemFillColorSuccessBackground => _colors.statusSuccessBackground;
  Color get systemFillColorSuccess => _colors.statusSuccessForeground;
  Color get systemFillColorNeutralBackground => _colors.neutralBackground2;
  Color get controlStrokeColorDefault => _colors.neutralStroke1;
  Color get subtleFillColorSecondary => _colors.subtleBackgroundHover;
  Color get systemFillColorCaution => _colors.statusWarningForeground;
  Color get systemFillColorSolidNeutral => _colors.neutralForeground2;
  Color get systemFillColorCritical => _colors.statusDangerForeground;
}
