/*
 * 本专科教务系统开课检索模型
 * @Project : SSPU-AllinOne
 * @File : course_offerings.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

/// 开课检索条件。
class AcademicCourseOfferingSearchCriteria {
  const AcademicCourseOfferingSearchCriteria({
    this.termName,
    this.courseCode,
    this.courseName,
    this.teacher,
    this.department,
  });

  /// 学期名称。
  final String? termName;

  /// 课程代码。
  final String? courseCode;

  /// 课程名称。
  final String? courseName;

  /// 教师名称。
  final String? teacher;

  /// 开课院系。
  final String? department;

  /// 从 JSON 恢复开课检索条件。
  factory AcademicCourseOfferingSearchCriteria.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicCourseOfferingSearchCriteria(
      termName: json['termName'] as String?,
      courseCode: json['courseCode'] as String?,
      courseName: json['courseName'] as String?,
      teacher: json['teacher'] as String?,
      department: json['department'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'termName': termName,
      'courseCode': courseCode,
      'courseName': courseName,
      'teacher': teacher,
      'department': department,
    };
  }
}

/// 单条开课记录。
class AcademicCourseOfferingRecord {
  const AcademicCourseOfferingRecord({
    required this.courseName,
    required this.rawCells,
    this.courseCode,
    this.teacher,
    this.credit,
    this.capacity,
    this.department,
    this.scheduleText,
    this.locationText,
    this.termName,
  });

  /// 课程名称。
  final String courseName;

  /// 课程代码。
  final String? courseCode;

  /// 教师名称。
  final String? teacher;

  /// 学分。
  final double? credit;

  /// 容量。
  final int? capacity;

  /// 开课院系。
  final String? department;

  /// 时间文本。
  final String? scheduleText;

  /// 地点文本。
  final String? locationText;

  /// 学期名称。
  final String? termName;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 从 JSON 恢复开课记录。
  factory AcademicCourseOfferingRecord.fromJson(Map<String, dynamic> json) {
    return AcademicCourseOfferingRecord(
      courseName: json['courseName'] as String? ?? '',
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      courseCode: json['courseCode'] as String?,
      teacher: json['teacher'] as String?,
      credit: (json['credit'] as num?)?.toDouble(),
      capacity: (json['capacity'] as num?)?.toInt(),
      department: json['department'] as String?,
      scheduleText: json['scheduleText'] as String?,
      locationText: json['locationText'] as String?,
      termName: json['termName'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'rawCells': rawCells,
      'courseCode': courseCode,
      'teacher': teacher,
      'credit': credit,
      'capacity': capacity,
      'department': department,
      'scheduleText': scheduleText,
      'locationText': locationText,
      'termName': termName,
    };
  }
}

/// 开课检索结果。
class AcademicCourseOfferingSearchResult {
  const AcademicCourseOfferingSearchResult({
    required this.criteria,
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
  });

  /// 本次只读搜索条件。
  final AcademicCourseOfferingSearchCriteria criteria;

  /// 命中的开课记录。
  final List<AcademicCourseOfferingRecord> records;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 来源页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复开课检索结果。
  factory AcademicCourseOfferingSearchResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicCourseOfferingSearchResult(
      criteria: AcademicCourseOfferingSearchCriteria.fromJson(
        json['criteria'] as Map<String, dynamic>? ?? const {},
      ),
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicCourseOfferingRecord.fromJson)
          .toList(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceUri: Uri.parse(json['sourceUri'] as String? ?? ''),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'criteria': criteria.toJson(),
      'records': records.map((record) => record.toJson()).toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
    };
  }
}
