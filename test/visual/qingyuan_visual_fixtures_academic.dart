/*
 * 清源视觉 fixture — 教务、成绩、考试与校历
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_fixtures_academic.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'qingyuan_visual_capture_test.dart';

/// 构建 _academicOverview 对应的确定性视觉场景。
///
/// :param scenario: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _academicOverview(_AcademicOverviewScenario scenario) {
  final loading = scenario == _AcademicOverviewScenario.loading;
  final operationLocked = scenario == _AcademicOverviewScenario.operationLocked;
  final credentialsRequired =
      scenario == _AcademicOverviewScenario.credentialsRequired;
  final credentialsPartial =
      scenario == _AcademicOverviewScenario.credentialsPartial;
  const completeCredentials = AcademicCredentialsStatus(
    oaAccount: '20260001',
    emailAccount: '20260001@sspu.edu.cn',
    hasOaPassword: true,
    hasSportsQueryPassword: true,
    hasEmailPassword: true,
  );
  const partialCredentials = AcademicCredentialsStatus(
    oaAccount: '20260001',
    emailAccount: '20260001@sspu.edu.cn',
    hasOaPassword: true,
    hasSportsQueryPassword: false,
    hasEmailPassword: true,
  );
  final hasCache = switch (scenario) {
    _AcademicOverviewScenario.initial ||
    _AcademicOverviewScenario.loading ||
    _AcademicOverviewScenario.credentialsRequired => false,
    _ => true,
  };
  final credentialsResult = AcademicEamsQueryResult(
    status: AcademicEamsQueryStatus.missingOaAccount,
    message: '请先保存学工号（OA账号）',
    detail: '当前不会发起校园服务请求。',
    checkedAt: qingyuanVisualNow,
    entranceUri: Uri.parse('https://oa.example.invalid/academic'),
  );
  final overviewResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicOverviewEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicOverviewStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicDetailErrorResult,
    _AcademicOverviewScenario.credentialsRequired => credentialsResult,
    _ => qingyuanHomeAcademicResult,
  };
  final gradeResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicGradeEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicGradeStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicDetailErrorResult,
    _AcademicOverviewScenario.credentialsRequired => credentialsResult,
    _ => qingyuanAcademicGradeContentResult,
  };
  final examResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicExamEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicExamStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicDetailErrorResult,
    _AcademicOverviewScenario.credentialsRequired => credentialsResult,
    _ => qingyuanAcademicOverviewExamContentResult,
  };
  final sportsResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicSportsEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicSportsStaleResult,
    _AcademicOverviewScenario.error ||
    _AcademicOverviewScenario.partialError => qingyuanAcademicSportsErrorResult,
    _ => qingyuanHomeSportsResult,
  };
  final reportResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicStudentReportEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicStudentReportStaleResult,
    _AcademicOverviewScenario.error || _AcademicOverviewScenario.partialError =>
      qingyuanAcademicStudentReportErrorResult,
    _ => qingyuanHomeStudentReportResult,
  };
  return AcademicPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: overviewResult,
      cachedOverviewResult: hasCache || credentialsRequired
          ? overviewResult
          : null,
      cachedGradeResult: hasCache || credentialsRequired ? gradeResult : null,
      cachedExamResult: hasCache || credentialsRequired ? examResult : null,
      examResult: examResult,
      gradeResult: gradeResult,
      pendingOverview: loading || operationLocked
          ? Completer<AcademicEamsQueryResult>()
          : null,
      pendingExam: operationLocked
          ? Completer<AcademicEamsQueryResult>()
          : null,
      pendingGrades: operationLocked
          ? Completer<AcademicEamsQueryResult>()
          : null,
    ),
    sportsAttendanceService: QingyuanVisualSportsAttendanceClient(
      sportsResult,
      cacheEnabled: hasCache,
      pendingFetch: loading || operationLocked
          ? Completer<SportsAttendanceQueryResult>()
          : null,
    ),
    studentReportService: QingyuanVisualStudentReportClient(
      reportResult,
      cacheEnabled: hasCache,
      pendingFetch: loading || operationLocked
          ? Completer<StudentReportQueryResult>()
          : null,
    ),
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    credentialsStatusOverride: credentialsRequired
        ? const AcademicCredentialsStatus.empty()
        : credentialsPartial
        ? partialCredentials
        : completeCredentials,
    academicEamsAutoRefreshEnabledOverride: loading,
    academicEamsAutoRefreshIntervalOverride: 30,
    sportsAttendanceAutoRefreshEnabledOverride: loading,
    sportsAttendanceAutoRefreshIntervalOverride: 30,
    studentReportAutoRefreshEnabledOverride: loading,
    studentReportAutoRefreshIntervalOverride: 30,
    onOpenAccountConnections: () {},
    onAdjustAcademicTerm: () {},
  );
}

/// 准备 _prepareAcademicOverviewLoading 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareAcademicOverviewLoading(WidgetTester tester) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('正在恢复本机教务快照').evaluate().isNotEmpty) return;
  }
  throw StateError('教务概览未在固定等待窗口内进入 loading 状态');
}

/// 准备 _prepareAcademicOverviewOperationLocked 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareAcademicOverviewOperationLocked(
  WidgetTester tester,
) async {
  final refresh = find.byKey(const ValueKey('academic-overview-refresh'));
  await tester.tap(refresh);
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.textContaining('正在协同刷新 5 个').evaluate().isNotEmpty) {
      return;
    }
  }
  throw StateError('教务概览未在固定等待窗口内进入 operation-locked 状态');
}

/// 构建 _academicGradeDetail 对应的确定性视觉场景。
///
/// :param result: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _academicGradeDetail(AcademicEamsQueryResult result) {
  return AcademicEamsGradeDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: result,
      gradeResult: result,
    ),
    initialResult: result,
    onResultChanged: (_) {},
  );
}

/// 构建 _academicGradeDetailLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicGradeDetailLoading() {
  return AcademicEamsGradeDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicGradeContentResult,
      pendingGrades: Completer<AcademicEamsQueryResult>(),
    ),
    initialResult: null,
    onResultChanged: (_) {},
  );
}

/// 构建 _academicGradeDetailOperationLocked 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicGradeDetailOperationLocked() {
  return AcademicEamsGradeDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicGradeContentResult,
      pendingGrades: Completer<AcademicEamsQueryResult>(),
    ),
    initialResult: qingyuanAcademicGradeContentResult,
    onResultChanged: (_) {},
  );
}

/// 准备 _prepareAcademicGradeDetailOperationLocked 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareAcademicGradeDetailOperationLocked(
  WidgetTester tester,
) async {
  await tester.tap(find.byKey(const Key('academic-eams-grade-detail-refresh')));
  await tester.pump();
}

/// 构建 _academicExamDetail 对应的确定性视觉场景。
///
/// :param result: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _academicExamDetail(AcademicEamsQueryResult result) {
  return AcademicEamsExamDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: result,
      examResult: result,
    ),
    initialResult: result,
    initialSelectedTerm: qingyuanAcademicSemester.termChoice,
    initialSelectedSemester: qingyuanAcademicSemester,
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    onResultChanged: (_, _, _) {},
  );
}

/// 构建 _academicExamDetailLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicExamDetailLoading() {
  return AcademicEamsExamDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicExamContentResult,
      pendingExam: Completer<AcademicEamsQueryResult>(),
    ),
    initialResult: null,
    initialSelectedTerm: qingyuanAcademicSemester.termChoice,
    initialSelectedSemester: qingyuanAcademicSemester,
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    onResultChanged: (_, _, _) {},
  );
}

/// 准备 _prepareAcademicExamLoading 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareAcademicExamLoading(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
  await tester.pump();
}

/// 构建 _academicExamDetailOperationLocked 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicExamDetailOperationLocked() {
  return AcademicEamsExamDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicExamContentResult,
      pendingExam: Completer<AcademicEamsQueryResult>(),
    ),
    initialResult: qingyuanAcademicExamContentResult,
    initialSelectedTerm: qingyuanAcademicSemester.termChoice,
    initialSelectedSemester: qingyuanAcademicSemester,
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    onResultChanged: (_, _, _) {},
  );
}

/// 准备 _prepareAcademicExamDetailOperationLocked 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareAcademicExamDetailOperationLocked(
  WidgetTester tester,
) async {
  await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
  await tester.pump();
}

/// 准备 _startStudentReportDetailRefresh 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _startStudentReportDetailRefresh(WidgetTester tester) async {
  await tester.tap(find.text('刷新成绩单'));
  await tester.pump();
}

/// 准备 _startSportsAttendanceDetailRefresh 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _startSportsAttendanceDetailRefresh(WidgetTester tester) async {
  await tester.tap(find.text('刷新考勤'));
  await tester.pump();
}

/// 构建 _academicGradeProcess 对应的确定性视觉场景。
///
/// :param result: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _academicGradeProcess(AcademicEamsQueryResult result) {
  return AcademicEamsGradeProcessPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: result,
      gradeProcessResult: result,
    ),
    initialTerm: qingyuanAcademicSemester.termChoice,
    initialSemester: qingyuanAcademicSemester,
  );
}

/// 构建 _academicGradeProcessLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicGradeProcessLoading() {
  return AcademicEamsGradeProcessPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicGradeProcessContentResult,
      pendingGradeProcess: Completer<AcademicEamsQueryResult>(),
    ),
    initialTerm: qingyuanAcademicSemester.termChoice,
    initialSemester: qingyuanAcademicSemester,
    initialCheckedAt: qingyuanVisualNow,
  );
}

/// 构建 _academicGradeProcessOperationLocked 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicGradeProcessOperationLocked() {
  final pending = Completer<AcademicEamsQueryResult>();
  return AcademicEamsGradeProcessPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicGradeProcessContentResult,
      gradeProcessResultResolver: (fetchCount) => fetchCount == 1
          ? Future.value(qingyuanAcademicGradeProcessContentResult)
          : pending.future,
    ),
    initialTerm: qingyuanAcademicSemester.termChoice,
    initialSemester: qingyuanAcademicSemester,
  );
}

/// 准备 _prepareAcademicGradeProcessOperationLocked 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _prepareAcademicGradeProcessOperationLocked(
  WidgetTester tester,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    final refresh = find.byKey(const Key('academic-eams-grade-process-search'));
    if (refresh.evaluate().isNotEmpty &&
        find.text('过程证据').evaluate().isNotEmpty) {
      await tester.tap(refresh);
      await tester.pump();
      return;
    }
  }
  throw StateError('过程化成绩未在固定等待窗口内进入可刷新内容态');
}

/// 构建 _academicCalendarLoading 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarLoading() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      pendingViewer: Completer<AcademicCalendarSyncResult>(),
    ),
  );
}

/// 构建 _academicCalendarContent 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarContent() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      cachedEntries: qingyuanAcademicCalendarEntries,
      viewerResult: qingyuanAcademicCalendarContentResult,
    ),
  );
}

/// 构建 _academicCalendarEmpty 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarEmpty() {
  return _academicCalendarPage(
    const QingyuanVisualAcademicCalendarClient(
      viewerResult: qingyuanAcademicCalendarEmptyResult,
    ),
  );
}

/// 构建 _academicCalendarStale 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarStale() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      cachedEntries: qingyuanAcademicCalendarEntries,
      viewerResult: qingyuanAcademicCalendarStaleResult,
    ),
  );
}

/// 构建 _academicCalendarError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarError() {
  return _academicCalendarPage(
    const QingyuanVisualAcademicCalendarClient(
      viewerResult: qingyuanAcademicCalendarErrorResult,
    ),
  );
}

/// 构建 _academicCalendarPartialError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarPartialError() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      cachedEntries: qingyuanAcademicCalendarEntries,
      viewerResult: qingyuanAcademicCalendarPartialErrorResult,
    ),
  );
}

/// 构建 _academicCalendarOperationLocked 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarOperationLocked() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      cachedEntries: qingyuanAcademicCalendarEntries,
      viewerResult: qingyuanAcademicCalendarContentResult,
      pendingRefresh: Completer<List<AcademicCalendarCacheEntry>>(),
    ),
  );
}

/// 构建 _academicCalendarExternalConfirmation 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarExternalConfirmation() => _academicCalendarPage(
  QingyuanVisualAcademicCalendarClient(
    cachedEntries: qingyuanAcademicCalendarEntries,
    viewerResult: qingyuanAcademicCalendarContentResult,
  ),
  launchExternalOverride: (uri) async => true,
);

/// 构建 _academicCalendarExternalError 对应的确定性视觉场景。
///
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarExternalError() => _academicCalendarPage(
  QingyuanVisualAcademicCalendarClient(
    cachedEntries: qingyuanAcademicCalendarEntries,
    viewerResult: qingyuanAcademicCalendarContentResult,
  ),
  launchExternalOverride: (uri) async => false,
);

/// 准备 _startAcademicCalendarRefresh 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _startAcademicCalendarRefresh(WidgetTester tester) async {
  await _waitForVisualFinder(tester, find.bySemanticsLabel('刷新校历'), '校历刷新入口');
  await tester.tap(find.bySemanticsLabel('刷新校历'));
  await tester.pump();
}

/// 准备 _showAcademicCalendarExternalConfirmation 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _showAcademicCalendarExternalConfirmation(
  WidgetTester tester,
) async {
  await _waitForVisualFinder(
    tester,
    find.bySemanticsLabel('外部打开校历 PDF'),
    '校历外部打开入口',
  );
  await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
  await tester.pumpAndSettle();
}

/// 准备 _failAcademicCalendarExternalOpen 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _failAcademicCalendarExternalOpen(WidgetTester tester) async {
  await _showAcademicCalendarExternalConfirmation(tester);
  await tester.tap(find.text('继续打开'));
  await tester.pumpAndSettle();
}

/// 准备 _waitForVisualFinder 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :param finder: 当前视觉场景输入。
/// :param description: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _waitForVisualFinder(
  WidgetTester tester,
  Finder finder,
  String description,
) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw StateError('$description 未在固定等待窗口内出现');
}

const Key _academicCalendarExternalRegionKey = Key(
  'academic-calendar-external-region',
);

/// 构建 _academicCalendarPage 对应的确定性视觉场景。
///
/// :param service: 当前视觉场景输入。
/// :param launchExternalOverride: 当前视觉场景输入。
/// :returns: 可用于视觉采集的界面。
Widget _academicCalendarPage(
  QingyuanVisualAcademicCalendarClient service, {

  /// 准备 Function 对应的确定性视觉状态。
  ///
  /// :param uri: 当前视觉场景输入。
  /// :returns: 对应的确定性测试值。
  Future<bool> Function(Uri uri)? launchExternalOverride,
}) {
  return AcademicCalendarPage(
    service: service,
    termService: _QingyuanVisualAcademicTermService(),
    now: DateTime(2026, 7, 18, 9, 30),
    launchExternalOverride: launchExternalOverride,
    viewerBuilder: (context, entry) {
      final theme = context.yhTheme;
      return KeyedSubtree(
        key: _academicCalendarExternalRegionKey,
        child: ColoredBox(
          color: theme.color.sunken,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  YhIcons.library,
                  size: theme.spacing.xl,
                  color: theme.color.muted,
                ),
                SizedBox(height: theme.spacing.m),
                Text(
                  entry == null
                      ? '请选择校历'
                      : '${entry.schoolYearStart}–${entry.schoolYearStart + 1} 学年校历正文',
                  textAlign: TextAlign.center,
                  style: theme.typography.h3.copyWith(
                    color: theme.color.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: theme.breakpoint.compact / 2,
                  ),
                  child: Text(
                    entry == null
                        ? '从校历列表选择一个学年。'
                        : 'PDF 正文由平台查看器绘制，应用只负责来源、选择与恢复操作。',
                    textAlign: TextAlign.center,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _QingyuanVisualAcademicTermService extends AcademicTermService {
  static const _actual = AcademicTermChoice(
    academicYear: 2025,
    season: AcademicTermSeason.summer,
  );
  AcademicTermSettings _settings = const AcademicTermSettings(
    selectedTerm: AcademicTermChoice(
      academicYear: 2025,
      season: AcademicTermSeason.fall,
    ),
  );

  /// 返回视觉场景当前选择的查询学期。
  ///
  /// :returns: 确定性学期设置。
  @override
  AcademicTermSettings get settings => _settings;

  /// 解析 availableTerms 使用的确定性视觉测试值。
  ///
  /// :returns: 对应的确定性测试值。
  @override
  List<AcademicTermChoice> get availableTerms => [
    for (final season in AcademicTermSeason.values)
      AcademicTermChoice(academicYear: 2025, season: season),
  ];

  /// 准备 loadSettings 对应的确定性视觉状态。
  ///
  /// :returns: 对应的确定性测试值。
  @override
  Future<AcademicTermSettings> loadSettings() async => _settings;

  /// 准备 getEffectiveContext 对应的确定性视觉状态。
  ///
  /// :param now: 当前视觉场景输入。
  /// :returns: 对应的确定性测试值。
  @override
  Future<AcademicTermContext> getEffectiveContext({DateTime? now}) async =>
      AcademicTermContext(
        term: _actual,
        queryTerm: _settings.selectedTerm,
        source: AcademicTermContextSource.selected,
        dateStatus: AcademicTermDateStatus.summerVacation,
        resolvedAt: now ?? DateTime(2026, 7, 18, 9, 30),
        isTeachingWeek: false,
      );

  /// 准备 setSelectedTerm 对应的确定性视觉状态。
  ///
  /// :param term: 当前视觉场景输入。
  /// :returns: 视觉状态准备完成时结束。
  @override
  Future<void> setSelectedTerm(AcademicTermChoice term) async {
    _settings = AcademicTermSettings(selectedTerm: term);
  }
}
