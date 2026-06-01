/*
 * 本专科教务系统培养计划模型
 * @Project : SSPU-AllinOne
 * @File : program_plan.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

/// 培养计划中的单门课程。
class AcademicProgramPlanCourse {
  const AcademicProgramPlanCourse({
    required this.courseName,
    required this.rawCells,
    this.courseCode,
    this.credit,
    this.moduleName,
    this.category,
    this.suggestedTerm,
  });

  /// 课程名称。
  final String courseName;

  /// 课程代码。
  final String? courseCode;

  /// 学分。
  final double? credit;

  /// 模块名称。
  final String? moduleName;

  /// 类别或课程性质。
  final String? category;

  /// 建议修读学期。
  final String? suggestedTerm;

  /// 原始单元格文本。
  final List<String> rawCells;

  /// 从 JSON 恢复培养计划课程。
  factory AcademicProgramPlanCourse.fromJson(Map<String, dynamic> json) {
    return AcademicProgramPlanCourse(
      courseName: json['courseName'] as String? ?? '',
      rawCells: (json['rawCells'] as List<dynamic>? ?? const []).cast<String>(),
      courseCode: json['courseCode'] as String?,
      credit: (json['credit'] as num?)?.toDouble(),
      moduleName: json['moduleName'] as String?,
      category: json['category'] as String?,
      suggestedTerm: json['suggestedTerm'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'rawCells': rawCells,
      'courseCode': courseCode,
      'credit': credit,
      'moduleName': moduleName,
      'category': category,
      'suggestedTerm': suggestedTerm,
    };
  }
}

/// 培养计划快照。
class AcademicProgramPlanSnapshot {
  const AcademicProgramPlanSnapshot({
    required this.courses,
    required this.fetchedAt,
    required this.sourceUri,
    this.planName,
  });

  /// 培养计划名称。
  final String? planName;

  /// 培养计划课程列表。
  final List<AcademicProgramPlanCourse> courses;

  /// 解析完成时间。
  final DateTime fetchedAt;

  /// 来源页面地址。
  final Uri sourceUri;

  /// 从 JSON 恢复培养计划快照。
  factory AcademicProgramPlanSnapshot.fromJson(Map<String, dynamic> json) {
    return AcademicProgramPlanSnapshot(
      courses: (json['courses'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicProgramPlanCourse.fromJson)
          .toList(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceUri: Uri.parse(json['sourceUri'] as String? ?? ''),
      planName: json['planName'] as String?,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'courses': courses.map((course) => course.toJson()).toList(),
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
      'planName': planName,
    };
  }
}

/// 单个培养计划模块的完成进度。
class AcademicProgramModuleProgress {
  const AcademicProgramModuleProgress({
    required this.moduleName,
    required this.totalCourseCount,
    required this.completedCourseCount,
    required this.pendingCourseCount,
    required this.totalCredits,
    required this.completedCredits,
    required this.pendingCredits,
  });

  /// 模块名称。
  final String moduleName;

  /// 模块总课程数。
  final int totalCourseCount;

  /// 模块已完成课程数。
  final int completedCourseCount;

  /// 模块待完成课程数。
  final int pendingCourseCount;

  /// 模块总学分。
  final double totalCredits;

  /// 模块已修学分。
  final double completedCredits;

  /// 模块未修学分。
  final double pendingCredits;

  /// 从 JSON 恢复模块完成进度。
  factory AcademicProgramModuleProgress.fromJson(Map<String, dynamic> json) {
    return AcademicProgramModuleProgress(
      moduleName: json['moduleName'] as String? ?? '',
      totalCourseCount: (json['totalCourseCount'] as num?)?.toInt() ?? 0,
      completedCourseCount:
          (json['completedCourseCount'] as num?)?.toInt() ?? 0,
      pendingCourseCount: (json['pendingCourseCount'] as num?)?.toInt() ?? 0,
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0,
      completedCredits: (json['completedCredits'] as num?)?.toDouble() ?? 0,
      pendingCredits: (json['pendingCredits'] as num?)?.toDouble() ?? 0,
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'moduleName': moduleName,
      'totalCourseCount': totalCourseCount,
      'completedCourseCount': completedCourseCount,
      'pendingCourseCount': pendingCourseCount,
      'totalCredits': totalCredits,
      'completedCredits': completedCredits,
      'pendingCredits': pendingCredits,
    };
  }
}

/// 培养计划完成情况快照。
class AcademicProgramCompletionSnapshot {
  const AcademicProgramCompletionSnapshot({
    required this.completedCourseCount,
    required this.pendingCourseCount,
    required this.completedCredits,
    required this.pendingCredits,
    required this.moduleProgress,
  });

  /// 已完成课程数。
  final int completedCourseCount;

  /// 未完成课程数。
  final int pendingCourseCount;

  /// 已修学分。
  final double completedCredits;

  /// 未修学分。
  final double pendingCredits;

  /// 按模块聚合的完成进度。
  final List<AcademicProgramModuleProgress> moduleProgress;

  /// 从 JSON 恢复培养计划完成情况。
  factory AcademicProgramCompletionSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return AcademicProgramCompletionSnapshot(
      completedCourseCount:
          (json['completedCourseCount'] as num?)?.toInt() ?? 0,
      pendingCourseCount: (json['pendingCourseCount'] as num?)?.toInt() ?? 0,
      completedCredits: (json['completedCredits'] as num?)?.toDouble() ?? 0,
      pendingCredits: (json['pendingCredits'] as num?)?.toDouble() ?? 0,
      moduleProgress: (json['moduleProgress'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AcademicProgramModuleProgress.fromJson)
          .toList(),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'completedCourseCount': completedCourseCount,
      'pendingCourseCount': pendingCourseCount,
      'completedCredits': completedCredits,
      'pendingCredits': pendingCredits,
      'moduleProgress': moduleProgress
          .map((progress) => progress.toJson())
          .toList(),
    };
  }
}
