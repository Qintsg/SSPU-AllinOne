/*
 * 清源视觉 surface 清单 — 教务与学业详情
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_surfaces_academic.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

final _academicSurfaces = <_VisualSurface>[
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.initial),
    state: 'initial',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.loading),
    state: 'loading',
    prepare: _prepareAcademicOverviewLoading,
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.content),
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.empty),
    state: 'empty',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.stale),
    state: 'stale',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.error),
    state: 'error',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.partialError),
    state: 'partial-error',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.credentialsRequired),
    state: 'credentials-required',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.credentialsPartial),
    state: 'credentials-partial',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.operationLocked),
    state: 'operation-locked',
    prepare: _prepareAcademicOverviewOperationLocked,
    destination: '教务',
  ),
  _VisualSurface(
    'academic.grade-detail',
    _academicGradeDetailLoading,
    state: 'loading',
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicGradeContentResult),
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicGradeEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicGradeStaleResult),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicDetailErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.grade-detail',
    _academicGradeDetailOperationLocked,
    state: 'operation-locked',
    prepare: _prepareAcademicGradeDetailOperationLocked,
  ),
  _VisualSurface(
    'academic.exam-detail',
    _academicExamDetailLoading,
    state: 'loading',
    prepare: _prepareAcademicExamLoading,
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicExamContentResult),
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicExamEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicExamStaleResult),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicDetailErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.exam-detail',
    _academicExamDetailOperationLocked,
    state: 'operation-locked',
    prepare: _prepareAcademicExamDetailOperationLocked,
  ),
  _VisualSurface(
    'academic.grade-process',
    _academicGradeProcessLoading,
    state: 'loading',
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicGradeProcessContentResult),
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicGradeProcessEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicGradeProcessStaleResult),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicDetailErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.grade-process',
    _academicGradeProcessOperationLocked,
    state: 'operation-locked',
    prepare: _prepareAcademicGradeProcessOperationLocked,
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanHomeStudentReportResult,
      isLoading: true,
    ),
    state: 'loading',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanHomeStudentReportResult,
      onRefresh: () async => qingyuanHomeStudentReportResult,
    ),
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanAcademicStudentReportEmptyResult,
      onRefresh: () async => qingyuanAcademicStudentReportEmptyResult,
    ),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanAcademicStudentReportStaleResult,
      onRefresh: () async => qingyuanAcademicStudentReportStaleResult,
    ),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanAcademicStudentReportErrorResult,
      onRefresh: () async => qingyuanAcademicStudentReportErrorResult,
    ),
    state: 'error',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanHomeStudentReportResult,
      onRefresh: () => Completer<StudentReportQueryResult>().future,
    ),
    state: 'operation-locked',
    prepare: _startStudentReportDetailRefresh,
  ),
  _VisualSurface(
    'academic.student-report-rules',
    () => StudentReportRulesPage(
      summary: qingyuanAcademicStudentReportContentSummary,
    ),
  ),
  _VisualSurface(
    'academic.student-report-rules',
    () => StudentReportRulesPage(
      summary: qingyuanAcademicStudentReportEmptyResult.summary!,
    ),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(
      result: qingyuanHomeSportsResult,
      isLoading: true,
    ),
    state: 'loading',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(
      result: qingyuanHomeSportsResult,
      onRefresh: () async => qingyuanHomeSportsResult,
    ),
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(
      result: qingyuanAcademicSportsEmptyResult,
      onRefresh: () async => qingyuanAcademicSportsEmptyResult,
    ),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(
      result: qingyuanAcademicSportsStaleResult,
      onRefresh: () async => qingyuanAcademicSportsStaleResult,
    ),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(
      result: qingyuanAcademicSportsErrorResult,
      onRefresh: () async => qingyuanAcademicSportsErrorResult,
    ),
    state: 'error',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(
      result: qingyuanHomeSportsResult,
      onRefresh: () => Completer<SportsAttendanceQueryResult>().future,
    ),
    state: 'operation-locked',
    prepare: _startSportsAttendanceDetailRefresh,
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarLoading,
    state: 'loading',
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarContent,
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
  _VisualSurface('academic.calendar', _academicCalendarEmpty, state: 'empty'),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarStale,
    state: 'stale',
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
  _VisualSurface('academic.calendar', _academicCalendarError, state: 'error'),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarPartialError,
    state: 'partial-error',
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarOperationLocked,
    state: 'operation-locked',
    prepare: _startAcademicCalendarRefresh,
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarExternalConfirmation,
    state: 'external-confirmation',
    prepare: _showAcademicCalendarExternalConfirmation,
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarExternalError,
    state: 'external-error',
    prepare: _failAcademicCalendarExternalOpen,
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
];
