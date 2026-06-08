/*
 * 本专科教务系统空闲教室模型
 * @Project : SSPU-AllinOne
 * @File : free_classrooms.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

/// 空闲教室查询条件。
class AcademicFreeClassroomSearchCriteria {
  const AcademicFreeClassroomSearchCriteria({
    this.campus,
    this.building,
    this.dateText,
    this.lessonFrom,
    this.lessonTo,
  });

  /// 校区。
  final String? campus;

  /// 楼宇。
  final String? building;

  /// 查询日期原始文本。
  final String? dateText;

  /// 起始节次。
  final int? lessonFrom;

  /// 结束节次。
  final int? lessonTo;

  /// 从 JSON 恢复空闲教室查询条件。
  factory AcademicFreeClassroomSearchCriteria.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicFreeClassroomSearchCriteria(
      campus: json['campus'] as String?,
      building: json['building'] as String?,
      dateText: json['dateText'] as String?,
      lessonFrom: (json['lessonFrom'] as num?)?.toInt(),
      lessonTo: (json['lessonTo'] as num?)?.toInt(),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'campus': campus,
      'building': building,
      'dateText': dateText,
      'lessonFrom': lessonFrom,
      'lessonTo': lessonTo,
    };
  }
}

/// 单条空闲教室记录。
class AcademicFreeClassroomRecord {
  const AcademicFreeClassroomRecord({
    required this.roomName,
    required this.rawCells,
    this.campus,
    this.building,
    this.location,
    this.capacity,
    this.dateText,
    this.lessonText,
  });

  /// 教室名称。
  final String roomName;

  /// 校区。
  final String? campus;

  /// 楼宇。
  final String? building;

  /// 位置说明。
  final String? location;

  /// 容量。
  final int? capacity;

  /// 日期文本。
  final String? dateText;

  /// 节次文本。
  final String? lessonText;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 从 JSON 恢复空闲教室记录。
  factory AcademicFreeClassroomRecord.fromJson(Map<String, dynamic> json) {
    return AcademicFreeClassroomRecord(
      roomName: json['roomName'] as String? ?? '',
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      campus: json['campus'] as String?,
      building: json['building'] as String?,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      dateText: json['dateText'] as String?,
      lessonText: json['lessonText'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'roomName': roomName,
      'rawCells': rawCells,
      'campus': campus,
      'building': building,
      'location': location,
      'capacity': capacity,
      'dateText': dateText,
      'lessonText': lessonText,
    };
  }
}

/// 空闲教室查询结果。
class AcademicFreeClassroomSearchResult {
  const AcademicFreeClassroomSearchResult({
    required this.criteria,
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
  });

  /// 本次查询条件。
  final AcademicFreeClassroomSearchCriteria criteria;

  /// 命中的空闲教室记录。
  final List<AcademicFreeClassroomRecord> records;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 来源页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复空闲教室查询结果。
  factory AcademicFreeClassroomSearchResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicFreeClassroomSearchResult(
      criteria: AcademicFreeClassroomSearchCriteria.fromJson(
        json['criteria'] as Map<String, dynamic>? ?? const {},
      ),
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicFreeClassroomRecord.fromJson)
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
