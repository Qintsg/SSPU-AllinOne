/*
 * 全局学期模型 — 描述学年、学期、周数、教学段和假期状态
 * @Project : SSPU-AllinOne
 * @File : academic_term.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

/// 学期类型。
enum AcademicTermSeason {
  /// 秋季学期。
  fall('fall', '秋季学期', 17),

  /// 春季学期。
  spring('spring', '春季学期', 17),

  /// 夏季学期。
  summer('summer', '夏季学期', 5);

  const AcademicTermSeason(this.code, this.label, this.totalWeeks);

  /// 可持久化代码。
  final String code;

  /// 中文显示名称。
  final String label;

  /// 该学期总周数。
  final int totalWeeks;

  /// 从持久化代码恢复学期类型。
  static AcademicTermSeason fromCode(String? code) {
    return AcademicTermSeason.values.firstWhere(
      (season) => season.code == code,
      orElse: () => AcademicTermSeason.fall,
    );
  }
}

/// 当前学期来源。
enum AcademicTermContextSource {
  /// 用户选择的全局学期。
  selected,

  /// 未设置全局学期时按内置校历自动匹配。
  automatic,

  /// 所选学期暂无内置校历，无法定位日期。
  unsupported,
}

/// 当前日期在所选学期中的状态。
enum AcademicTermDateStatus {
  /// 教学周或考试周。
  teaching,

  /// 暑假。
  summerVacation,

  /// 寒假。
  winterVacation,

  /// 暂无内置校历，无法定位。
  unsupported,
}

/// 学年与学期选择。
class AcademicTermChoice {
  const AcademicTermChoice({required this.academicYear, required this.season});

  /// 学年起始年份，例如 2025 表示 2025-2026 学年。
  final int academicYear;

  /// 学期类型。
  final AcademicTermSeason season;

  /// 展示名称。
  String get label => '$academicYear-${academicYear + 1} 学年${season.label}';

  /// 复制并替换部分字段。
  AcademicTermChoice copyWith({int? academicYear, AcademicTermSeason? season}) {
    return AcademicTermChoice(
      academicYear: academicYear ?? this.academicYear,
      season: season ?? this.season,
    );
  }

  /// 转换为 JSON。
  Map<String, Object?> toJson() {
    return {'academicYear': academicYear, 'season': season.code};
  }

  /// 从 JSON 恢复选择。
  factory AcademicTermChoice.fromJson(Map<String, Object?> json) {
    return AcademicTermChoice(
      academicYear: (json['academicYear'] as num?)?.toInt() ?? 2025,
      season: AcademicTermSeason.fromCode(json['season'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AcademicTermChoice &&
        other.academicYear == academicYear &&
        other.season == season;
  }

  @override
  int get hashCode => Object.hash(academicYear, season);

  @override
  String toString() => label;
}

/// 学年、学期与周数结果。
class AcademicTermSelection {
  const AcademicTermSelection({
    required this.academicYear,
    required this.season,
    required this.week,
  });

  /// 学年起始年份，例如 2025 表示 2025-2026 学年。
  final int academicYear;

  /// 学期类型。
  final AcademicTermSeason season;

  /// 当前周数；允许为负数，表示距离第 1 周开始还有几周；不允许为 0。
  final int week;

  /// 该学期总周数。
  int get totalWeeks => season.totalWeeks;

  /// 学期选择。
  AcademicTermChoice get choice =>
      AcademicTermChoice(academicYear: academicYear, season: season);

  /// 展示名称。
  String get label => choice.label;

  /// 带周数的展示名称。
  String get weekLabel => '$label 第 $week / $totalWeeks 周';

  @override
  bool operator ==(Object other) {
    return other is AcademicTermSelection &&
        other.academicYear == academicYear &&
        other.season == season &&
        other.week == week;
  }

  @override
  int get hashCode => Object.hash(academicYear, season, week);

  @override
  String toString() => weekLabel;
}

/// 学期设置。
class AcademicTermSettings {
  const AcademicTermSettings({this.selectedTerm});

  /// 用户选择的全局学期；为空时由内置校历按当前日期自动匹配。
  final AcademicTermChoice? selectedTerm;

  /// 复制并替换部分字段。
  AcademicTermSettings copyWith({AcademicTermChoice? selectedTerm}) {
    return AcademicTermSettings(
      selectedTerm: selectedTerm ?? this.selectedTerm,
    );
  }
}

/// 生效学期上下文。
class AcademicTermContext {
  const AcademicTermContext({
    required this.term,
    required this.source,
    required this.dateStatus,
    required this.resolvedAt,
    required this.isTeachingWeek,
    this.selection,
    this.definition,
    this.message,
  });

  /// 当前全局学期。
  final AcademicTermChoice term;

  /// 带周数的定位结果；假期或无内置校历时可能为空。
  final AcademicTermSelection? selection;

  /// 当前学期定义。
  final AcademicTermDefinition? definition;

  /// 当前生效值来源。
  final AcademicTermContextSource source;

  /// 当前日期在所选学期中的状态。
  final AcademicTermDateStatus dateStatus;

  /// 解析时间。
  final DateTime resolvedAt;

  /// 是否处于教学周。
  final bool isTeachingWeek;

  /// 状态说明。
  final String? message;

  /// 是否来自内置校历定位。
  bool get isLocated => selection != null;

  /// 是否暂无内置校历。
  bool get isUnsupported => dateStatus == AcademicTermDateStatus.unsupported;

  /// 概览文本。
  String get summaryLabel {
    return switch (dateStatus) {
      AcademicTermDateStatus.teaching => selection?.weekLabel ?? term.label,
      AcademicTermDateStatus.summerVacation => '${term.label} 暑假',
      AcademicTermDateStatus.winterVacation => '${term.label} 寒假',
      AcademicTermDateStatus.unsupported => '${term.label} 暂无内置校历',
    };
  }

  /// 状态标签。
  String get statusLabel {
    return switch (dateStatus) {
      AcademicTermDateStatus.teaching => '教学周',
      AcademicTermDateStatus.summerVacation => '暑假',
      AcademicTermDateStatus.winterVacation => '寒假',
      AcademicTermDateStatus.unsupported => '无法定位',
    };
  }
}

/// 单段教学周。
class AcademicTermTeachingSegment {
  AcademicTermTeachingSegment({
    required DateTime startDate,
    required DateTime endDate,
    required this.startWeek,
    required this.endWeek,
  }) : startDate = AcademicTermDefinition.dateOnly(startDate),
       endDate = AcademicTermDefinition.dateOnly(endDate) {
    assert(!this.endDate.isBefore(this.startDate));
    assert(startWeek >= 1);
    assert(endWeek >= startWeek);
  }

  /// 起始日期，含当天。
  final DateTime startDate;

  /// 结束日期，含当天。
  final DateTime endDate;

  /// 起始周数。
  final int startWeek;

  /// 结束周数。
  final int endWeek;

  /// 判断日期是否落在该教学段内。
  bool contains(DateTime date) {
    final target = AcademicTermDefinition.dateOnly(date);
    return !target.isBefore(startDate) && !target.isAfter(endDate);
  }

  /// 将日期解析为教学周数。
  int resolveWeek(DateTime date) {
    final targetMonday = AcademicTermDefinition.weekMonday(date);
    final startMonday = AcademicTermDefinition.weekMonday(startDate);
    final week = startWeek + targetMonday.difference(startMonday).inDays ~/ 7;
    return week.clamp(startWeek, endWeek);
  }
}

/// 单个学期定义。
class AcademicTermDefinition {
  AcademicTermDefinition({
    required this.choice,
    required DateTime startDate,
    required DateTime endDate,
    required List<AcademicTermTeachingSegment> teachingSegments,
  }) : startDate = dateOnly(startDate),
       endDate = dateOnly(endDate),
       teachingSegments = List.unmodifiable(teachingSegments) {
    assert(!this.endDate.isBefore(this.startDate));
  }

  /// 学期选择。
  final AcademicTermChoice choice;

  /// 学期长范围开始日期。
  final DateTime startDate;

  /// 学期长范围结束日期。
  final DateTime endDate;

  /// 教学周段。夏季学期可有多个不连续教学段。
  final List<AcademicTermTeachingSegment> teachingSegments;

  /// 判断日期是否落在学期长范围内。
  bool contains(DateTime date) {
    final target = dateOnly(date);
    return !target.isBefore(startDate) && !target.isAfter(endDate);
  }

  /// 判断日期是否落在教学周段内。
  AcademicTermTeachingSegment? teachingSegmentFor(DateTime date) {
    for (final segment in teachingSegments) {
      if (segment.contains(date)) return segment;
    }
    return null;
  }

  /// 按学期开始周一计算周数，允许负数，不返回 0。
  int relativeWeekFor(DateTime date) {
    final diffWeeks =
        weekMonday(date).difference(weekMonday(startDate)).inDays ~/ 7;
    return diffWeeks >= 0 ? diffWeeks + 1 : diffWeeks;
  }

  /// 转为带周数选择。
  AcademicTermSelection selectionFor(DateTime date, {int? week}) {
    final resolvedWeek = week ?? relativeWeekFor(date);
    return AcademicTermSelection(
      academicYear: choice.academicYear,
      season: choice.season,
      week: resolvedWeek == 0 ? -1 : resolvedWeek,
    );
  }

  /// 日期归一到当天零点。
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 取日期所在周的周一。
  static DateTime weekMonday(DateTime date) {
    final target = dateOnly(date);
    return target.subtract(Duration(days: target.weekday - DateTime.monday));
  }
}
