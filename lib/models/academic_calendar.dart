/*
 * 校历模型 — 描述教务处校历元数据、结构化学期与日期标签
 * @Project : SSPU-AllinOne
 * @File : academic_calendar.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'academic_term.dart';

/// 校历来源资源类型。
enum AcademicCalendarSourceType {
  /// 已解析 PDF。
  pdf('pdf', 'PDF'),

  /// 仅解析到图片。
  image('image', '图片'),

  /// 同时包含 PDF 与图片。
  mixed('mixed', 'PDF + 图片'),

  /// 未识别资源。
  unknown('unknown', '未知');

  const AcademicCalendarSourceType(this.code, this.label);

  /// 持久化代码。
  final String code;

  /// 展示名称。
  final String label;

  /// 从持久化代码恢复来源类型。
  static AcademicCalendarSourceType fromCode(String? code) {
    return AcademicCalendarSourceType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => AcademicCalendarSourceType.unknown,
    );
  }
}

/// 日期标签类型。
enum AcademicCalendarDayTagType {
  /// 工作日。
  workday('workday', '工作日'),

  /// 休息日。
  restDay('restDay', '休息日'),

  /// 假期。
  holiday('holiday', '假期'),

  /// 运动会停课日。
  sportsDay('sportsDay', '运动会停课日');

  const AcademicCalendarDayTagType(this.code, this.label);

  /// 持久化代码。
  final String code;

  /// 展示名称。
  final String label;

  /// 从持久化代码恢复日期标签。
  static AcademicCalendarDayTagType fromCode(String? code) {
    return AcademicCalendarDayTagType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => AcademicCalendarDayTagType.holiday,
    );
  }
}

/// 校历列表项。
class AcademicCalendarListItem {
  const AcademicCalendarListItem({
    required this.title,
    required this.detailUrl,
    required this.publishDate,
    required this.schoolYearStart,
    required this.schoolYearEnd,
  });

  /// 标题。
  final String title;

  /// 详情页 URL。
  final String detailUrl;

  /// 发布日期。
  final String publishDate;

  /// 学年起始年份。
  final int schoolYearStart;

  /// 学年结束年份。
  final int schoolYearEnd;

  /// 学年标签。
  String get schoolYearLabel => '$schoolYearStart-$schoolYearEnd学年校历';
}

/// 校历详情资源。
class AcademicCalendarAssets {
  const AcademicCalendarAssets({
    required this.pdfUrl,
    required this.imageUrls,
    required this.sourceType,
  });

  /// PDF URL。
  final String? pdfUrl;

  /// 图片 URL。
  final List<String> imageUrls;

  /// 来源类型。
  final AcademicCalendarSourceType sourceType;
}

/// 日期级标签。
class AcademicCalendarDayTag {
  AcademicCalendarDayTag({
    required DateTime date,
    required this.type,
    required this.label,
    required this.sourceText,
  }) : date = AcademicTermDefinition.dateOnly(date);

  /// 日期。
  final DateTime date;

  /// 标签类型。
  final AcademicCalendarDayTagType type;

  /// 展示标签。
  final String label;

  /// 来源原文。
  final String sourceText;

  /// 转换为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'date': _formatDate(date),
      'type': type.code,
      'label': label,
      'sourceText': sourceText,
    };
  }

  /// 从 JSON 恢复。
  factory AcademicCalendarDayTag.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarDayTag(
      date: DateTime.parse(json['date'] as String),
      type: AcademicCalendarDayTagType.fromCode(json['type'] as String?),
      label: json['label'] as String? ?? '',
      sourceText: json['sourceText'] as String? ?? '',
    );
  }
}

/// 未补全节假日说明。
class AcademicCalendarPendingHolidayNotice {
  const AcademicCalendarPendingHolidayNotice({required this.sourceText});

  /// 来源原文。
  final String sourceText;

  /// 转换为 JSON。
  Map<String, dynamic> toJson() => {'sourceText': sourceText};

  /// 从 JSON 恢复。
  factory AcademicCalendarPendingHolidayNotice.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicCalendarPendingHolidayNotice(
      sourceText: json['sourceText'] as String? ?? '',
    );
  }
}

/// 结构化校历结果。
class AcademicCalendarTermSchedule {
  AcademicCalendarTermSchedule({
    required this.schoolYearStart,
    required DateTime fallStart,
    required DateTime fallEnd,
    required DateTime springStart,
    required DateTime springEnd,
    required DateTime summerStart,
    required DateTime summerEnd,
    required List<AcademicTermTeachingSegment> summerSegments,
    required List<AcademicCalendarDayTag> dayTags,
    required List<AcademicCalendarPendingHolidayNotice> pendingHolidayNotices,
    required List<String> parseWarnings,
  }) : fallStart = AcademicTermDefinition.dateOnly(fallStart),
       fallEnd = AcademicTermDefinition.dateOnly(fallEnd),
       springStart = AcademicTermDefinition.dateOnly(springStart),
       springEnd = AcademicTermDefinition.dateOnly(springEnd),
       summerStart = AcademicTermDefinition.dateOnly(summerStart),
       summerEnd = AcademicTermDefinition.dateOnly(summerEnd),
       summerSegments = List.unmodifiable(summerSegments),
       dayTags = List.unmodifiable(dayTags),
       pendingHolidayNotices = List.unmodifiable(pendingHolidayNotices),
       parseWarnings = List.unmodifiable(parseWarnings);

  /// 学年起始年份。
  final int schoolYearStart;

  /// 秋季学期开始。
  final DateTime fallStart;

  /// 秋季学期结束。
  final DateTime fallEnd;

  /// 春季学期开始。
  final DateTime springStart;

  /// 春季学期结束。
  final DateTime springEnd;

  /// 夏季学期长范围开始。
  final DateTime summerStart;

  /// 夏季学期长范围结束。
  final DateTime summerEnd;

  /// 夏季教学段。
  final List<AcademicTermTeachingSegment> summerSegments;

  /// 日期标签。
  final List<AcademicCalendarDayTag> dayTags;

  /// 未补全节假日说明。
  final List<AcademicCalendarPendingHolidayNotice> pendingHolidayNotices;

  /// 解析警告。
  final List<String> parseWarnings;

  /// 转换为学期定义。
  List<AcademicTermDefinition> toTermDefinitions() {
    return [
      AcademicTermDefinition(
        choice: AcademicTermChoice(
          academicYear: schoolYearStart,
          season: AcademicTermSeason.fall,
        ),
        startDate: fallStart,
        endDate: fallEnd,
        teachingSegments: [
          AcademicTermTeachingSegment(
            startDate: fallStart,
            endDate: fallEnd,
            startWeek: 1,
            endWeek: AcademicTermSeason.fall.totalWeeks,
          ),
        ],
      ),
      AcademicTermDefinition(
        choice: AcademicTermChoice(
          academicYear: schoolYearStart,
          season: AcademicTermSeason.spring,
        ),
        startDate: springStart,
        endDate: springEnd,
        teachingSegments: [
          AcademicTermTeachingSegment(
            startDate: springStart,
            endDate: springEnd,
            startWeek: 1,
            endWeek: AcademicTermSeason.spring.totalWeeks,
          ),
        ],
      ),
      AcademicTermDefinition(
        choice: AcademicTermChoice(
          academicYear: schoolYearStart,
          season: AcademicTermSeason.summer,
        ),
        startDate: summerStart,
        endDate: summerEnd,
        teachingSegments: summerSegments,
      ),
    ];
  }

  /// 转换为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'schoolYearStart': schoolYearStart,
      'fallStart': _formatDate(fallStart),
      'fallEnd': _formatDate(fallEnd),
      'springStart': _formatDate(springStart),
      'springEnd': _formatDate(springEnd),
      'summerStart': _formatDate(summerStart),
      'summerEnd': _formatDate(summerEnd),
      'summerSegments': summerSegments
          .map(
            (segment) => {
              'startDate': _formatDate(segment.startDate),
              'endDate': _formatDate(segment.endDate),
              'startWeek': segment.startWeek,
              'endWeek': segment.endWeek,
            },
          )
          .toList(),
      'dayTags': dayTags.map((tag) => tag.toJson()).toList(),
      'pendingHolidayNotices': pendingHolidayNotices
          .map((notice) => notice.toJson())
          .toList(),
      'parseWarnings': parseWarnings,
    };
  }

  /// 从 JSON 恢复。
  factory AcademicCalendarTermSchedule.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarTermSchedule(
      schoolYearStart: (json['schoolYearStart'] as num).toInt(),
      fallStart: DateTime.parse(json['fallStart'] as String),
      fallEnd: DateTime.parse(json['fallEnd'] as String),
      springStart: DateTime.parse(json['springStart'] as String),
      springEnd: DateTime.parse(json['springEnd'] as String),
      summerStart: DateTime.parse(json['summerStart'] as String),
      summerEnd: DateTime.parse(json['summerEnd'] as String),
      summerSegments:
          (json['summerSegments'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) {
                final payload = Map<String, dynamic>.from(item);
                return AcademicTermTeachingSegment(
                  startDate: DateTime.parse(payload['startDate'] as String),
                  endDate: DateTime.parse(payload['endDate'] as String),
                  startWeek: (payload['startWeek'] as num).toInt(),
                  endWeek: (payload['endWeek'] as num).toInt(),
                );
              })
              .toList(),
      dayTags: (json['dayTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AcademicCalendarDayTag.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      pendingHolidayNotices:
          (json['pendingHolidayNotices'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map(
                (item) => AcademicCalendarPendingHolidayNotice.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
      parseWarnings:
          (json['parseWarnings'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

/// 校历缓存条目。
class AcademicCalendarCacheEntry {
  AcademicCalendarCacheEntry({
    required this.schoolYearStart,
    required this.title,
    required this.detailUrl,
    required this.publishDate,
    required this.pdfUrl,
    required List<String> imageUrls,
    required this.sourceType,
    required DateTime fetchedAt,
    required this.parseVersion,
    required this.pdfFilePath,
    required this.rawTextFilePath,
    required this.rawExtractedText,
    required this.schedule,
    required List<String> warnings,
    required this.errorMessage,
    this.isStale = false,
  }) : imageUrls = List.unmodifiable(imageUrls),
       fetchedAt = fetchedAt.toUtc(),
       warnings = List.unmodifiable(warnings);

  /// 学年起始年份。
  final int schoolYearStart;

  /// 标题。
  final String title;

  /// 详情页 URL。
  final String detailUrl;

  /// 发布日期。
  final String publishDate;

  /// PDF URL。
  final String? pdfUrl;

  /// 图片 URL。
  final List<String> imageUrls;

  /// 来源类型。
  final AcademicCalendarSourceType sourceType;

  /// 抓取时间。
  final DateTime fetchedAt;

  /// 解析版本。
  final int parseVersion;

  /// 本地 PDF 路径。
  final String? pdfFilePath;

  /// 本地原始文本路径。
  final String? rawTextFilePath;

  /// 原始解析文本，Web 或测试环境可直接放入缓存。
  final String? rawExtractedText;

  /// 结构化学期结果。
  final AcademicCalendarTermSchedule? schedule;

  /// 警告。
  final List<String> warnings;

  /// 错误信息。
  final String? errorMessage;

  /// 是否因刷新失败而沿用旧缓存。
  final bool isStale;

  /// 是否具备结构化学期数据。
  bool get hasStructuredSchedule => schedule != null;

  /// 展示学年。
  String get schoolYearLabel => '$schoolYearStart-${schoolYearStart + 1}学年';

  /// 复制并替换部分字段。
  AcademicCalendarCacheEntry copyWith({
    bool? isStale,
    String? errorMessage,
    List<String>? warnings,
  }) {
    return AcademicCalendarCacheEntry(
      schoolYearStart: schoolYearStart,
      title: title,
      detailUrl: detailUrl,
      publishDate: publishDate,
      pdfUrl: pdfUrl,
      imageUrls: imageUrls,
      sourceType: sourceType,
      fetchedAt: fetchedAt,
      parseVersion: parseVersion,
      pdfFilePath: pdfFilePath,
      rawTextFilePath: rawTextFilePath,
      rawExtractedText: rawExtractedText,
      schedule: schedule,
      warnings: warnings ?? this.warnings,
      errorMessage: errorMessage ?? this.errorMessage,
      isStale: isStale ?? this.isStale,
    );
  }

  /// 转换为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'schoolYearStart': schoolYearStart,
      'title': title,
      'detailUrl': detailUrl,
      'publishDate': publishDate,
      'pdfUrl': pdfUrl,
      'imageUrls': imageUrls,
      'sourceType': sourceType.code,
      'fetchedAt': fetchedAt.toIso8601String(),
      'parseVersion': parseVersion,
      'pdfFilePath': pdfFilePath,
      'rawTextFilePath': rawTextFilePath,
      'rawExtractedText': rawExtractedText,
      'schedule': schedule?.toJson(),
      'warnings': warnings,
      'errorMessage': errorMessage,
      'isStale': isStale,
    };
  }

  /// 从 JSON 恢复。
  factory AcademicCalendarCacheEntry.fromJson(Map<String, dynamic> json) {
    return AcademicCalendarCacheEntry(
      schoolYearStart: (json['schoolYearStart'] as num).toInt(),
      title: json['title'] as String? ?? '',
      detailUrl: json['detailUrl'] as String? ?? '',
      publishDate: json['publishDate'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      sourceType: AcademicCalendarSourceType.fromCode(
        json['sourceType'] as String?,
      ),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      parseVersion: (json['parseVersion'] as num?)?.toInt() ?? 1,
      pdfFilePath: json['pdfFilePath'] as String?,
      rawTextFilePath: json['rawTextFilePath'] as String?,
      rawExtractedText: json['rawExtractedText'] as String?,
      schedule: json['schedule'] is Map
          ? AcademicCalendarTermSchedule.fromJson(
              Map<String, dynamic>.from(json['schedule'] as Map),
            )
          : null,
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      errorMessage: json['errorMessage'] as String?,
      isStale: json['isStale'] as bool? ?? false,
    );
  }
}

/// 校历同步结果。
class AcademicCalendarSyncResult {
  const AcademicCalendarSyncResult({
    required this.entries,
    required this.loadedFromCache,
    required this.refreshed,
    this.errorMessage,
  });

  /// 校历条目。
  final List<AcademicCalendarCacheEntry> entries;

  /// 是否读取了缓存。
  final bool loadedFromCache;

  /// 是否发生网络刷新。
  final bool refreshed;

  /// 错误信息。
  final String? errorMessage;

  /// 是否成功。
  bool get isSuccess => errorMessage == null;
}

String _formatDate(DateTime date) {
  final normalized = AcademicTermDefinition.dateOnly(date);
  return normalized.toIso8601String().split('T').first;
}
