/*
 * Fluent 业务强调令牌 — 校园业务域色、课程色板、渐变与度量
 * @Project : SSPU-AllinOne
 * @File : fluent_accent_tokens.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 *
 * UI Refresh 2026 业务层只允许引用这些语义色和尺寸令牌，避免页面各自硬编码。
 */

import 'package:flutter/material.dart';

/// 业务域强调色集合。
@immutable
class FluentAccentColors extends ThemeExtension<FluentAccentColors> {
  const FluentAccentColors({
    required this.academic,
    required this.schedule,
    required this.information,
    required this.mail,
    required this.finance,
    required this.sports,
    required this.secondClassroom,
    required this.quickLink,
  });

  /// 教务 / 学籍。
  final Color academic;

  /// 课表。
  final Color schedule;

  /// 信息中心。
  final Color information;

  /// 邮箱。
  final Color mail;

  /// 校园卡 / 财务。
  final Color finance;

  /// 体育考勤。
  final Color sports;

  /// 第二课堂。
  final Color secondClassroom;

  /// 快速跳转。
  final Color quickLink;

  @override
  FluentAccentColors copyWith({
    Color? academic,
    Color? schedule,
    Color? information,
    Color? mail,
    Color? finance,
    Color? sports,
    Color? secondClassroom,
    Color? quickLink,
  }) {
    return FluentAccentColors(
      academic: academic ?? this.academic,
      schedule: schedule ?? this.schedule,
      information: information ?? this.information,
      mail: mail ?? this.mail,
      finance: finance ?? this.finance,
      sports: sports ?? this.sports,
      secondClassroom: secondClassroom ?? this.secondClassroom,
      quickLink: quickLink ?? this.quickLink,
    );
  }

  @override
  FluentAccentColors lerp(ThemeExtension<FluentAccentColors>? other, double t) {
    if (other is! FluentAccentColors) return this;
    return FluentAccentColors(
      academic: Color.lerp(academic, other.academic, t)!,
      schedule: Color.lerp(schedule, other.schedule, t)!,
      information: Color.lerp(information, other.information, t)!,
      mail: Color.lerp(mail, other.mail, t)!,
      finance: Color.lerp(finance, other.finance, t)!,
      sports: Color.lerp(sports, other.sports, t)!,
      secondClassroom: Color.lerp(secondClassroom, other.secondClassroom, t)!,
      quickLink: Color.lerp(quickLink, other.quickLink, t)!,
    );
  }

  /// 亮色业务强调色。
  static const FluentAccentColors light = FluentAccentColors(
    academic: Color(0xFF0F6CBD),
    schedule: Color(0xFF0078D4),
    information: Color(0xFF8764B8),
    mail: Color(0xFF0078A8),
    finance: Color(0xFF107C10),
    sports: Color(0xFFC239B3),
    secondClassroom: Color(0xFFCA5010),
    quickLink: Color(0xFF038387),
  );

  /// 暗色业务强调色。
  static const FluentAccentColors dark = FluentAccentColors(
    academic: Color(0xFF62ABF5),
    schedule: Color(0xFF60CDFF),
    information: Color(0xFFB4A0FF),
    mail: Color(0xFF6CCBFF),
    finance: Color(0xFF6CCB5F),
    sports: Color(0xFFE8A3DE),
    secondClassroom: Color(0xFFFFB386),
    quickLink: Color(0xFF68D8D6),
  );
}

/// 课程色板，按课程名稳定映射。
@immutable
class FluentCoursePalette extends ThemeExtension<FluentCoursePalette> {
  const FluentCoursePalette({required this.colors});

  /// 可分配的课程颜色。
  final List<Color> colors;

