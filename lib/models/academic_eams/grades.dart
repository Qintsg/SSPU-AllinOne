/*
 * 本专科教务系统成绩模型
 * @Project : SSPU-AllinOne
 * @File : grades.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

/// 单条成绩记录。
class AcademicGradeRecord {
  const AcademicGradeRecord({
    required this.courseName,
    required this.scoreText,
    required this.rawCells,
    this.courseCode,
    this.termName,
    this.credit,
    this.gradePoint,
    this.processScoreText,
    this.totalScoreText,
  });

  /// 课程名称。
  final String courseName;

  /// 课程代码。
  final String? courseCode;

  /// 学年学期。
  final String? termName;

  /// 页面原始成绩文本。
  final String scoreText;

  /// 学分。
  final double? credit;

  /// 绩点。
  final double? gradePoint;

  /// 当前学期过程化成绩文本。
  final String? processScoreText;

  /// 当前学期总成绩文本。
  final String? totalScoreText;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 从 JSON 恢复成绩记录。
  factory AcademicGradeRecord.fromJson(Map<String, dynamic> json) {
    return AcademicGradeRecord(
      courseName: json['courseName'] as String? ?? '',
      scoreText: json['scoreText'] as String? ?? '',
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      courseCode: json['courseCode'] as String?,
      termName: json['termName'] as String?,
      credit: (json['credit'] as num?)?.toDouble(),
      gradePoint: (json['gradePoint'] as num?)?.toDouble(),
      processScoreText: json['processScoreText'] as String?,
      totalScoreText: json['totalScoreText'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'scoreText': scoreText,
      'rawCells': rawCells,
      'courseCode': courseCode,
      'termName': termName,
      'credit': credit,
      'gradePoint': gradePoint,
      'processScoreText': processScoreText,
      'totalScoreText': totalScoreText,
    };
  }

  /// 是否可视为通过，用于培养计划完成情况的保守统计。
  bool get isPassed {
    final normalized = scoreText.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized.contains('不及格') || normalized.contains('未通过')) {
      return false;
    }
    if (normalized.contains('通过') || normalized.contains('及格')) return true;
    final numeric = double.tryParse(normalized.replaceAll('%', ''));
    return numeric != null && numeric >= 60;
  }
}

/// 成绩查询快照。
class AcademicGradeSnapshot {
  const AcademicGradeSnapshot({
    required this.currentTermRecords,
    required this.historyRecords,
    required this.fetchedAt,
    required this.sourceUri,
  });

  /// 当前学期成绩记录。
  final List<AcademicGradeRecord> currentTermRecords;

  /// 历史成绩记录。
  final List<AcademicGradeRecord> historyRecords;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 产生该快照的最后页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复成绩快照。
  factory AcademicGradeSnapshot.fromJson(Map<String, dynamic> json) {
    return AcademicGradeSnapshot(
      currentTermRecords:
          (json['currentTermRecords'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AcademicGradeRecord.fromJson)
              .toList(),
      historyRecords: (json['historyRecords'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicGradeRecord.fromJson)
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
      'currentTermRecords': currentTermRecords
          .map((record) => record.toJson())
          .toList(),
      'historyRecords': historyRecords
          .map((record) => record.toJson())
          .toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
    };
  }

  /// 当前学期与历史成绩合并去重后的全部记录。
  ///
  /// 当前学期成绩页与历史成绩页可能返回同一门课，去重键使用
  /// 课程代码（优先）或课程名加学年学期，避免重复计入学分/绩点。
  List<AcademicGradeRecord> get allRecords {
    final merged = <String, AcademicGradeRecord>{};
    for (final record in [...currentTermRecords, ...historyRecords]) {
      merged.putIfAbsent(_recordKey(record), () => record);
    }
    return List.unmodifiable(merged.values);
  }

  /// 去重后出现过的学年学期名，按字典序倒序（最新学期在前）。
  List<String> get availableTerms {
    final terms = <String>{
      for (final record in allRecords)
        if ((record.termName ?? '').trim().isNotEmpty) record.termName!.trim(),
    }.toList()..sort((a, b) => b.compareTo(a));
    return List.unmodifiable(terms);
  }

  /// 最近一个学年学期名；没有学期信息时返回 null。
  String? get latestTermName =>
      availableTerms.isEmpty ? null : availableTerms.first;

  /// 指定学期的成绩；[term] 为 null 或空时返回全部记录。
  ///
  /// :param term: 目标学年学期名，例如 2025-2026-2。
  /// :returns: 该学期的成绩记录列表。
  List<AcademicGradeRecord> recordsForTerm(String? term) {
    final normalized = term?.trim() ?? '';
    if (normalized.isEmpty) return allRecords;
    return List.unmodifiable(
      allRecords.where(
        (record) => (record.termName ?? '').trim() == normalized,
      ),
    );
  }

  /// 指定学期（或全部）可解析学分之和。
  ///
  /// :param term: 目标学年学期名，null 表示统计全部。
  /// :returns: 学分合计，缺少学分的记录按 0 计。
  double creditsForTerm(String? term) {
    return recordsForTerm(
      term,
    ).fold(0, (sum, record) => sum + (record.credit ?? 0));
  }

  /// 指定学期（或全部）的学分加权平均绩点。
  ///
  /// :param term: 目标学年学期名，null 表示统计全部。
  /// :returns: 加权平均绩点；缺少绩点或学分而无法计算时返回 null。
  double? weightedGpaForTerm(String? term) {
    var totalCredit = 0.0;
    var weightedPoint = 0.0;
    for (final record in recordsForTerm(term)) {
      final credit = record.credit;
      final gradePoint = record.gradePoint;
      if (credit == null || gradePoint == null) continue;
      totalCredit += credit;
      weightedPoint += credit * gradePoint;
    }
    if (totalCredit <= 0) return null;
    return weightedPoint / totalCredit;
  }

  /// 按学年学期倒序排列的全部记录；同一学期内保持原始顺序（稳定排序）。
  List<AcademicGradeRecord> get recordsByTermDesc {
    final records = allRecords.toList();
    final originalIndex = <AcademicGradeRecord, int>{
      for (var i = 0; i < records.length; i++) records[i]: i,
    };
    records.sort((a, b) {
      final termCompare = (b.termName ?? '').trim().compareTo(
        (a.termName ?? '').trim(),
      );
      if (termCompare != 0) return termCompare;
      return originalIndex[a]!.compareTo(originalIndex[b]!);
    });
    return List.unmodifiable(records);
  }

  static String _recordKey(AcademicGradeRecord record) {
    final code = (record.courseCode ?? '').trim();
    final identity = code.isNotEmpty ? code : record.courseName.trim();
    return '${(record.termName ?? '').trim()}::$identity';
  }
}
