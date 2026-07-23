/*
 * 清源主题 — 由设计 token 映射的语义主题扩展
 * @Project : SSPU-AllinOne
 * @File : yh_theme.dart
 * @Author : Qintsg
 * @Date : 2026-07-18
 */

import 'package:flutter/animation.dart' show Cubic, Curve;
import 'package:flutter/painting.dart'
    show BoxShadow, Color, FontWeight, Offset, TextStyle;
import 'package:flutter/widgets.dart'
    show
        Brightness,
        BuildContext,
        InheritedTheme,
        MediaQuery,
        Widget,
        immutable;

@immutable
class YhColorTokens {
  const YhColorTokens({
    required this.background,
    required this.surface,
    required this.sunken,
    required this.foreground,
    required this.muted,
    required this.border,
    required this.brand,
    required this.brandStrong,
    required this.brandTint,
    required this.brandInk,
    required this.onBrand,
    required this.structural,
    required this.onStructural,
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.danger,
    required this.dangerTint,
    required this.serviceAcademic,
    required this.serviceSchedule,
    required this.serviceNews,
    required this.serviceMail,
    required this.serviceFinance,
    required this.serviceSports,
    required this.serviceSecondClass,
    required this.serviceQuickLink,
    required this.scrim,
  });

  static const light = YhColorTokens(
    background: Color(0xFFF7F6F5),
    surface: Color(0xFFFFFFFF),
    sunken: Color(0xFFFAFAFA),
    foreground: Color(0xFF1C1B1A),
    muted: Color(0xFF6B6964),
    border: Color(0xFFD1CEC9),
    brand: Color(0xFF6FA3A4),
    brandStrong: Color(0xFF478384),
    brandTint: Color(0xFFE9F0F0),
    brandInk: Color(0xFF356263),
    onBrand: Color(0xFFFFFFFF),
    structural: Color(0xFF14304D),
    onStructural: Color(0xFFFFFFFF),
    success: Color(0xFF1F8F57),
    successTint: Color(0xFFE7F4EC),
    warning: Color(0xFFB26A12),
    warningTint: Color(0xFFFBF1E0),
    danger: Color(0xFFC23B33),
    dangerTint: Color(0xFFFBECEA),
    serviceAcademic: Color(0xFF3D7EA6),
    serviceSchedule: Color(0xFF6B5B95),
    serviceNews: Color(0xFFC97D4A),
    serviceMail: Color(0xFF5C8C6E),
    serviceFinance: Color(0xFFB85C6A),
    serviceSports: Color(0xFF8A6B3D),
    serviceSecondClass: Color(0xFF6A8C5C),
    serviceQuickLink: Color(0xFF7A7A8C),
    scrim: Color(0x73000000),
  );

  static const dark = YhColorTokens(
    background: Color(0xFF14171A),
    surface: Color(0xFF1E2226),
    sunken: Color(0xFF181B1E),
    foreground: Color(0xFFE8E6E3),
    muted: Color(0xFF9A9893),
    border: Color(0xFF353A3F),
    brand: Color(0xFF7FB0B1),
    brandStrong: Color(0xFF5C9A9B),
    brandTint: Color(0xFF1E3233),
    brandInk: Color(0xFFA8CFCF),
    onBrand: Color(0xFF0A0D12),
    structural: Color(0xFF2A4A6E),
    onStructural: Color(0xFFFFFFFF),
    success: Color(0xFF28C26B),
    successTint: Color(0xFF14241B),
    warning: Color(0xFFD89134),
    warningTint: Color(0xFF2A2113),
    danger: Color(0xFFE5564B),
    dangerTint: Color(0xFF2C1715),
    serviceAcademic: Color(0xFF5599C2),
    serviceSchedule: Color(0xFF9486C0),
    serviceNews: Color(0xFFE0995F),
    serviceMail: Color(0xFF7DB091),
    serviceFinance: Color(0xFFD67D8A),
    serviceSports: Color(0xFFB08E5C),
    serviceSecondClass: Color(0xFF8DAF7F),
    serviceQuickLink: Color(0xFF9C9CAE),
    scrim: Color(0x99000000),
  );

  final Color background, surface, sunken, foreground, muted, border;
  final Color brand, brandStrong, brandTint, brandInk, onBrand;
  final Color structural, onStructural;
  final Color success, successTint, warning, warningTint, danger, dangerTint;
  final Color serviceAcademic, serviceSchedule, serviceNews, serviceMail;
  final Color serviceFinance,
      serviceSports,
      serviceSecondClass,
      serviceQuickLink;
  final Color scrim;
}

