/*
 * 本专科教务系统考试模型
 * @Project : SSPU-AllinOne
 * @File : exams.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import '../academic_term.dart';

/// 教务系统学期选项。
class AcademicEamsSemesterOption {
  const AcademicEamsSemesterOption({
    required this.id,
    required this.label,
    this.schoolYear,
    this.termCode,
    this.academicYear,
    this.termChoice,
  });

  /// EAMS 内部 semester.id。
  final String id;

  /// 展示名称，例如 2025-2026-2。
  final String label;

  /// EAMS 返回的学年文本。
  final String? schoolYear;

  /// EAMS 返回的学期代码。
  final String? termCode;

  /// 学年起始年份。
  final int? academicYear;

  /// 可映射到全局学期的结构化选择。
  final AcademicTermChoice? termChoice;

  /// 按 EAMS 返回值构造学期选项。
  factory AcademicEamsSemesterOption.fromEamsFields({
    required String id,
    required String schoolYear,
    required String termCode,
  }) {
    final normalizedSchoolYear = schoolYear.replaceAll(RegExp(r'\s+'), '');
    final academicYear = int.tryParse(normalizedSchoolYear.split('-').first);
    final normalizedTermCode = termCode.replaceAll(RegExp(r'\s+'), '');
    final season = _seasonFromEamsTermCode(normalizedTermCode);
    final termChoice = academicYear == null || season == null
        ? null
        : AcademicTermChoice(academicYear: academicYear, season: season);
    return AcademicEamsSemesterOption(
      id: id.trim(),
      label: normalizedSchoolYear.isEmpty
          ? normalizedTermCode
          : '$normalizedSchoolYear-$normalizedTermCode',
      schoolYear: normalizedSchoolYear,
      termCode: normalizedTermCode,
      academicYear: academicYear,
      termChoice: termChoice,
    );
  }

  /// 判断是否对应指定全局学期。
  bool matchesTerm(AcademicTermChoice term) {
    return termChoice == term ||
        academicYear == term.academicYear &&
            _seasonFromEamsTermCode(termCode ?? '') == term.season;
  }

  /// 是否与另一个 EAMS 学期指向同一学年学期。
  bool matchesSchoolTerm({int? academicYear, String? termCode}) {
    final normalizedTermCode = termCode?.trim();
    if (academicYear != null && this.academicYear != academicYear) {
      return false;
    }
    if (normalizedTermCode != null && normalizedTermCode.isNotEmpty) {
      final expectedSeason = _seasonFromEamsTermCode(normalizedTermCode);
      final actualSeason = _seasonFromEamsTermCode(this.termCode ?? '');
      if (expectedSeason != null && actualSeason != null) {
        return expectedSeason == actualSeason;
      }
      if (this.termCode != normalizedTermCode) return false;
    }
    return true;
  }

  /// 从 JSON 恢复教务系统学期选项。
  factory AcademicEamsSemesterOption.fromJson(Map<String, dynamic> json) {
    final termChoiceJson = json['termChoice'];
    return AcademicEamsSemesterOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      schoolYear: json['schoolYear'] as String?,
      termCode: json['termCode'] as String?,
      academicYear: (json['academicYear'] as num?)?.toInt(),
      termChoice: termChoiceJson is Map<String, dynamic>
          ? AcademicTermChoice.fromJson(termChoiceJson)
          : null,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'schoolYear': schoolYear,
      'termCode': termCode,
      'academicYear': academicYear,
      'termChoice': termChoice?.toJson(),
    };
  }
}

/// 单条考试安排。
class AcademicExamRecord {
  const AcademicExamRecord({
    required this.courseName,
    required this.rawCells,
    this.examType,
    this.courseSequence,
    String? examDate,
    this.examArrange,
    String? examLocation,
    String? examSituation,
    this.otherExplanation,
    String? examTime,
    String? location,
    String? status,
    String? seatNumber,
  }) : examDate = examDate ?? examTime,
       examLocation = examLocation ?? location,
       examSituation = examSituation ?? status ?? seatNumber;

  /// 考试类型。
  final String? examType;

  /// 课程序号。
  final String? courseSequence;

  /// 课程名称。
  final String courseName;

  /// 考试日期。
  final String? examDate;

  /// 考试安排。
  final String? examArrange;

  /// 考试地点。
  final String? examLocation;

  /// 考试情况。
  final String? examSituation;

  /// 其它说明。
  final String? otherExplanation;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 兼容旧版考试时间字段。
  String? get examTime => examDate;

  /// 兼容旧版考试地点字段。
  String? get location => examLocation;

  /// 兼容旧版座位号字段。
  String? get seatNumber => examSituation;

  /// 兼容旧版状态字段。
  String? get status => examSituation;

  /// 可展示考试日期；过滤 EAMS 用在日期列中的占位说明。
  String? get displayExamDate {
    return _displayExamField(examDate);
  }

  /// 可展示考试安排。
  String? get displayExamArrange => _displayExamField(examArrange);

  /// 可展示考试地点。
  String? get displayExamLocation => _displayExamField(examLocation);

  /// 可展示考试情况。
  String? get displayExamSituation => _displayExamField(examSituation);

  /// 可展示其它说明。
  String? get displayOtherExplanation => _displayExamField(otherExplanation);

  /// 是否存在可展示考试日期。
  bool get hasExamDate => (displayExamDate ?? '').trim().isNotEmpty;

  /// 是否存在能用于外部卡片预览的具体考试日期。
  bool get hasScheduledExamDate => hasExamDate;

  /// 是否存在可展示的考试安排信息。
  bool get hasDisplayableExamInfo {
    // 仅有课程名而其余字段（含备注）都是 "-"/占位时不展示该考试。
    return hasExamDate ||
        (displayExamArrange ?? '').trim().isNotEmpty ||
        (displayExamLocation ?? '').trim().isNotEmpty ||
        (displayExamSituation ?? '').trim().isNotEmpty ||
        (displayOtherExplanation ?? '').trim().isNotEmpty;
  }

  /// 从 JSON 恢复考试安排。
  factory AcademicExamRecord.fromJson(Map<String, dynamic> json) {
    return AcademicExamRecord(
      courseName: json['courseName'] as String? ?? '',
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      examType: json['examType'] as String?,
      courseSequence: json['courseSequence'] as String?,
      examDate: json['examDate'] as String? ?? json['examTime'] as String?,
      examArrange: json['examArrange'] as String?,
      examLocation:
          json['examLocation'] as String? ?? json['location'] as String?,
      examSituation:
          json['examSituation'] as String? ??
          json['status'] as String? ??
          json['seatNumber'] as String?,
      otherExplanation: json['otherExplanation'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'examType': examType,
      'courseSequence': courseSequence,
      'courseName': courseName,
      'rawCells': rawCells,
      'examDate': examDate,
      'examArrange': examArrange,
      'examLocation': examLocation,
      'examSituation': examSituation,
      'otherExplanation': otherExplanation,
    };
  }
}

/// 考试安排快照。
class AcademicExamSnapshot {
  const AcademicExamSnapshot({
    required this.records,
    required this.fetchedAt,
    required this.sourceUri,
    this.selectedSemester,
    this.semesterOptions = const [],
    this.selectedExamType,
    this.examTypeOptions = const {},
  });

  /// 已解析的考试记录。
  final List<AcademicExamRecord> records;

  /// 本次查询使用的 EAMS 学期。
  final AcademicEamsSemesterOption? selectedSemester;

  /// EAMS 可选学期列表。
  final List<AcademicEamsSemesterOption> semesterOptions;

  /// 本次查询使用的考试类型 id（如期末考试 1）。
  final String? selectedExamType;

  /// EAMS 考试类型选项，键为 examType.id，值为展示名称。
  final Map<String, String> examTypeOptions;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 来源页面地址。
  final Uri sourceUri;

  /// 当前考试类型展示名称。
  String? get selectedExamTypeLabel {
    final type = selectedExamType;
    if (type == null) return null;
    return examTypeOptions[type] ?? type;
  }

  /// 从 JSON 恢复考试安排快照。
  factory AcademicExamSnapshot.fromJson(Map<String, dynamic> json) {
    return AcademicExamSnapshot(
      records: (json['records'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicExamRecord.fromJson)
          .toList(),
      selectedSemester: _readObject(
        json['selectedSemester'],
        AcademicEamsSemesterOption.fromJson,
      ),
      semesterOptions: (json['semesterOptions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicEamsSemesterOption.fromJson)
          .toList(),
      selectedExamType: json['selectedExamType'] as String?,
      examTypeOptions:
          (json['examTypeOptions'] as Map<dynamic, dynamic>? ?? const {})
              .map((key, value) => MapEntry('$key', '$value')),
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
      'selectedExamType': selectedExamType,
      'examTypeOptions': examTypeOptions,
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
    };
  }
}

String? _displayExamField(
  String? value, {
  List<String> additionalPlaceholders = const [],
}) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return text;
  final normalized = text.replaceAll(RegExp(r'\s+'), '');
  final normalizedLower = normalized.toLowerCase();
  final exactPlaceholders = {'-', '--', '—', '－', '尚未发布', '未发布', '暂无', '暂无信息'};
  final containsPlaceholders = {
    '暂无信息',
    '考试情况尚未发布',
    '考试安排尚未发布',
    ...additionalPlaceholders,
  };
  // 英文界面占位（locale 兜底时出现），如 [No examination situation to be deployed.]
  const englishPlaceholders = {'tobedeployed', 'notdeployed', 'noexamination'};
  if (exactPlaceholders.contains(normalized) ||
      containsPlaceholders.any(normalized.contains) ||
      englishPlaceholders.any(normalizedLower.contains)) {
    return '';
  }
  return text;
}

AcademicTermSeason? _seasonFromEamsTermCode(String code) {
  return switch (code.replaceAll(RegExp(r'\s+'), '')) {
    '1' ||
    '一' ||
    '第1学期' ||
    '第一学期' ||
    '秋' ||
    '秋季' ||
    '秋季学期' => AcademicTermSeason.fall,
    '2' ||
    '二' ||
    '第2学期' ||
    '第二学期' ||
    '春' ||
    '春季' ||
    '春季学期' => AcademicTermSeason.spring,
    '3' ||
    '三' ||
    '第3学期' ||
    '第三学期' ||
    '夏' ||
    '夏季' ||
    '夏季学期' => AcademicTermSeason.summer,
    _ => null,
  };
}

T? _readObject<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is Map<String, dynamic>) return fromJson(value);
  return null;
}
