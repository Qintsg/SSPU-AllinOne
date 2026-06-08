/*
 * 全局学期模型 — 描述学年、学期、周数和校历解析结果
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
  /// 用户手动设置。
  manual,

  /// 内置校历自动计算。
  automatic,

  /// 自动计算未命中，已回退手动设置。
  unresolved,
}

/// 学年、学期与周数选择。
class AcademicTermSelection {
  const AcademicTermSelection({
    required this.academicYear,
    required this.season,
    required this.week,
  });

  /// 学年起始年份，例如 2025 表示 2025 学年。
  final int academicYear;

  /// 学期类型。
  final AcademicTermSeason season;

  /// 当前周数，从 1 开始。
  final int week;

  /// 该学期总周数。
  int get totalWeeks => season.totalWeeks;

  /// 标准化周数，确保不会超过当前学期总周数。
  AcademicTermSelection normalized() {
    return AcademicTermSelection(
      academicYear: academicYear.clamp(2000, 2100),
      season: season,
      week: week.clamp(1, season.totalWeeks),
    );
  }

  /// 复制并替换部分字段。
  AcademicTermSelection copyWith({
    int? academicYear,
    AcademicTermSeason? season,
    int? week,
  }) {
    final nextSeason = season ?? this.season;
    return AcademicTermSelection(
      academicYear: academicYear ?? this.academicYear,
      season: nextSeason,
      week: (week ?? this.week).clamp(1, nextSeason.totalWeeks),
    );
  }

  /// 展示名称。
  String get label => '$academicYear 学年${season.label}';

  /// 带周数的展示名称。
  String get weekLabel => '$label 第 $week / $totalWeeks 周';

  /// 转换为 JSON。
  Map<String, Object?> toJson() {
    return {'academicYear': academicYear, 'season': season.code, 'week': week};
  }

  /// 从 JSON 恢复选择。
  factory AcademicTermSelection.fromJson(Map<String, Object?> json) {
    return AcademicTermSelection(
      academicYear: (json['academicYear'] as num?)?.toInt() ?? 2025,
      season: AcademicTermSeason.fromCode(json['season'] as String?),
      week: (json['week'] as num?)?.toInt() ?? 1,
    ).normalized();
  }

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
  const AcademicTermSettings({
    required this.autoSwitchEnabled,
    required this.manualSelection,
  });

  /// 是否启用内置校历自动切换。
  final bool autoSwitchEnabled;

  /// 用户手动设置的学期。
  final AcademicTermSelection manualSelection;

  /// 复制并替换部分字段。
  AcademicTermSettings copyWith({
    bool? autoSwitchEnabled,
    AcademicTermSelection? manualSelection,
  }) {
    return AcademicTermSettings(
      autoSwitchEnabled: autoSwitchEnabled ?? this.autoSwitchEnabled,
      manualSelection: manualSelection ?? this.manualSelection,
    );
  }
}

/// 生效学期上下文。
class AcademicTermContext {
  const AcademicTermContext({
    required this.selection,
    required this.manualSelection,
    required this.autoSwitchEnabled,
    required this.source,
    required this.resolvedAt,
    this.message,
  });

  /// 当前生效学期。
  final AcademicTermSelection selection;

  /// 当前手动学期设置。
  final AcademicTermSelection manualSelection;

  /// 是否启用自动切换。
  final bool autoSwitchEnabled;

  /// 当前生效值来源。
  final AcademicTermContextSource source;

  /// 解析时间。
  final DateTime resolvedAt;

  /// 状态说明。
  final String? message;

  /// 是否来自内置校历自动计算。
  bool get isAutomatic => source == AcademicTermContextSource.automatic;

  /// 是否自动计算未命中。
  bool get isUnresolved => source == AcademicTermContextSource.unresolved;
}

/// 单段校历。
class AcademicTermCalendarSegment {
  AcademicTermCalendarSegment({
    required this.academicYear,
    required this.season,
    required DateTime startDate,
    required DateTime endDate,
    required this.startWeek,
  }) : startDate = _dateOnly(startDate),
       endDate = _dateOnly(endDate) {
    assert(!this.endDate.isBefore(this.startDate));
    assert(startWeek >= 1);
    assert(startWeek <= season.totalWeeks);
    assert(endWeek <= season.totalWeeks);
  }

  /// 学年起始年份。
  final int academicYear;

  /// 学期类型。
  final AcademicTermSeason season;

  /// 该校历段起始日期，含当天。
  final DateTime startDate;

  /// 该校历段结束日期，含当天。
  final DateTime endDate;

  /// 该校历段第一天对应的学期周数。
  final int startWeek;

  /// 该校历段最后一天对应的学期周数。
  int get endWeek => startWeek + endDate.difference(startDate).inDays ~/ 7;

  /// 判断日期是否落在该校历段内。
  bool contains(DateTime date) {
    final target = _dateOnly(date);
    return !target.isBefore(startDate) && !target.isAfter(endDate);
  }

  /// 将日期解析为学期选择。
  AcademicTermSelection resolve(DateTime date) {
    final target = _dateOnly(date);
    final week = startWeek + target.difference(startDate).inDays ~/ 7;
    return AcademicTermSelection(
      academicYear: academicYear,
      season: season,
      week: week,
    ).normalized();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