@immutable
class YhSpacingTokens {
  const YhSpacingTokens({
    this.xs = 4,
    this.s = 8,
    this.m = 16,
    this.l = 24,
    this.xl = 32,
    this.xl2 = 48,
  });
  final double xs, s, m, l, xl, xl2;
}

@immutable
class YhRadiusTokens {
  const YhRadiusTokens({
    this.s = 10,
    this.input = 12,
    this.m = 16,
    this.tile = 18,
    this.l = 24,
    this.full = 999,
  });
  final double s, input, m, tile, l, full;
}

@immutable
class YhTypographyTokens {
  const YhTypographyTokens({
    required this.hero,
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.small,
    required this.caption,
  });

  static const fontFamilyDisplay = 'MiSans';
  static const fontFamilyBody = 'MiSans';
  static const fontFamilyMono = 'MiSans';
  static const compactLineHeight = 1.0;

  static const standard = YhTypographyTokens(
    hero: TextStyle(
      fontFamily: fontFamilyDisplay,
      fontSize: 48,
      height: 1.15,
      fontWeight: FontWeight.w500,
      letterSpacing: -1.68,
    ),
    display: TextStyle(
      fontFamily: fontFamilyDisplay,
      fontSize: 36,
      height: 1.1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.72,
    ),
    h1: TextStyle(
      fontFamily: fontFamilyDisplay,
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.56,
    ),
    h2: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.22,
    ),
    h3: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 18,
      height: 1.4,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.18,
    ),
    body: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 15,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    small: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.13,
    ),
    caption: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 11,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.11,
    ),
  );

  final TextStyle hero, display, h1, h2, h3, body, small, caption;

  FontWeight get semibold => display.fontWeight!;
}

@immutable
class YhMotionTokens {
  const YhMotionTokens({
    this.fast = const Duration(milliseconds: 120),
    this.base = const Duration(milliseconds: 200),
    this.slow = const Duration(milliseconds: 320),
    this.curve = const Cubic(0.33, 0, 0.2, 1),
    this.pressedScale = 0.98,
  });
  final Duration fast, base, slow;
  final Curve curve;
  final double pressedScale;

  Duration effective(Duration duration, {required bool disableAnimations}) =>
      disableAnimations ? Duration.zero : duration;
}

@immutable
class YhProgressTokens {
  const YhProgressTokens({this.activitySweep = 0.25});

  final double activitySweep;
}

@immutable
class YhOpacityTokens {
  const YhOpacityTokens({
    this.domainTint = 0.14,
    this.contentMuted = 0.82,
    this.timelineMeta = 0.72,
    this.timelineDetail = 0.66,
    this.timelineTrack = 0.24,
    this.timelineDot = 0.48,
    this.timelineCurrentRing = 0.18,
    this.timelineOrbit = 0.18,
    this.timelineOrbitMid = 0.04,
    this.timelineOrbitOuter = 0.03,
  });

  final double domainTint, contentMuted;
  final double timelineMeta, timelineDetail, timelineTrack, timelineDot;
  final double timelineCurrentRing;
  final double timelineOrbit, timelineOrbitMid, timelineOrbitOuter;
}

@immutable
class YhBreakpointTokens {
  const YhBreakpointTokens({
    this.compact = 600,
    this.medium = 768,
    this.expanded = 1200,
    this.large = 1600,
  });
  final double compact, medium, expanded, large;
}

@immutable
class YhControlTokens {
  const YhControlTokens({
    this.compact = 40,
    this.regular = 48,
    this.touch = 48,
    this.minimumTarget = 48,
  });
  final double compact, regular, touch, minimumTarget;
}

@immutable
class YhResponsiveTokens {
  const YhResponsiveTokens({
    this.panelPaddingViewportPercent = 4,
    this.heroViewportPercent = 5,
    this.homePrimaryFlex = 33,
    this.homeSecondaryFlex = 16,
  });

  final double panelPaddingViewportPercent;
  final double heroViewportPercent;
  final int homePrimaryFlex;
  final int homeSecondaryFlex;
}

@immutable
class YhLayoutTokens {
  const YhLayoutTokens({
    this.divider = 1,
    this.controlBorder = 1.5,
    this.appBarHeight = 56,
    this.bottomNavigationHeight = 72,
    this.navRailCompactWidth = 80,
    this.navRailExpandedWidth = 220,
    this.statusProgressWidth = 240,
    this.settingsIndicatorWidth = 128,
    this.inlineControlWidth = 180,
    this.compactContentWidth = 220,
    this.popoverWidth = 320,
    this.formFieldWidth = 340,
    this.dialogWidth = 480,
    this.formContentWidth = 560,
    this.pageContentWidth = 1180,
  });

