/* 清源视觉验收脱敏 fixture — 固定时钟与确定性业务状态。 */

import 'dart:async';

import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';

/// 视觉矩阵的固定本地时钟。
final DateTime qingyuanVisualNow = DateTime(2026, 7, 18, 9, 30);

final Uri _entranceUri = Uri.parse(
  'https://oa.example.invalid/interface/Entrance.jsp?id=academic',
);
final Uri _sourceUri = Uri.parse(
  'https://academic.example.invalid/course-table',
);

/// 课表正常内容 fixture。
final AcademicEamsQueryResult qingyuanScheduleContentResult = _scheduleResult(
  checkedAt: qingyuanVisualNow,
  entries: const [
    AcademicCourseTableEntry(
      courseName: '数据结构',
      weekday: 1,
      startUnit: 1,
      endUnit: 2,
      timeText: '周一 第1-2节',
      teacher: '陈老师',
      location: '计算机楼 301',
      weekDescription: '1-16周',
      rawText: '数据结构 陈老师 计算机楼 301 1-16周',
    ),
    AcademicCourseTableEntry(
      courseName: '人机交互设计',
      weekday: 3,
      startUnit: 5,
      endUnit: 6,
      timeText: '周三 第5-6节',
      teacher: '林老师',
      location: '艺术楼 B204',
      weekDescription: '2-15周',
      rawText: '人机交互设计 林老师 艺术楼 B204 2-15周',
    ),
    AcademicCourseTableEntry(
      courseName: '软件工程实践',
      weekday: 6,
      startUnit: 3,
      endUnit: 4,
      timeText: '周六 第3-4节',
      teacher: '周老师',
      location: '实训中心 405',
      weekDescription: '1-8周',
      rawText: '软件工程实践 周老师 实训中心 405 1-8周',
    ),
  ],
);

/// 课表空数据 fixture。
final AcademicEamsQueryResult qingyuanScheduleEmptyResult = _scheduleResult(
  checkedAt: qingyuanVisualNow,
  entries: const [],
);

/// 课表过期缓存 fixture。
final AcademicEamsQueryResult qingyuanScheduleStaleResult = _scheduleResult(
  checkedAt: DateTime(2026, 7, 17, 18, 0),
  entries: qingyuanScheduleContentResult.snapshot!.courseTable!.entries,
  status: AcademicEamsQueryStatus.partialSuccess,
  warnings: const ['当前展示为昨日缓存，实时刷新暂不可用'],
);

/// 课表失败 fixture。
final AcademicEamsQueryResult qingyuanScheduleErrorResult =
    AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.networkError,
      message: '暂时无法读取课表',
      detail: '请检查校园网络或 VPN 后重试，已保留本地数据。',
      checkedAt: qingyuanVisualNow,
      entranceUri: _entranceUri,
    );

AcademicEamsQueryResult _scheduleResult({
  required DateTime checkedAt,
  required List<AcademicCourseTableEntry> entries,
  AcademicEamsQueryStatus status = AcademicEamsQueryStatus.success,
  List<String> warnings = const [],
}) {
  return AcademicEamsQueryResult(
    status: status,
    message: status == AcademicEamsQueryStatus.success ? '课表已同步' : '正在显示缓存课表',
    detail: '已读取当前学期课表。',
    checkedAt: checkedAt,
    entranceUri: _entranceUri,
    snapshot: AcademicEamsSnapshot(
      fetchedAt: checkedAt,
      sourceUri: _sourceUri,
      warnings: warnings,
      hasCourseOfferingEntry: true,
      hasFreeClassroomEntry: true,
      profile: const AcademicEamsProfile(
        name: '清源同学',
        studentId: '20260001',
        department: '计算机与信息工程学院',
        major: '软件工程',
        className: '软件 241',
        gender: '不展示',
        studyLength: '4 年',
        educationLevel: '本科',
        rawFields: {},
      ),
      courseTable: AcademicCourseTableSnapshot(
        termName: '2025-2026 第2学期',
        entries: entries,
        fetchedAt: checkedAt,
        sourceUri: _sourceUri,
      ),
    ),
  );
}

/// 视觉测试使用的无网络 EAMS 客户端。
class QingyuanVisualAcademicEamsClient implements AcademicEamsClient {
  QingyuanVisualAcademicEamsClient({
    required this.result,
    this.cachedResult,
    this.pendingCourseTable,
  });

  final AcademicEamsQueryResult result;
  final AcademicEamsQueryResult? cachedResult;
  final Completer<AcademicEamsQueryResult>? pendingCourseTable;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedCourseTable() async {
    return cachedResult;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedOverview() async => null;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedExamSchedule() async => null;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGrades() async => null;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGradeProcess() async => null;

  @override
  Future<AcademicEamsProfile?> readCachedStudentProfile() async => null;

  @override
  Future<AcademicEamsProfile?> refreshStudentProfileIfIncomplete({
    bool forceRefresh = false,
  }) async => result.snapshot?.profile;

  @override
  Future<AcademicEamsQueryResult> fetchCourseTable({
    bool requireCampusNetwork = true,
  }) {
    return pendingCourseTable?.future ?? Future.value(result);
  }

  @override
  Future<AcademicEamsQueryResult> fetchOverview({
    bool requireCampusNetwork = true,
  }) async => result;

  @override
  Future<AcademicEamsQueryResult> fetchExamSchedule({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    String? examTypeId,
    bool requireCampusNetwork = true,
  }) async => result;

  @override
  Future<AcademicEamsQueryResult> fetchGrades({
    bool requireCampusNetwork = true,
  }) async => result;

  @override
  Future<AcademicEamsQueryResult> fetchGradeProcess({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    bool requireCampusNetwork = true,
  }) async => result;
}
