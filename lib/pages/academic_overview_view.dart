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
    final completion = _academicEamsResult?.snapshot?.programCompletion;
    final totalCredits = completion == null
        ? 0.0
        : completion.completedCredits + completion.pendingCredits;
    final completionValue = totalCredits <= 0
        ? 0.0
        : completion!.completedCredits / totalCredits;
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
      gpa: grades?.weightedGpaForTerm(null),
      earnedCredits: completion?.completedCredits,
      gradeCount: grades?.allRecords.length,
      nextExam: nextExam,
      completionValue: completionValue,
      completedCredits: completion?.completedCredits,
      totalCredits: totalCredits,
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
              _credentialsStatus == null ||
              _academicAvailableRefreshSourceCount == 0
          ? null
          : () => unawaited(_refreshAllAcademicSources()),
      onOpenGrades: _isCoordinatedRefresh ? null : _openAcademicGradeDetail,
      onOpenExams: _isCoordinatedRefresh ? null : _openAcademicExamDetail,
      onOpenSchedule: _isCoordinatedRefresh ? null : _openCourseSchedule,
      onOpenAccountConnections: widget.onOpenAccountConnections,
      onAdjustAcademicTerm: widget.onAdjustAcademicTerm,
      onOpenDetailedSources: _isCoordinatedRefresh
          ? null
          : () => unawaited(_openAcademicLegacySources()),
      legacyDetails: _AcademicLegacySources(
        key: _academicLegacySourcesKey,
        focusNode: _academicLegacySourcesFocusNode,
        locked: _isCoordinatedRefresh,
        primary: AcademicEamsSummaryCard(
          result: _academicEamsResult,
          isLoading: _academicEamsRefreshController.isLoading,
          isRefreshActionLoading:
              _academicEamsRefreshController.isLoading ||
              _academicExamRefreshController.isLoading,
          autoRefreshEnabled: _academicEamsRefreshController.autoRefreshEnabled,
          refreshFeedback: _academicEamsRefreshController.feedback,
          onRefresh: () => unawaited(_loadAcademicEamsOverview()),
          onOpenCourseSchedule: _openCourseSchedule,
          examResult: _academicExamResult,
          examSchedule: AcademicEamsExamCard(
            result: _academicExamResult,
            isLoading: _academicExamRefreshController.isLoading,
            selectedTerm: this._academicExamSelectedTerm,
            onOpenDetail: _openAcademicExamDetail,
          ),
          gradeResult: _academicGradeResult,
          gradeCard: AcademicEamsGradeCard(
            result: _academicGradeResult,
            isLoading: _academicGradeRefreshController.isLoading,
            onOpenDetail: _openAcademicGradeDetail,
          ),
        ),
        sports: AcademicSportsAttendanceCard(
          result: _sportsAttendanceResult,
          isLoading: _sportsAttendanceRefreshController.isLoading,
          autoRefreshEnabled:
              _sportsAttendanceRefreshController.autoRefreshEnabled,
          refreshFeedback: _sportsAttendanceRefreshController.feedback,
          onRefresh: () => unawaited(_loadSportsAttendance()),
        ),
        secondClassroom: AcademicStudentReportCard(
          result: _studentReportResult,
          isLoading: _studentReportRefreshController.isLoading,
          autoRefreshEnabled:
              _studentReportRefreshController.autoRefreshEnabled,
          refreshFeedback: _studentReportRefreshController.feedback,
          onRefresh: () => unawaited(_loadStudentReport()),
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

class _AcademicOverviewPage extends StatelessWidget {
  const _AcademicOverviewPage({
    required this.state,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
    required this.nextExam,
    required this.completionValue,
    required this.completedCredits,
    required this.totalCredits,
    required this.failedSources,
    required this.failedSourcesWithoutFallback,
    required this.hasContent,
    required this.credentialsIncomplete,
    required this.oaStatusLabel,
    required this.oaStatusKind,
    required this.refreshSourceCount,
    required this.staleCheckedAt,
    required this.backgroundRefreshing,
    required this.onRefresh,
    required this.onOpenGrades,
    required this.onOpenExams,
    required this.onOpenSchedule,
    required this.onOpenAccountConnections,
    required this.onAdjustAcademicTerm,
    required this.onOpenDetailedSources,
    required this.legacyDetails,
  });

  final AcademicOverviewDisplayState state;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;
  final AcademicExamRecord? nextExam;
  final double completionValue;
  final double? completedCredits;
  final double totalCredits;
  final Set<String> failedSources;
  final Set<String> failedSourcesWithoutFallback;
  final bool hasContent;
  final bool credentialsIncomplete;
  final String oaStatusLabel;
  final YhStatusKind oaStatusKind;
  final int refreshSourceCount;
  final DateTime? staleCheckedAt;
  final bool backgroundRefreshing;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenGrades;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenSchedule;
  final VoidCallback? onOpenAccountConnections;
  final VoidCallback? onAdjustAcademicTerm;
  final VoidCallback? onOpenDetailedSources;
  final Widget legacyDetails;

  bool get _showsContent =>
      state == AcademicOverviewDisplayState.content ||
      state == AcademicOverviewDisplayState.stale ||
      state == AcademicOverviewDisplayState.partialError ||
      (state == AcademicOverviewDisplayState.operationLocked && hasContent);

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final pagePadding = compact
              ? theme.spacing.m
              : (viewportWidth *
                        theme.responsive.panelPaddingViewportPercent /
                        100)
                    .clamp(theme.spacing.l, theme.spacing.xl2);
          final balancedGrid =
              !compact && viewportWidth < theme.breakpoint.expanded;
          return SingleChildScrollView(
            key: const PageStorageKey('academic-overview-scroll'),
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              compact ? theme.spacing.xl : theme.spacing.xl + theme.spacing.s,
              pagePadding,
              theme.spacing.xl2,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.layout.pageContentWidth,
                  minHeight: constraints.maxHeight - theme.spacing.xl2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AcademicHeading(
                      compact: compact,
                      balanced: balancedGrid,
                      onRefresh: onRefresh,
                    ),
                    if (_showsContent) ...[
                      Wrap(
                        spacing: theme.spacing.s,
                        runSpacing: theme.spacing.s,
                        children: [
                          YhStatusPill(
                            label: oaStatusLabel,
                            kind: oaStatusKind,
                          ),
                          const YhStatusPill(
                            label: '本地快照可用',
                            kind: YhStatusKind.success,
                          ),
                          const YhStatusPill(
                            label: '只读访问',
                            kind: YhStatusKind.info,
                          ),
                          if (backgroundRefreshing)
                            Semantics(
                              liveRegion: true,
                              child: const YhStatusPill(
                                label: '正在更新',
                                kind: YhStatusKind.info,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: theme.spacing.m),
                      if (credentialsIncomplete) ...[
                        YhBanner(
                          kind: YhBannerKind.warn,
                          text: _academicCredentialWarningText(
                            refreshSourceCount,
                          ),
                          action: onOpenAccountConnections == null
                              ? null
                              : YhButton(
                                  label: '连接设置',
                                  variant: YhButtonVariant.secondary,
                                  onTap: onOpenAccountConnections,
                                ),
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      if (state == AcademicOverviewDisplayState.stale) ...[
                        YhBanner(
                          kind: YhBannerKind.warn,
                          text:
                              '当前显示 ${_formatAcademicCheckedAt(staleCheckedAt)} 的本地教务快照；刷新失败不会删除这些内容。',
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      if (state ==
                          AcademicOverviewDisplayState.partialError) ...[
                        YhBanner(
                          kind: YhBannerKind.warn,
                          text: _academicPartialFailureText(
                            failedSources,
                            failedSourcesWithoutFallback,
                          ),
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      if (state ==
                          AcademicOverviewDisplayState.operationLocked) ...[
                        Semantics(
                          liveRegion: true,
                          child: YhBanner(
                            text:
                                '正在协同刷新 $refreshSourceCount 个可用只读来源；完成前已锁定重复刷新和详情导航。',
                          ),
                        ),
                        SizedBox(height: theme.spacing.m),
                      ],
                      _AcademicContentGrid(
                        compact: compact,
                        balanced: balancedGrid,
                        termLabel: termLabel,
                        gpa: gpa,
                        earnedCredits: earnedCredits,
                        gradeCount: gradeCount,
                        nextExam: nextExam,
                        completionValue: completionValue,
                        completedCredits: completedCredits,
                        totalCredits: totalCredits,
                        onOpenGrades: onOpenGrades,
                        onOpenExams: onOpenExams,
                        onOpenSchedule: onOpenSchedule,
                      ),
                    ] else
                      _AcademicStatePanel(
                        state: state,
                        refreshSourceCount: refreshSourceCount,
                        onRefresh: onRefresh,
                        onOpenAccountConnections: onOpenAccountConnections,
                        onAdjustAcademicTerm: onAdjustAcademicTerm,
                      ),
                    SizedBox(height: theme.spacing.xl),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: YhButton(
                        key: const ValueKey(
                          'academic-overview-detailed-sources',
                        ),
                        label: '查看详细数据源',
                        variant: YhButtonVariant.secondary,
                        leadingIcon: YhIcons.info,
                        onTap: onOpenDetailedSources,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xl2 * 4),
                    legacyDetails,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatAcademicCheckedAt(DateTime? value) {
  if (value == null) return '最近一次保存';
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month} 月 ${value.day} 日 ${value.hour}:$minute';
}

String _academicPartialFailureText(
  Set<String> failedSources,
  Set<String> failedSourcesWithoutFallback,
) {
  final retainedSources = failedSources.difference(
    failedSourcesWithoutFallback,
  );
  return '${['${failedSources.join('、')}未完成', if (retainedSources.isNotEmpty) '${retainedSources.join('、')}继续显示最后有效数据', if (failedSourcesWithoutFallback.isNotEmpty) '${failedSourcesWithoutFallback.join('、')}暂无可保留数据', '可在详细数据源中分别重试'].join('；')}。';
}

String _academicCredentialWarningText(int refreshSourceCount) {
  if (refreshSourceCount == 4) {
    return '体育考勤连接未完成；刷新只会访问其余 4 个可用只读来源。';
  }
  if (refreshSourceCount == 1) {
    return 'OA 连接未完成；刷新只会访问体育考勤，成绩、考试与第二课堂保持本地快照。';
  }
  return '部分教务连接未完成；刷新只会访问已配置的只读来源。';
}

class _AcademicHeading extends StatelessWidget {
  const _AcademicHeading({
    required this.compact,
    required this.balanced,
    required this.onRefresh,
  });

  final bool compact;
  final bool balanced;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final copy = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '教务中心',
            style: theme.typography.small.copyWith(
              color: theme.color.brandInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Semantics(
            header: true,
            child: Text(
              '学习进度，一处看全。',
              style: theme.typography.h1.copyWith(
                color: theme.color.foreground,
              ),
            ),
          ),
          SizedBox(height: theme.spacing.s),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: balanced
                  ? theme.control.regular * 9
                  : theme.layout.formContentWidth,
            ),
            child: Text(
              '成绩、考试、培养方案与体育考勤保持只读，原始来源和更新时间始终可见。',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: balanced ? theme.spacing.xl : theme.spacing.l,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copy,
          SizedBox(width: theme.spacing.m),
          if (compact)
            YhIconButton(
              key: const ValueKey('academic-overview-refresh'),
              icon: YhIcons.refresh,
              semanticLabel: '刷新教务数据',
              onTap: onRefresh,
              disabled: onRefresh == null,
            )
          else
            YhButton(
              key: const ValueKey('academic-overview-refresh'),
              label: '刷新教务数据',
              variant: YhButtonVariant.secondary,
              onTap: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _AcademicContentGrid extends StatelessWidget {
  const _AcademicContentGrid({
    required this.compact,
    required this.balanced,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
    required this.nextExam,
    required this.completionValue,
    required this.completedCredits,
    required this.totalCredits,
    required this.onOpenGrades,
    required this.onOpenExams,
    required this.onOpenSchedule,
  });

  final bool compact;
  final bool balanced;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;
  final AcademicExamRecord? nextExam;
  final double completionValue;
  final double? completedCredits;
  final double totalCredits;
  final VoidCallback? onOpenGrades;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final overview = _AcademicOverviewCard(
      compact: compact,
      balanced: balanced,
      termLabel: termLabel,
      gpa: gpa,
      earnedCredits: earnedCredits,
      gradeCount: gradeCount,
    );
    final exam = _AcademicNextExamCard(nextExam: nextExam);
    final archive = _AcademicArchiveCard(
      onOpenGrades: onOpenGrades,
      onOpenExams: onOpenExams,
      onOpenSchedule: onOpenSchedule,
    );
    final completion = _AcademicCompletionCard(
      value: completionValue,
      completedCredits: completedCredits,
      totalCredits: totalCredits,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          overview,
          SizedBox(height: theme.spacing.m),
          exam,
          SizedBox(height: theme.spacing.m),
          archive,
          SizedBox(height: theme.spacing.m),
          completion,
        ],
      );
    }
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: balanced ? 1 : 8, child: overview),
              SizedBox(width: theme.spacing.m),
              Expanded(flex: balanced ? 1 : 4, child: exam),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.m),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: balanced ? 1 : 7, child: archive),
              SizedBox(width: theme.spacing.m),
              Expanded(flex: balanced ? 1 : 5, child: completion),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcademicOverviewCard extends StatelessWidget {
  const _AcademicOverviewCard({
    required this.compact,
    required this.balanced,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
  });

  final bool compact;
  final bool balanced;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final metrics = [
      ('平均绩点', gpa == null ? '—' : gpa!.toStringAsFixed(2)),
      ('已获学分', earnedCredits == null ? '—' : earnedCredits!.toStringAsFixed(1)),
      ('已读成绩', gradeCount == null ? '—' : '$gradeCount 门'),
    ];
    return _AcademicSectionCard(
      title: '本学期概览',
      summary: termLabel,
      child: compact
          ? Column(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _AcademicMetricBox(
                      label: metrics[index].$1,
                      value: metrics[index].$2,
                      balanced: balanced,
                    ),
                  ),
                  if (index != metrics.length - 1)
                    SizedBox(height: theme.spacing.s),
                ],
              ],
            )
          : Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(
                    child: _AcademicMetricBox(
                      label: metrics[index].$1,
                      value: metrics[index].$2,
                      balanced: balanced,
                    ),
                  ),
                  if (index != metrics.length - 1)
                    SizedBox(width: theme.spacing.s),
                ],
              ],
            ),
    );
  }
}

class _AcademicMetricBox extends StatelessWidget {
  const _AcademicMetricBox({
    required this.label,
    required this.value,
    required this.balanced,
  });

  final String label;
  final String value;
  final bool balanced;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: balanced
              ? theme.spacing.s + theme.spacing.xs
              : theme.spacing.m,
          vertical: theme.spacing.m,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                theme.control.regular +
                theme.spacing.xl +
                theme.spacing.xs +
                (balanced ? theme.spacing.m : 0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                value,
                style: theme.typography.h2.copyWith(
                  color: theme.color.foreground,
                  fontWeight: FontWeight.w600,
                  height: YhTypographyTokens.compactLineHeight,
                  fontFamily: YhTypographyTokens.fontFamilyMono,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicNextExamCard extends StatelessWidget {
  const _AcademicNextExamCard({required this.nextExam});

  final AcademicExamRecord? nextExam;

  @override
  Widget build(BuildContext context) {
    final now =
        context
            .findAncestorWidgetOfExactType<AcademicPage>()
            ?.academicTermNow ??
        DateTime.now();
    final date = DateTime.tryParse(nextExam?.displayExamDate ?? '');
    final days = date == null
        ? null
        : DateTime(
            date.year,
            date.month,
            date.day,
          ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final dayLabel = days == null || days < 0 ? null : '$days 天';
    final detail = [
      if (date != null) '${date.month} 月 ${date.day} 日',
      if ((nextExam?.displayExamArrange ?? '').isNotEmpty)
        nextExam!.displayExamArrange!,
      if ((nextExam?.displayExamLocation ?? '').isNotEmpty)
        nextExam!.displayExamLocation!,
    ].join(' · ');
    return _AcademicSectionCard(
      title: '下一场考试',
      summary: dayLabel == null ? '当前没有已发布日期的考试' : '离考试还有 $dayLabel',
      child: nextExam == null
          ? const _AcademicInlineEmpty(text: '考试日期尚未发布')
          : _AcademicActionRow(
              passive: true,
              icon: YhIcons.calendar,
              title: nextExam!.courseName,
              detail: detail,
              trail: dayLabel?.replaceAll(' ', ''),
            ),
    );
  }
}

class _AcademicArchiveCard extends StatelessWidget {
  const _AcademicArchiveCard({
    required this.onOpenGrades,
    required this.onOpenExams,
    required this.onOpenSchedule,
  });

  final VoidCallback? onOpenGrades;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return _AcademicSectionCard(
      title: '学习档案',
      summary: '进入详情后仍保留来源、学期和返回上下文。',
      child: Column(
        children: [
          _AcademicActionRow(
            key: const ValueKey('academic-overview-grade'),
            icon: YhIcons.academic,
            title: '课程成绩',
            detail: '按学期查看成绩与过程分',
            trail: '›',
            onTap: onOpenGrades,
          ),
          _AcademicActionRow(
            key: const ValueKey('academic-overview-exam'),
            icon: YhIcons.calendar,
            title: '考试安排',
            detail: '时间、地点与考试类型',
            trail: '›',
            onTap: onOpenExams,
          ),
          _AcademicActionRow(
            key: const ValueKey('academic-overview-schedule'),
            icon: YhIcons.info,
            title: '课表与培养进度',
            detail: '当前课表、已修学分和待完成课程',
            trail: '›',
            onTap: onOpenSchedule,
          ),
        ],
      ),
    );
  }
}

class _AcademicCompletionCard extends StatelessWidget {
  const _AcademicCompletionCard({
    required this.value,
    required this.completedCredits,
    required this.totalCredits,
  });

  final double value;
  final double? completedCredits;
  final double totalCredits;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final creditLabel = completedCredits == null || totalCredits <= 0
        ? '—'
        : '${completedCredits!.toStringAsFixed(0)}/${totalCredits.toStringAsFixed(0)}';
    return _AcademicSectionCard(
      title: '完成度',
      summary: '状态色只表达完成情况，不替代教务域色。',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.sunken,
          borderRadius: BorderRadius.circular(theme.radius.m),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '毕业要求',
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                '${(value * 100).round()}%',
                style: theme.typography.h2.copyWith(
                  color: theme.color.foreground,
                  fontWeight: FontWeight.w600,
                  height: YhTypographyTokens.compactLineHeight,
                  fontFamily: YhTypographyTokens.fontFamilyMono,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Row(
                children: [
                  Expanded(
                    child: YhProgressBar(
                      value: value,
                      semanticLabel: '毕业要求完成度',
                    ),
                  ),
                  SizedBox(width: theme.spacing.s),
                  Text(
                    creditLabel,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                      fontWeight: FontWeight.w600,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicSectionCard extends StatelessWidget {
  const _AcademicSectionCard({
    required this.title,
    required this.summary,
    required this.child,
  });

  final String title;
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      padding: EdgeInsets.all(theme.spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.typography.h3.copyWith(
              color: theme.color.foreground,
              fontWeight: FontWeight.w600,
              height: theme.typography.h3.height,
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            summary,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          child,
        ],
      ),
    );
  }
}

class _AcademicActionRow extends StatelessWidget {
  const _AcademicActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.trail,
    this.onTap,
    this.passive = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? trail;
  final VoidCallback? onTap;
  final bool passive;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final content = Padding(
      padding: EdgeInsets.all(theme.spacing.s),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.brandTint,
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: SizedBox.square(
              dimension: theme.control.compact,
              child: Icon(
                icon,
                size: theme.control.compact / 2,
                color: theme.color.brandStrong,
              ),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.copyWith(
                    color: theme.color.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
          if (trail != null) ...[
            SizedBox(width: theme.spacing.s),
            Text(
              trail!,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        ],
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            theme.control.minimumTarget +
            (MediaQuery.sizeOf(context).width >= theme.breakpoint.medium &&
                    MediaQuery.sizeOf(context).width < theme.breakpoint.expanded
                ? theme.spacing.m + theme.spacing.xs
                : theme.spacing.s + theme.layout.divider * 2),
      ),
      child: onTap == null && !passive
          ? Opacity(opacity: theme.opacity.disabled, child: content)
          : onTap == null
          ? content
          : YhPressable(
              semanticLabel: '$title，$detail',
              onPressed: onTap,
              builder: (context, state, child) => DecoratedBox(
                decoration: BoxDecoration(
                  color: state.hovered || state.pressed
                      ? theme.color.sunken
                      : theme.color.surface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(theme.radius.input),
                ),
                child: child,
              ),
              child: content,
            ),
    );
  }
}

class _AcademicInlineEmpty extends StatelessWidget {
  const _AcademicInlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.yhTheme.typography.small.copyWith(
      color: context.yhTheme.color.muted,
    ),
  );
}

class _AcademicStatePanel extends StatelessWidget {
  const _AcademicStatePanel({
    required this.state,
    required this.refreshSourceCount,
    required this.onRefresh,
    required this.onOpenAccountConnections,
    required this.onAdjustAcademicTerm,
  });

  final AcademicOverviewDisplayState state;
  final int refreshSourceCount;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenAccountConnections;
  final VoidCallback? onAdjustAcademicTerm;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (state == AcademicOverviewDisplayState.loading ||
        state == AcademicOverviewDisplayState.operationLocked) {
      final operationLocked =
          state == AcademicOverviewDisplayState.operationLocked;
      return YhCard(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: theme.layout.popoverWidth - theme.spacing.m,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: theme.control.regular,
                  child: const YhProgress(showPercent: false),
                ),
                SizedBox(width: theme.spacing.m),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: operationLocked,
                        child: Text(
                          operationLocked
                              ? '正在读取 $refreshSourceCount 个可用教务来源'
                              : '正在恢复本机教务快照',
                          style: theme.typography.h3,
                        ),
                      ),
                      SizedBox(height: theme.spacing.s),
                      Text(
                        operationLocked
                            ? '完成前已锁定重复刷新和详情导航；若部分来源失败，将保留各自最后有效数据。'
                            : '页面结构与已有导航保持可用；网络读取完成后再替换各区域。',
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final (icon, title, message, label, action, variant) = switch (state) {
      AcademicOverviewDisplayState.initial => (
        YhIcons.academic,
        '尚未读取教务快照',
        '先从本机恢复已保存内容；只有你主动刷新时才访问校园服务。',
        '读取教务数据',
        onRefresh,
        YhButtonVariant.primary,
      ),
      AcademicOverviewDisplayState.empty => (
        YhIcons.academic,
        '当前学期没有可展示的学习记录',
        '读取已完成，但成绩、考试和课表均为空；可调整学期或查看账户范围。',
        '调整学期',
        onAdjustAcademicTerm,
        YhButtonVariant.secondary,
      ),
      AcademicOverviewDisplayState.credentialsRequired => (
        YhIcons.academic,
        '需要先完成教务账户连接',
        '尚未保存 OA 账号或密码；现在不会发起任何校园服务请求。',
        '前往账户与连接',
        onOpenAccountConnections,
        YhButtonVariant.primary,
      ),
      _ => (
        YhIcons.info,
        '无法读取教务数据',
        '未读取到可用快照；请检查校园网络或 VPN 后重试。',
        '检查后重试',
        onRefresh,
        YhButtonVariant.primary,
      ),
    };
    return YhCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: theme.layout.popoverWidth - theme.spacing.m,
        ),
        child: _AcademicStateEmpty(
          icon: icon,
          title: title,
          message: message,
          action: YhButton(label: label, variant: variant, onTap: action),
        ),
      ),
    );
  }
}

class _AcademicStateEmpty extends StatelessWidget {
  const _AcademicStateEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.brandTint,
                borderRadius: BorderRadius.circular(theme.radius.m),
              ),
              child: SizedBox.square(
                dimension: theme.control.regular,
                child: Icon(icon, color: theme.color.brandStrong),
              ),
            ),
            SizedBox(height: theme.spacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.h3.copyWith(
                color: theme.color.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.s),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: theme.layout.compactContentWidth,
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.m),
            action,
          ],
        ),
      ),
    );
  }
}

class _AcademicLegacySources extends StatelessWidget {
  const _AcademicLegacySources({
    super.key,
    required this.focusNode,
    required this.locked,
    required this.primary,
    required this.sports,
    required this.secondClassroom,
  });

  final Widget primary;
  final Widget sports;
  final Widget secondClassroom;
  final FocusNode focusNode;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final content = Focus(
      key: const ValueKey('academic-legacy-sources-focus'),
      focusNode: focusNode,
      canRequestFocus: !locked,
      descendantsAreFocusable: !locked,
      descendantsAreTraversable: !locked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('详细数据源', style: theme.typography.h2),
          SizedBox(height: theme.spacing.m),
          _AcademicDashboardGrid(
            primary: primary,
            sports: sports,
            secondClassroom: secondClassroom,
          ),
          SizedBox(height: theme.spacing.m),
          const YhBanner(text: '只读边界：不提供选课、退课、调课、教学评价、提交申请或任何状态变更入口。'),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: locked ? '详细数据源，协同刷新期间不可用' : '详细数据源',
      enabled: !locked,
      child: ExcludeSemantics(
        excluding: locked,
        child: IgnorePointer(
          ignoring: locked,
          child: Opacity(
            opacity: locked ? theme.opacity.disabled : 1,
            child: content,
          ),
        ),
      ),
    );
  }
}
