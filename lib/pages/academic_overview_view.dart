/*
 * 教务总览状态 — 负责将既有数据源映射为展示状态
 * @Project : SSPU-AllinOne
 * @File : academic_overview_view.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

enum AcademicOverviewDisplayState {
  initial,
  loading,
  content,
  empty,
  stale,
  error,
  partialError,
  credentialsRequired,
  operationLocked,
}

extension _AcademicOverviewStateView on _AcademicPageState {
  Widget _buildAcademicOverview(BuildContext context) {
    final state = _academicOverviewDisplayState;
    final failedSources = _academicOverviewEffectiveFailedSources;
    final grades = _academicGradeResult?.snapshot?.grades;
    final profile = _academicEamsResult?.snapshot?.profile;
    final exams = _academicExamResult?.snapshot?.exams?.records ?? const [];
    AcademicExamRecord? nextExam;
    for (final exam in exams) {
      if (exam.hasScheduledExamDate) {
        nextExam = exam;
        break;
      }
    }

    return _AcademicOverviewPage(
      state: state,
      termLabel:
          this._academicExamSelectedTerm?.label ??
          this._academicExamSelectedSemester?.termChoice?.label ??
          '当前学期',
      profile: profile,
      gpa: grades?.weightedGpaForTerm(null),
      earnedCredits: grades?.earnedCreditsForTerm(null),
      gradeCount: grades?.allRecords.length,
      nextExam: nextExam,
      failedSources: failedSources,
      failedSourcesWithoutFallback: failedSources
          .where((source) => !_academicSourceHasFallbackData(source))
          .toSet(),
      hasContent: _academicOverviewHasContent,
      credentialsIncomplete: _academicOverviewHasMissingCredentials,
      oaStatusLabel: _academicOverviewOaStatusLabel,
      oaStatusKind: _academicOverviewOaStatusKind,
      refreshSourceCount: _academicAvailableRefreshSourceCount,
      staleCheckedAt: _academicOverviewLatestCheckedAt,
      backgroundRefreshing:
          _anyAcademicSourceLoading &&
          !_isCoordinatedRefresh &&
          _academicOverviewHasContent,
      onRefresh:
          _isCoordinatedRefresh ||
              _anyAcademicSourceLoading ||
              (_credentialsStatus != null &&
                  _academicAvailableRefreshSourceCount == 0)
          ? null
          : () => unawaited(_refreshAllAcademicSources()),
      onOpenSchedule: _openCourseSchedule,
      onOpenAccountConnections: widget.onOpenAccountConnections,
      onAdjustAcademicTerm: widget.onAdjustAcademicTerm,
      legacyDetails: _AcademicLegacySources(
        locked: _isCoordinatedRefresh,
        sports: AcademicSportsAttendanceCard(
          result: _sportsAttendanceResult,
          isLoading: _sportsAttendanceRefreshController.isLoading,
          autoRefreshEnabled:
              _sportsAttendanceRefreshController.autoRefreshEnabled,
          onDetailRefresh: () async =>
              (await _sportsAttendanceRefreshController.runRefresh())?.result,
        ),
        secondClassroom: AcademicStudentReportCard(
          result: _studentReportResult,
          isLoading: _studentReportRefreshController.isLoading,
          autoRefreshEnabled:
              _studentReportRefreshController.autoRefreshEnabled,
          onDetailRefresh: () async =>
              (await _studentReportRefreshController.runRefresh())?.result,
        ),
      ),
    );
  }

  AcademicOverviewDisplayState get _academicOverviewDisplayState {
    if (_isCoordinatedRefresh) {
      return AcademicOverviewDisplayState.operationLocked;
    }
    final hasContent = _academicOverviewHasContent;
    if (_academicAvailableRefreshSourceCount == 0 &&
        _credentialsStatus != null &&
        !hasContent) {
      return AcademicOverviewDisplayState.credentialsRequired;
    }
    if (_anyAcademicSourceLoading && !hasContent) {
      return AcademicOverviewDisplayState.loading;
    }
    if (!hasContent &&
        (_failedAcademicSources.isNotEmpty || _academicOverviewHasHardError)) {
      return AcademicOverviewDisplayState.error;
    }
    if (!hasContent && !_academicOverviewHasAnyResult) {
      return AcademicOverviewDisplayState.initial;
    }
    if (_academicOverviewIsStale && hasContent) {
      return AcademicOverviewDisplayState.stale;
    }
    if ((_failedAcademicSources.isNotEmpty || _academicOverviewHasHardError) &&
        hasContent) {
      return AcademicOverviewDisplayState.partialError;
    }
    if (!hasContent && _academicOverviewHasAnyResult) {
      return AcademicOverviewDisplayState.empty;
    }
    return AcademicOverviewDisplayState.content;
  }

  bool get _academicOverviewHasContent =>
      _academicEamsResult?.snapshot?.hasAnyData == true ||
      (_academicGradeResult?.snapshot?.grades?.allRecords.isNotEmpty ??
          false) ||
      (_academicExamResult?.snapshot?.exams?.records.isNotEmpty ?? false) ||
      (_sportsAttendanceResult?.summary?.totalCount ?? 0) > 0 ||
      (_sportsAttendanceResult?.summary?.records.isNotEmpty ?? false) ||
      _studentReportHasContent;

  bool get _studentReportHasContent {
    final summary = _studentReportResult?.summary;
    if (summary == null) return false;
    final totals = summary.totals;
    return summary.records.isNotEmpty ||
        summary.rules.isNotEmpty ||
        summary.detailRecords.isNotEmpty ||
        (totals?.totalCredit ?? 0) > 0 ||
        (totals?.totalEarnedCredit ?? 0) > 0 ||
        (totals?.totalRequiredCredit ?? 0) > 0 ||
        (totals?.passStatus?.trim().isNotEmpty ?? false);
  }

  bool get _academicOverviewHasAnyResult =>
      _academicEamsResult != null ||
      _academicGradeResult != null ||
      _academicExamResult != null ||
      _sportsAttendanceResult != null ||
      _studentReportResult != null;

  bool get _academicOverviewHasMissingCredentials {
    if (_credentialsStatus == null) return false;
    bool missing(AcademicEamsQueryResult? result) =>
        result?.status == AcademicEamsQueryStatus.missingOaAccount ||
        result?.status == AcademicEamsQueryStatus.missingOaPassword;
    return !_academicOaCredentialsReady ||
        !_academicSportsCredentialsReady ||
        missing(_academicEamsResult) ||
        missing(_academicGradeResult) ||
        missing(_academicExamResult);
  }

  String get _academicOverviewOaStatusLabel {
    if (_credentialsStatus == null) return 'OA 状态读取中';
    if (!_academicOaCredentialsReady) return 'OA 凭据待补充';
    final oaResults = [
      _academicEamsResult,
      _academicGradeResult,
      _academicExamResult,
    ];
    final hasPartialOaData = oaResults.any(
      (result) => result?.status == AcademicEamsQueryStatus.partialSuccess,
    );
    if (hasPartialOaData) return 'OA 数据部分读取';
    final hasFreshOaData = oaResults.any(
      (result) => result?.status == AcademicEamsQueryStatus.success,
    );
    return hasFreshOaData ? 'OA 数据已读取' : 'OA 状态未校验';
  }

  YhStatusKind get _academicOverviewOaStatusKind {
    if (!_academicOaCredentialsReady) return YhStatusKind.warning;
    return switch (_academicOverviewOaStatusLabel) {
      'OA 数据已读取' => YhStatusKind.success,
      'OA 数据部分读取' => YhStatusKind.warning,
      _ => YhStatusKind.neutral,
    };
  }

  DateTime? get _academicOverviewLatestCheckedAt {
    final values =
        [_academicEamsResult, _academicGradeResult, _academicExamResult]
            .where(
              (result) =>
                  result?.status == AcademicEamsQueryStatus.partialSuccess,
            )
            .map((result) => result?.checkedAt)
            .whereType<DateTime>();
    DateTime? latest;
    for (final value in values) {
      if (latest == null || value.isAfter(latest)) latest = value;
    }
    return latest;
  }

  bool get _academicOverviewIsStale =>
      _academicEamsResult?.status == AcademicEamsQueryStatus.partialSuccess ||
      _academicGradeResult?.status == AcademicEamsQueryStatus.partialSuccess ||
      _academicExamResult?.status == AcademicEamsQueryStatus.partialSuccess;

  bool get _academicOverviewHasHardError {
    bool academicFailed(AcademicEamsQueryResult? result) =>
        result != null &&
        result.status != AcademicEamsQueryStatus.success &&
        result.status != AcademicEamsQueryStatus.partialSuccess;
    return academicFailed(_academicEamsResult) ||
        academicFailed(_academicGradeResult) ||
        academicFailed(_academicExamResult) ||
        (_sportsAttendanceResult != null &&
            !_sportsAttendanceResult!.isSuccess) ||
        (_studentReportResult != null && !_studentReportResult!.isSuccess);
  }

  Set<String> get _academicOverviewEffectiveFailedSources {
    bool academicFailed(AcademicEamsQueryResult? result) =>
        result != null &&
        result.status != AcademicEamsQueryStatus.success &&
        result.status != AcademicEamsQueryStatus.partialSuccess;
    return {
      ..._failedAcademicSources,
      if (academicFailed(_academicEamsResult)) '教务摘要',
      if (academicFailed(_academicExamResult)) '考试',
      if (academicFailed(_academicGradeResult)) '成绩',
      if (_sportsAttendanceResult != null &&
          !_sportsAttendanceResult!.isSuccess)
        '体育考勤',
      if (_studentReportResult != null && !_studentReportResult!.isSuccess)
        '第二课堂',
    };
  }
}