  /// 根据任意 key 稳定选取课程颜色。
  Color colorFor(String key) {
    if (colors.isEmpty) return const Color(0xFF0F6CBD);
    final normalized = key.trim();
    if (normalized.isEmpty) return colors.first;
    var hash = 0;
    for (final codeUnit in normalized.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return colors[hash.abs() % colors.length];
  }

  @override
  FluentCoursePalette copyWith({List<Color>? colors}) {
    return FluentCoursePalette(colors: colors ?? this.colors);
  }

  @override
  FluentCoursePalette lerp(
    ThemeExtension<FluentCoursePalette>? other,
    double t,
  ) {
    if (other is! FluentCoursePalette) return this;
    return t < 0.5 ? this : other;
  }

  /// 亮色课程色板。
  static const FluentCoursePalette light = FluentCoursePalette(
    colors: [
      Color(0xFF0F6CBD),
      Color(0xFF107C10),
      Color(0xFFC239B3),
      Color(0xFFCA5010),
      Color(0xFF038387),
      Color(0xFF8764B8),
      Color(0xFF8E562E),
      Color(0xFF69797E),
      Color(0xFFB146C2),
      Color(0xFF498205),
    ],
  );

  /// 暗色课程色板。
  static const FluentCoursePalette dark = FluentCoursePalette(
    colors: [
      Color(0xFF62ABF5),
      Color(0xFF6CCB5F),
      Color(0xFFE8A3DE),
      Color(0xFFFFB386),
      Color(0xFF68D8D6),
      Color(0xFFB4A0FF),
      Color(0xFFD8B094),
      Color(0xFFA6B9BF),
      Color(0xFFE6A3FF),
      Color(0xFFA7D46F),
    ],
  );
}

/// 语义渐变令牌。
@immutable
class FluentGradients extends ThemeExtension<FluentGradients> {
  const FluentGradients({
    required this.dashboardHero,
    required this.cardSheen,
    required this.courseNow,
  });

  /// 首页仪表盘顶部渐变。
  final LinearGradient dashboardHero;

  /// 卡片轻微材质渐变。
  final LinearGradient cardSheen;

  /// 当前课程高亮渐变。
  final LinearGradient courseNow;

  @override
  FluentGradients copyWith({
    LinearGradient? dashboardHero,
    LinearGradient? cardSheen,
    LinearGradient? courseNow,
  }) {
    return FluentGradients(
      dashboardHero: dashboardHero ?? this.dashboardHero,
      cardSheen: cardSheen ?? this.cardSheen,
      courseNow: courseNow ?? this.courseNow,
    );
  }

  @override
  FluentGradients lerp(ThemeExtension<FluentGradients>? other, double t) {
    if (other is! FluentGradients) return this;
    return FluentGradients(
      dashboardHero: LinearGradient.lerp(
        dashboardHero,
        other.dashboardHero,
        t,
      )!,
      cardSheen: LinearGradient.lerp(cardSheen, other.cardSheen, t)!,
      courseNow: LinearGradient.lerp(courseNow, other.courseNow, t)!,
    );
  }

  /// 亮色渐变。
  static const FluentGradients light = FluentGradients(
    dashboardHero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEBF3FC), Color(0xFFF6FAFE), Color(0xFFFFFFFF)],
    ),
    cardSheen: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    ),
    courseNow: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEAF6FF), Color(0xFFFFFFFF)],
    ),
  );

  /// 暗色渐变。
  static const FluentGradients dark = FluentGradients(
    dashboardHero: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF17324A), Color(0xFF1F1F1F), Color(0xFF292929)],
    ),
    cardSheen: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF292929), Color(0xFF1F1F1F)],
    ),
    courseNow: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF14324A), Color(0xFF292929)],
    ),
  );
}

/// 应用级布局度量令牌。
@immutable
class AppMetrics extends ThemeExtension<AppMetrics> {
  const AppMetrics();

  /// 页面内容最大宽度。
  double get contentMaxWidth => 1280;

  /// 阅读型内容最大宽度。
  double get readableMaxWidth => 920;

  /// 首页磁贴最小高度。
  double get dashboardTileMinHeight => 176;

  /// 首页小磁贴最小高度。
  double get dashboardCompactTileMinHeight => 132;

  /// 业务卡片桌面高度。
  double get businessCardHeight => 224;

  /// 快速跳转磁贴尺寸。
  double get quickLinkTileWidth => 156;

  /// 课表节次列宽。
  double get schedulePeriodColumnWidth => 82;

  /// 课表单元格最小高度。
  double get scheduleCellMinHeight => 76;

  @override
  AppMetrics copyWith() => const AppMetrics();

  @override
  AppMetrics lerp(ThemeExtension<AppMetrics>? other, double t) => this;
}
