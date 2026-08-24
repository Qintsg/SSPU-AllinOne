/*
 * 本专科教务过程化成绩模型 — 按学期的平时成绩明细
 * @Project : SSPU-AllinOne
 * @File : grade_process.dart
 * @Author : Qintsg
 * @Date : 2026-06-15
 */

import 'exams.dart' show AcademicEamsSemesterOption;

/// 单个平时成绩项（值/占比/描述）。
class AcademicGradeProcessItem {
  const AcademicGradeProcessItem({required this.label, required this.value});

  /// 项目名称，例如 平时成绩Ⅰ。
  final String label;

  /// 原始展示文本，例如 95.0/10%。
  final String value;

  /// 从 JSON 恢复。
  factory AcademicGradeProcessItem.fromJson(Map<String, dynamic> json) {
    return AcademicGradeProcessItem(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

/// 单门课程的过程化成绩记录。
class AcademicGradeProcessRecord {
  const AcademicGradeProcessRecord({
    required this.courseName,
    required this.items,
    required this.rawCells,
    this.courseCode,
    this.courseSequence,
    this.category,
    this.termName,
    this.credit,
  });

  /// 课程名称。
  final String courseName;

  /// 课程代码。
  final String? courseCode;

  /// 课程序号。
  final String? courseSequence;

  /// 课程类别。
  final String? category;

  /// 学年学期。
  final String? termName;

  /// 学分。
  final double? credit;

  /// 非占位的平时成绩项。
  final List<AcademicGradeProcessItem> items;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 是否存在可展示的平时成绩。
  bool get hasProcessItems => items.isNotEmpty;

  /// 从 JSON 恢复。
  factory AcademicGradeProcessRecord.fromJson(Map<String, dynamic> json) {
    return AcademicGradeProcessRecord(
      courseName: json['courseName'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicGradeProcessItem.fromJson)
          .toList(),
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      courseCode: json['courseCode'] as String?,
      courseSequence: json['courseSequence'] as String?,
      category: json['category'] as String?,
      termName: json['termName'] as String?,
      credit: (json['credit'] as num?)?.toDouble(),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'items': items.map((item) => item.toJson()).toList(),
      'rawCells': rawCells,
      'courseCode': courseCode,
      'courseSequence': courseSequence,
      'category': category,
      'termName': termName,
      'credit': credit,
    };
  }
}

/// 过程化成绩查询快照。
class AcademicGradeProcessSnapshot {
  const AcademicGradeProcessSnapshot({
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
    this.selectedSemester,
    this.semesterOptions = const [],
  });

  /// 仅含有平时成绩的课程记录。
  final List<AcademicGradeProcessRecord> records;

  /// 本次查询使用的 EAMS 学期。
  final AcademicEamsSemesterOption? selectedSemester;

  /// EAMS 可选学期列表。
  final List<AcademicEamsSemesterOption> semesterOptions;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 来源页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复。
  factory AcademicGradeProcessSnapshot.fromJson(Map<String, dynamic> json) {
    final selectedSemesterJson = json['selectedSemester'];
    return AcademicGradeProcessSnapshot(
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicGradeProcessRecord.fromJson)
          .toList(),
      selectedSemester: selectedSemesterJson is Map<String, dynamic>
          ? AcademicEamsSemesterOption.fromJson(selectedSemesterJson)
          : null,
      semesterOptions: (json['semesterOptions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicEamsSemesterOption.fromJson)
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
      'selectedSemester': selectedSemester?.toJson(),
      'semesterOptions': semesterOptions
          .map((semester) => semester.toJson())
          .toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
    };
  }
}