  final double divider;
  final double controlBorder;
  final double appBarHeight;
  final double bottomNavigationHeight;
  final double navRailCompactWidth;
  final double navRailExpandedWidth;
  final double statusProgressWidth;
  final double settingsIndicatorWidth;
  final double inlineControlWidth;
  final double compactContentWidth;
  final double popoverWidth;
  final double formFieldWidth;
  final double dialogWidth;
  final double formContentWidth;
  final double pageContentWidth;
}

@immutable
class YhFocusTokens {
  const YhFocusTokens({this.ringWidth = 2, this.ringGap = 2});
  final double ringWidth, ringGap;
}

@immutable
class YhElevationTokens {
  const YhElevationTokens({
    required this.e1,
    required this.e2,
    required this.e3,
  });

  static const light = YhElevationTokens(
    e1: [
      BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
    ],
    e2: [
      BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    e3: [
      BoxShadow(color: Color(0x29000000), blurRadius: 28, offset: Offset(0, 8)),
    ],
  );
  static const dark = YhElevationTokens(
    e1: [
      BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1)),
    ],
    e2: [
      BoxShadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    e3: [
      BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 8)),
    ],
  );

  final List<BoxShadow> e1, e2, e3;
}

@immutable
class YhTheme {
  const YhTheme({
    required this.color,
    this.spacing = const YhSpacingTokens(),
    this.radius = const YhRadiusTokens(),
    this.opacity = const YhOpacityTokens(),
    this.typography = YhTypographyTokens.standard,
    this.motion = const YhMotionTokens(),
    this.progress = const YhProgressTokens(),
    this.breakpoint = const YhBreakpointTokens(),
    this.responsive = const YhResponsiveTokens(),
    this.control = const YhControlTokens(),
    this.layout = const YhLayoutTokens(),
    this.focus = const YhFocusTokens(),
    required this.elevation,
  });

  static const light = YhTheme(
    color: YhColorTokens.light,
    elevation: YhElevationTokens.light,
  );
  static const dark = YhTheme(
    color: YhColorTokens.dark,
    elevation: YhElevationTokens.dark,
  );

  final YhColorTokens color;
  final YhSpacingTokens spacing;
  final YhRadiusTokens radius;
  final YhOpacityTokens opacity;
  final YhTypographyTokens typography;
  final YhMotionTokens motion;
  final YhProgressTokens progress;
  final YhBreakpointTokens breakpoint;
  final YhResponsiveTokens responsive;
  final YhControlTokens control;
  final YhLayoutTokens layout;
  final YhFocusTokens focus;
  final YhElevationTokens elevation;

  YhTheme copyWith({
    YhColorTokens? color,
    YhSpacingTokens? spacing,
    YhRadiusTokens? radius,
    YhOpacityTokens? opacity,
    YhTypographyTokens? typography,
    YhMotionTokens? motion,
    YhProgressTokens? progress,
    YhBreakpointTokens? breakpoint,
    YhResponsiveTokens? responsive,
    YhControlTokens? control,
    YhLayoutTokens? layout,
    YhFocusTokens? focus,
    YhElevationTokens? elevation,
  }) => YhTheme(
    color: color ?? this.color,
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
    opacity: opacity ?? this.opacity,
    typography: typography ?? this.typography,
    motion: motion ?? this.motion,
    progress: progress ?? this.progress,
    breakpoint: breakpoint ?? this.breakpoint,
    responsive: responsive ?? this.responsive,
    control: control ?? this.control,
    layout: layout ?? this.layout,
    focus: focus ?? this.focus,
    elevation: elevation ?? this.elevation,
  );

  YhTheme lerp(YhTheme other, double t) => t >= 0.5 ? other : this;
}

class YhThemeScope extends InheritedTheme {
  const YhThemeScope({super.key, required this.data, required super.child});

  final YhTheme data;

  static YhTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<YhThemeScope>();
    if (scope != null) return scope.data;
    final brightness = MediaQuery.maybeOf(context)?.platformBrightness;
    return brightness == Brightness.dark ? YhTheme.dark : YhTheme.light;
  }

  @override
  bool updateShouldNotify(YhThemeScope oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      YhThemeScope(data: data, child: child);
}

extension YhThemeContext on BuildContext {
  YhTheme get yhTheme => YhThemeScope.of(this);
}
