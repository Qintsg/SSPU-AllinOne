/*
 * Fluent 2 静态 Token — 静态命名映射至 design/fluent 精确令牌值
 * @Project : SSPU-AllinOne
 * @File : fluent_tokens.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 本文件为历史静态调用提供 Fluent 命名；数值与 design/fluent/tokens 一致，
 * 仅因 static const 上下文无法引用 ThemeExtension 而镜像固化。
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import 'app_motion.dart';
import 'app_shapes.dart';
import 'app_spacing.dart';
import 'app_theme.dart';

/// 亮色主题固定语义色。
class FluentLightColors {
  FluentLightColors._();

  static const Color brandPrimary = Color(0xFF0F6CBD);
  static const Color brandHover = Color(0xFF115EA3);
  static const Color brandPressed = Color(0xFF0F548C);
  static const Color backgroundDefault = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundSidebar = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF242424);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color borderSubtle = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEBEBEB);
  static const Color statusSuccess = Color(0xFF0E700E);
  static const Color statusWarning = Color(0xFFBC4B09);
  static const Color statusError = Color(0xFFB10E1C);
  static const Color statusInfo = Color(0xFF0F6CBD);
  static const Color hoverFill = Color(0x0A000000);
  static const Color activeFill = Color(0x06000000);
  static const Color unreadIndicator = Color(0xFF0F6CBD);
  static const Color accentAcademic = Color(0xFF0F6CBD);
  static const Color accentSchedule = Color(0xFF0078D4);
  static const Color accentInformation = Color(0xFF8764B8);
  static const Color accentMail = Color(0xFF0078A8);
  static const Color accentFinance = Color(0xFF107C10);
  static const Color accentSports = Color(0xFFC239B3);
  static const Color accentSecondClassroom = Color(0xFFCA5010);
  static const Color accentQuickLink = Color(0xFF038387);
}

/// 暗色主题固定语义色。
class FluentDarkColors {
  FluentDarkColors._();

  static const Color brandPrimary = Color(0xFF479EF5);
  static const Color brandHover = Color(0xFF62ABF5);
  static const Color brandPressed = Color(0xFF2886DE);
  static const Color backgroundDefault = Color(0xFF292929);
  static const Color backgroundCard = Color(0xFF292929);
  static const Color backgroundSidebar = Color(0xFF1F1F1F);
  static const Color backgroundSecondary = Color(0xFF141414);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD6D6D6);
  static const Color textDisabled = Color(0xFF5C5C5C);
  static const Color borderSubtle = Color(0xFF525252);
  static const Color divider = Color(0xFF3D3D3D);
  static const Color statusSuccess = Color(0xFF54B054);
  static const Color statusWarning = Color(0xFFFAA06B);
  static const Color statusError = Color(0xFFDC626D);
  static const Color statusInfo = Color(0xFF479EF5);
  static const Color hoverFill = Color(0x0AFFFFFF);
  static const Color activeFill = Color(0x06FFFFFF);
  static const Color unreadIndicator = Color(0xFF479EF5);
  static const Color accentAcademic = Color(0xFF62ABF5);
  static const Color accentSchedule = Color(0xFF60CDFF);
  static const Color accentInformation = Color(0xFFB4A0FF);
  static const Color accentMail = Color(0xFF6CCBFF);
  static const Color accentFinance = Color(0xFF6CCB5F);
  static const Color accentSports = Color(0xFFE8A3DE);
  static const Color accentSecondClassroom = Color(0xFFFFB386);
  static const Color accentQuickLink = Color(0xFF68D8D6);
}

/// UI Refresh 2026 应用级度量镜像。
class FluentAppMetrics {
  FluentAppMetrics._();

  static const double contentMaxWidth = 1280;
  static const double readableMaxWidth = 920;
  static const double dashboardTileMinHeight = 176;
  static const double dashboardCompactTileMinHeight = 132;
  static const double businessCardHeight = 224;
  static const double quickLinkTileWidth = 156;
  static const double schedulePeriodColumnWidth = 82;
  static const double scheduleCellMinHeight = 76;
}

/// Fluent 2 浮层阴影静态映射。
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

/// Fluent 2 间距静态映射。
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
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(
    horizontal: xxl,
  );
  static const EdgeInsets listItemVertical = EdgeInsets.symmetric(vertical: s);
}

/// Fluent 2 圆角静态映射。
class FluentRadius {
  FluentRadius._();

  static const double small = 2;
  static const double medium = 4;
  static const double large = 6;
  static const double xLarge = 8;
  static const double xxLarge = 8;
  static const double circular = 9999;
  static const BorderRadius card = AppShapes.lg;
  static const BorderRadius button = AppShapes.sm;
  static const BorderRadius tag = AppShapes.xs;
}

/// Fluent 2 排版尺寸静态映射。
class FluentTypographySize {
  FluentTypographySize._();

  static const double title = 20;
  static const double subtitle = 16;
  static const double bodyStrong = 14;
  static const double body = 14;
  static const double caption = 12;
  static const double overline = 10;
}

/// Fluent 2 动效时长静态映射。
class FluentDuration {
  FluentDuration._();

  static const Duration fast = AppMotion.short;
  static const Duration normal = AppMotion.medium;
  static const Duration slow = AppMotion.long;
  static const Duration stagger = Duration(milliseconds: 80);
}

/// Fluent 2 动效曲线静态映射。
class FluentEasing {
  FluentEasing._();

  static const Curve standard = AppMotion.emphasized;
  static const Curve decelerate = Cubic(0.1, 0.9, 0.2, 1);
  static const Curve accelerate = Cubic(0.7, 0, 1, 0.5);
}

/// 设备类型枚举。
enum DeviceType {
  /// 手机（Compact）。
  phone,

  /// 平板（Medium / Expanded）。
  tablet,

  /// 桌面（Large 及以上）。
  desktop,
}

/// 响应式布局断点。
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

/// Fluent 2 主题静态工厂。
class FluentTokenTheme {
  FluentTokenTheme._();

  static const String fontFamily = AppTheme.fontFamily;

  static FluentThemeData light() => AppTheme.build(Brightness.light);

  static FluentThemeData dark() => AppTheme.build(Brightness.dark);
}
