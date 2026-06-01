/*
 * 本专科教务系统考试模型
 * @Project : SSPU-AllinOne
 * @File : exams.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

/// 单条考试安排。
class AcademicExamRecord {
  const AcademicExamRecord({
    required this.courseName,
    required this.rawCells,
    this.examTime,
    this.location,
    this.seatNumber,
    this.status,
  });

  /// 课程名称。
  final String courseName;

  /// 考试时间文本。
  final String? examTime;

  /// 考试地点。
  final String? location;

  /// 座位号。
  final String? seatNumber;

  /// 页面中的状态或备注。
  final String? status;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 从 JSON 恢复考试安排。
  factory AcademicExamRecord.fromJson(Map<String, dynamic> json) {
    return AcademicExamRecord(
      courseName: json['courseName'] as String? ?? '',
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      examTime: json['examTime'] as String?,
      location: json['location'] as String?,
      seatNumber: json['seatNumber'] as String?,
      status: json['status'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'rawCells': rawCells,
      'examTime': examTime,
      'location': location,
      'seatNumber': seatNumber,
      'status': status,
    };
  }
}

/// 考试安排快照。
class AcademicExamSnapshot {
  const AcademicExamSnapshot({
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
  });

  /// 已解析的考试记录。
  final List<AcademicExamRecord> records;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 来源页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复考试安排快照。
  factory AcademicExamSnapshot.fromJson(Map<String, dynamic> json) {
    return AcademicExamSnapshot(
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicExamRecord.fromJson)
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
      'records': records.map((record) => record.toJson()).toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
    };
  }
}
