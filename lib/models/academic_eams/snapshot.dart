/*
 * 本专科教务系统汇总快照模型
 * @Project : SSPU-AllinOne
 * @File : snapshot.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'course_offerings.dart';
import 'course_table.dart';
import 'exams.dart';
import 'free_classrooms.dart';
import 'grade_process.dart';
import 'grades.dart';
import 'profile.dart';
import 'program_plan.dart';

/// 本专科教务系统首页摘要快照。
class AcademicEamsSnapshot {
  const AcademicEamsSnapshot({
    required this.fetchedAt,
    required this.sourceUri,
    required this.warnings,
    required this.hasCourseOfferingEntry,
    required this.hasFreeClassroomEntry,
    this.profile,
    this.courseTable,
    this.grades,
    this.gradeProcess,
    this.programPlan,
    this.programCompletion,
    this.exams,
    this.courseOfferingsPreview,
    this.freeClassroomsPreview,
  });

  /// 汇总解析完成时间。
  final DateTime fetchedAt;

  /// 触发本次读取的业务页面地址。
  final Uri sourceUri;

  /// 页面可读但未完整解析的模块告警。
  final List<String> warnings;

  /// 是否已识别开课检索入口。
  final bool hasCourseOfferingEntry;

  /// 是否已识别空闲教室入口。
  final bool hasFreeClassroomEntry;

  /// 个人基本信息。
  final AcademicEamsProfile? profile;

  /// 当前学期课表。
  final AcademicCourseTableSnapshot? courseTable;

  /// 成绩快照。
  final AcademicGradeSnapshot? grades;

  /// 过程化成绩快照。
  final AcademicGradeProcessSnapshot? gradeProcess;

  /// 培养计划。
  final AcademicProgramPlanSnapshot? programPlan;

  /// 培养计划完成情况。
  final AcademicProgramCompletionSnapshot? programCompletion;

  /// 期末考试安排。
  final AcademicExamSnapshot? exams;

  /// 开课检索预览结果；仅在首页探测出结果表格时返回。
  final AcademicCourseOfferingSearchResult? courseOfferingsPreview;

  /// 空闲教室预览结果；仅在首页探测出结果表格时返回。
  final AcademicFreeClassroomSearchResult? freeClassroomsPreview;

  /// 从 JSON 恢复本专科教务摘要快照。
  factory AcademicEamsSnapshot.fromJson(Map<String, dynamic> json) {
    return AcademicEamsSnapshot(
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceUri: Uri.parse(json['sourceUri'] as String? ?? ''),
      warnings: (json['warnings'] as List<dynamic>? ?? const []).cast<String>(),
      hasCourseOfferingEntry: json['hasCourseOfferingEntry'] as bool? ?? false,
      hasFreeClassroomEntry: json['hasFreeClassroomEntry'] as bool? ?? false,
      profile: _readObject(json['profile'], AcademicEamsProfile.fromJson),
      courseTable: _readObject(
        json['courseTable'],
        AcademicCourseTableSnapshot.fromJson,
      ),
      grades: _readObject(json['grades'], AcademicGradeSnapshot.fromJson),
      gradeProcess: _readObject(
        json['gradeProcess'],
        AcademicGradeProcessSnapshot.fromJson,
      ),
      programPlan: _readObject(
        json['programPlan'],
        AcademicProgramPlanSnapshot.fromJson,
      ),
      programCompletion: _readObject(
        json['programCompletion'],
        AcademicProgramCompletionSnapshot.fromJson,
      ),
      exams: _readObject(json['exams'], AcademicExamSnapshot.fromJson),
      courseOfferingsPreview: _readObject(
        json['courseOfferingsPreview'],
        AcademicCourseOfferingSearchResult.fromJson,
      ),
      freeClassroomsPreview: _readObject(
        json['freeClassroomsPreview'],
        AcademicFreeClassroomSearchResult.fromJson,
      ),
    );
  }

  /// 转换为可持久化 JSON。
  Map<String, dynamic> toJson() {
    return {
      'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      'sourceUri': sourceUri.toString(),
      'warnings': warnings,
      'hasCourseOfferingEntry': hasCourseOfferingEntry,
      'hasFreeClassroomEntry': hasFreeClassroomEntry,
      'profile': profile?.toPublicCacheJson(),
      'courseTable': courseTable?.toJson(),
      'grades': grades?.toJson(),
      'gradeProcess': gradeProcess?.toJson(),
      'programPlan': programPlan?.toJson(),
      'programCompletion': programCompletion?.toJson(),
      'exams': exams?.toJson(),
      'courseOfferingsPreview': courseOfferingsPreview?.toJson(),
      'freeClassroomsPreview': freeClassroomsPreview?.toJson(),
    };
  }

  /// 是否至少解析出一个核心模块。
  bool get hasAnyData {
    return profile?.hasAnyValue == true ||
        (courseTable?.entries.isNotEmpty ?? false) ||
        (grades?.currentTermRecords.isNotEmpty ?? false) ||
        (grades?.historyRecords.isNotEmpty ?? false) ||
        (programPlan?.courses.isNotEmpty ?? false) ||
        (exams?.records.isNotEmpty ?? false) ||
        (courseOfferingsPreview?.records.isNotEmpty ?? false) ||
        (freeClassroomsPreview?.records.isNotEmpty ?? false);
  }
}

T? _readObject<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is Map<String, dynamic>) return fromJson(value);
  return null;
}
