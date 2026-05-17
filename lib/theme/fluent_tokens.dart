/*
 * Material 3 兼容 Token — 为历史调用提供过渡期命名
 * @Project : SSPU-AllinOne
 * @File : fluent_tokens.dart
 * @Author : Qintsg
 * @Date : 2026-04-19
 */

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_shapes.dart';
import 'app_spacing.dart';
import 'app_theme.dart';

/// 亮色主题固定语义色兼容层。
class FluentLightColors {
  FluentLightColors._();

  static const Color brandPrimary = AppColors.brandBlue;
  static const Color brandHover = Color(0xFF106EBE);
  static const Color brandPressed = Color(0xFF005A9E);
  static const Color backgroundDefault = Color(0xFFFDFBFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundSidebar = Color(0xFFF4F3F8);
  static const Color backgroundSecondary = Color(0xFFE8E7EF);
  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF5F5E66);
  static const Color textDisabled = Color(0xFF8C8A93);
  static const Color borderSubtle = Color(0xFFE1E2EA);
  static const Color divider = Color(0xFFE1E2EA);
  static const Color statusSuccess = Color(0xFF2E7D32);
  static const Color statusWarning = Color(0xFFB26A00);
  static const Color statusError = Color(0xFFBA1A1A);
  static const Color statusInfo = AppColors.brandBlue;
  static const Color hoverFill = Color(0x0A000000);
  static const Color activeFill = Color(0x06000000);
  static const Color unreadIndicator = AppColors.brandBlue;
}

/// 暗色主题固定语义色兼容层。
class FluentDarkColors {
  FluentDarkColors._();

  static const Color brandPrimary = Color(0xFFAEC6FF);
  static const Color brandHover = Color(0xFFC8D7FF);
  static const Color brandPressed = Color(0xFF7FA7E8);
  static const Color backgroundDefault = Color(0xFF111318);
  static const Color backgroundCard = Color(0xFF1A1C22);
  static const Color backgroundSidebar = Color(0xFF181A20);
  static const Color backgroundSecondary = Color(0xFF24262D);
  static const Color textPrimary = Color(0xFFE4E2E9);
  static const Color textSecondary = Color(0xFFC8C6D0);
  static const Color textDisabled = Color(0xFF777680);
  static const Color borderSubtle = Color(0xFF444750);
  static const Color divider = Color(0xFF444750);
  static const Color statusSuccess = Color(0xFFA5D6A7);
  static const Color statusWarning = Color(0xFFFFD180);
  static const Color statusError = Color(0xFFFFB4AB);
  static const Color statusInfo = Color(0xFFAEC6FF);
  static const Color hoverFill = Color(0x0AFFFFFF);
  static const Color activeFill = Color(0x06FFFFFF);
  static const Color unreadIndicator = Color(0xFFAEC6FF);
}

/// Material 3 浮层阴影兼容层。
class FluentElevation {
  FluentElevation._();

  static const List<BoxShadow> cardRest = [];
  static const List<BoxShadow> cardHover = [];
  static const List<BoxShadow> cardPressed = [];
  static const List<BoxShadow> dialog = [];
  static const List<BoxShadow> cardRestDark = [];
  static const List<BoxShadow> cardHoverDark = [];
  static const List<BoxShadow> cardPressedDark = [];
}

/// Material 3 间距兼容层。
class FluentSpacing {
  FluentSpacing._();

  static const double xxs = 2;
  static const double xs = AppSpacing.xs;
  static const double s = AppSpacing.sm;
  static const double m = 12;
  static const double l = AppSpacing.md;
  static const double xl = 20;
  static const double xxl = AppSpacing.lg;
  static const double xxxl = AppSpacing.xl;
  static const EdgeInsets cardPadding = EdgeInsets.all(xl);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: xxl);
  static const EdgeInsets listItemVertical = EdgeInsets.symmetric(vertical: s);
}

/// Material 3 圆角兼容层。
class FluentRadius {
  FluentRadius._();

  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double xLarge = 16;
  static const double xxLarge = 28;
  static const double circular = 9999;
  static const BorderRadius card = AppShapes.lg;
  static const BorderRadius button = AppShapes.sm;
  static const BorderRadius tag = AppShapes.sm;
}

/// Material 3 排版尺寸兼容层。
class FluentTypographySize {
  FluentTypographySize._();

  static const double title = 22;
  static const double subtitle = 16;
  static const double bodyStrong = 14;
  static const double body = 14;
  static const double caption = 12;
  static const double overline = 11;
}

/// Material 3 动效时长兼容层。
class FluentDuration {
  FluentDuration._();

  static const Duration fast = AppMotion.short;
  static const Duration normal = AppMotion.medium;
  static const Duration slow = AppMotion.medium;
  static const Duration stagger = Duration(milliseconds: 80);
}

/// Material 3 动效曲线兼容层。
class FluentEasing {
  FluentEasing._();

  static const Curve standard = AppMotion.emphasized;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
}

/// 设备类型枚举兼容层。
enum DeviceType {
  /// 手机（Compact）。
  phone,

  /// 平板（Medium / Expanded）。
  tablet,

  /// 桌面（Large 及以上）。
  desktop,
}

/// 响应式布局断点兼容层。
class FluentBreakpoints {
  FluentBreakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  static DeviceType fromWidth(double width) {
    if (width < compact) return DeviceType.phone;
    if (width < expanded) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

/// Material 3 主题兼容工厂。
class FluentTokenTheme {
  FluentTokenTheme._();

  static const String fontFamily = AppTheme.fontFamily;

  static ThemeData light() => AppTheme.build(Brightness.light);

  static ThemeData dark() => AppTheme.build(Brightness.dark);
}
