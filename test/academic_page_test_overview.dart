/*
 * 教务总览协同回归测试
 * @Project : SSPU-AllinOne
 * @File : academic_page_test_overview.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page_test.dart';

/// 注册教务总览协同测试。
///
/// :returns: 无返回值。
void _registerAcademicOverviewTests() {
  testWidgets('学程总览协同刷新期间锁定重复动作且每个来源只请求一次', (tester) async {
    final semantics = tester.ensureSemantics();
    final overview = Completer<AcademicEamsQueryResult>();
    final exams = Completer<AcademicEamsQueryResult>();
    final grades = Completer<AcademicEamsQueryResult>();
    final sports = Completer<SportsAttendanceQueryResult>();
    final report = Completer<StudentReportQueryResult>();
    final academicClient = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      pendingOverview: overview,
      pendingExam: exams,
      pendingGrades: grades,
    );
    final sportsClient = _FakeSportsAttendanceClient(
      result: _successResult,
      pendingFetch: sports,
    );
    final reportClient = _FakeStudentReportClient(
      result: _creditResult,
      pendingFetch: report,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: academicClient,
      sportsAttendanceService: sportsClient,
      studentReportService: reportClient,
    );
    await tester.pump();

    final refresh = find.byKey(const ValueKey('academic-overview-refresh'));
    expect(refresh, findsOneWidget);
    expect(find.byKey(const Key('academic-eams-refresh')), findsNothing);
    expect(find.byKey(const Key('academic-sports-refresh')), findsNothing);
    expect(
      find.byKey(const Key('academic-student-report-refresh')),
      findsNothing,
    );
    await tester.tap(refresh);
    await tester.pump();

    final lockedStatus = find.text('正在读取 5 个可用教务来源');
    expect(lockedStatus, findsOneWidget);
    expect(
      tester.getSemantics(lockedStatus).flagsCollection.isLiveRegion,
      isTrue,
    );
    expect(find.text('本地快照可用'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('academic-overview-grade')),
        matching: find.byType(YhPressable),
      ),
      findsNothing,
    );
    expect(academicClient.overviewFetchCount, 1);
    expect(academicClient.examFetchCount, 1);
    expect(academicClient.gradeFetchCount, 1);
    expect(sportsClient.fetchCount, 1);
    expect(reportClient.fetchCount, 1);

    await tester.tap(refresh);
    await tester.pump();
    expect(academicClient.overviewFetchCount, 1);
    expect(sportsClient.fetchCount, 1);

    final lockedSources = tester.getSemantics(
      find.bySemanticsLabel('详细数据源，协同刷新期间不可用'),
    );
    expect(lockedSources.flagsCollection.isEnabled, Tristate.isFalse);
    final lockedFocus = tester.widget<Focus>(
      find.byKey(const ValueKey('academic-legacy-sources-focus')),
    );
    expect(lockedFocus.canRequestFocus, isFalse);
    expect(lockedFocus.descendantsAreFocusable, isFalse);
    expect(lockedFocus.descendantsAreTraversable, isFalse);

    final legacyDetail = find.byKey(
      const Key('academic-student-report-detail'),
    );
    await tester.ensureVisible(legacyDetail);
    await tester.tap(legacyDetail, warnIfMissed: false);
    await tester.pump();
    expect(find.text('第二课堂详情'), findsNothing);

    overview.complete(_academicEamsResult);
    exams.complete(_academicEamsResult);
    grades.complete(_academicEamsResult);
    sports.complete(_successResult);
    report.complete(_creditResult);
    await tester.pumpAndSettle();

    expect(find.text('正在读取 5 个可用教务来源'), findsNothing);
    expect(find.text('教务数据已刷新'), findsOneWidget);
    semantics.dispose();
    await disposeAcademicPage(tester);
  });

  testWidgets('凭据切换立即解除协同锁且旧代结果不得回写', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final overview = Completer<AcademicEamsQueryResult>();
    final exams = Completer<AcademicEamsQueryResult>();
    final grades = Completer<AcademicEamsQueryResult>();
    final sports = Completer<SportsAttendanceQueryResult>();
    final report = Completer<StudentReportQueryResult>();
    final academicClient = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      pendingOverview: overview,
      pendingExam: exams,
      pendingGrades: grades,
    );
    final sportsClient = _FakeSportsAttendanceClient(
      result: _successResult,
      pendingFetch: sports,
    );
    final reportClient = _FakeStudentReportClient(
      result: _creditResult,
      pendingFetch: report,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: academicClient,
      sportsAttendanceService: sportsClient,
      studentReportService: reportClient,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('academic-overview-refresh')));
    await tester.pump();
    expect(find.text('正在读取 5 个可用教务来源'), findsOneWidget);

    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260002',
      oaPassword: 'new-password',
      sportsQueryPassword: 'new-sports-password',
    );
    await tester.pump();
    expect(find.text('正在读取 5 个可用教务来源'), findsNothing);

    overview.complete(_academicEamsResult);
    exams.complete(_academicEamsResult);
    grades.complete(_academicEamsResult);
    sports.complete(_successResult);
    report.complete(_creditResult);
    await tester.pumpAndSettle();

    expect(find.text('教务数据已刷新'), findsNothing);
    expect(
      tester
          .widget<AcademicEamsSummaryCard>(find.byType(AcademicEamsSummaryCard))
          .result,
      isNull,
    );
    expect(
      tester
          .widget<AcademicSportsAttendanceCard>(
            find.byType(AcademicSportsAttendanceCard),
          )
          .result,
      isNull,
    );
    expect(
      tester
          .widget<AcademicStudentReportCard>(
            find.byType(AcademicStudentReportCard),
          )
          .result,
      isNull,
    );
    expect(academicClient.overviewFetchCount, 1);
    expect(academicClient.examFetchCount, 1);
    expect(academicClient.gradeFetchCount, 1);
    expect(sportsClient.fetchCount, 1);
    expect(reportClient.fetchCount, 1);
    await disposeAcademicPage(tester);
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('详细数据源入口满足触控尺寸并在跳转后转移键盘焦点', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
        cachedExamResult: _academicEamsResult,
        cachedGradeResult: _academicEamsResult,
      ),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
        cachedResult: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(
        result: _creditResult,
        cachedResult: _creditResult,
      ),
    );
    await pumpUntilFound(tester, find.text('查看详细数据源'));

    final shortcut = find.byKey(
      const ValueKey('academic-overview-detailed-sources'),
    );
    expect(tester.getSize(shortcut).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(shortcut);
    await tester.pumpAndSettle();
    await tester.tap(shortcut);
    await tester.pumpAndSettle();

    final headingTop = tester.getTopLeft(find.text('详细数据源')).dy;
    expect(headingTop, inInclusiveRange(0, tester.view.physicalSize.height));
    final focus = tester.widget<Focus>(
      find.byKey(const ValueKey('academic-legacy-sources-focus')),
    );
    expect(focus.focusNode?.hasFocus, isTrue);
    await disposeAcademicPage(tester);
  });

  testWidgets('有本地快照的自动刷新明确显示正在更新且保留内容', (tester) async {
    final sports = Completer<SportsAttendanceQueryResult>();
    final sportsClient = _FakeSportsAttendanceClient(
      result: _successResult,
      cachedResult: _successResult,
      pendingFetch: sports,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
      ),
      sportsAttendanceService: sportsClient,
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
    );
    await pumpUntilFound(tester, find.text('正在更新'));

    expect(find.text('本地快照可用'), findsOneWidget);
    expect(find.text('正在更新'), findsOneWidget);
    expect(
      tester
          .widget<AcademicSportsAttendanceCard>(
            find.byType(AcademicSportsAttendanceCard),
          )
          .result,
      same(_successResult),
    );

    sports.complete(_successResult);
    await tester.pumpAndSettle();
    expect(find.text('正在更新'), findsNothing);
    await disposeAcademicPage(tester);
  });

  testWidgets('缺少 OA 凭据时不请求任何校园来源并打开账户连接', (tester) async {
    final missingCredentials = AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.missingOaAccount,
      message: '请先保存学工号（OA账号）',
      detail: '当前不会访问校园服务。',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://oa.example.invalid/academic'),
    );
    final academicClient = _FakeAcademicEamsClient(
      result: missingCredentials,
      cachedOverviewResult: missingCredentials,
    );
    final sportsClient = _FakeSportsAttendanceClient(result: _successResult);
    final reportClient = _FakeStudentReportClient(result: _creditResult);
    var openedConnections = 0;
    await pumpAcademicPage(
      tester,
      academicEamsService: academicClient,
      sportsAttendanceService: sportsClient,
      studentReportService: reportClient,
      academicEamsAutoRefreshEnabledOverride: true,
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
      credentialsStatusOverride: const AcademicCredentialsStatus.empty(),
      onOpenAccountConnections: () => openedConnections++,
    );
    await pumpUntilFound(tester, find.text('需要先完成教务账户连接'));

    await tester.tap(find.byKey(const ValueKey('academic-overview-refresh')));
    await tester.pump();

    expect(academicClient.overviewFetchCount, 0);
    expect(academicClient.examFetchCount, 0);
    expect(academicClient.gradeFetchCount, 0);
    expect(sportsClient.fetchCount, 0);
    expect(reportClient.fetchCount, 0);

    await tester.tap(find.text('前往账户与连接'));
    await tester.pump();
    expect(openedConnections, 1);
    await disposeAcademicPage(tester);
  });

  testWidgets('仅缺体育凭据时保留缓存且协同刷新跳过不可用来源', (tester) async {
    final academicClient = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      cachedOverviewResult: _academicEamsResult,
      cachedExamResult: _academicEamsResult,
      cachedGradeResult: _academicEamsResult,
    );
    final sportsClient = _FakeSportsAttendanceClient(
      result: _successResult,
      cachedResult: _successResult,
    );
    final reportClient = _FakeStudentReportClient(
      result: _creditResult,
      cachedResult: _creditResult,
    );
    var openedConnections = 0;
    await pumpAcademicPage(
      tester,
      academicEamsService: academicClient,
      sportsAttendanceService: sportsClient,
      studentReportService: reportClient,
      credentialsStatusOverride: _partialAcademicCredentials,
      onOpenAccountConnections: () => openedConnections++,
    );
    await pumpUntilFound(tester, find.text('体育考勤连接未完成；刷新只会访问其余 4 个可用只读来源。'));

    expect(find.text('OA 数据已读取'), findsOneWidget);
    await tester.tap(find.text('连接设置'));
    await tester.pump();
    expect(openedConnections, 1);

    await tester.tap(find.byKey(const ValueKey('academic-overview-refresh')));
    await tester.pumpAndSettle();

    expect(academicClient.overviewFetchCount, 1);
    expect(academicClient.examFetchCount, 1);
    expect(academicClient.gradeFetchCount, 1);
    expect(reportClient.fetchCount, 1);
    expect(sportsClient.fetchCount, 0);
    expect(find.text('可用教务数据已刷新'), findsOneWidget);
    expect(find.text('体育考勤未连接，本次未请求。'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('部分凭据下可用来源全失败时区分失败与未请求', (tester) async {
    final academicFailure = AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.networkError,
      message: '暂时无法读取教务数据',
      detail: '网络不可用',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://oa.example.invalid/academic'),
    );
    final reportFailure = StudentReportQueryResult(
      status: StudentReportQueryStatus.networkError,
      message: '暂时无法读取第二课堂',
      detail: '网络不可用',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://oa.example.invalid/report'),
    );
    final academicClient = _FakeAcademicEamsClient(result: academicFailure);
    final sportsClient = _FakeSportsAttendanceClient(result: _successResult);
    final reportClient = _FakeStudentReportClient(result: reportFailure);
    await pumpAcademicPage(
      tester,
      academicEamsService: academicClient,
      sportsAttendanceService: sportsClient,
      studentReportService: reportClient,
      credentialsStatusOverride: _partialAcademicCredentials,
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('academic-overview-refresh')));
    await tester.pumpAndSettle();

    expect(find.text('可用教务数据刷新失败'), findsOneWidget);
    expect(find.textContaining('体育考勤未连接，本次未请求'), findsOneWidget);
    expect(find.text('教务数据部分更新'), findsNothing);
    expect(find.text('无法读取教务数据'), findsOneWidget);
    expect(find.text('未读取到可用快照；请检查校园网络或 VPN 后重试。'), findsOneWidget);
    expect(find.text('检查后重试'), findsOneWidget);
    expect(find.text('尚未读取教务快照'), findsNothing);
    expect(academicClient.overviewFetchCount, 1);
    expect(academicClient.examFetchCount, 1);
    expect(academicClient.gradeFetchCount, 1);
    expect(reportClient.fetchCount, 1);
    expect(sportsClient.fetchCount, 0);
    await disposeAcademicPage(tester);
  });

  testWidgets('协同刷新部分失败时保留各来源最后有效缓存', (tester) async {
    final academicFailure = AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.networkError,
      message: '暂时无法读取',
      detail: '网络不可用',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://oa.example.invalid/academic'),
    );
    final sportsFailure = SportsAttendanceQueryResult(
      status: SportsAttendanceQueryStatus.networkError,
      message: '暂时无法读取体育考勤',
      detail: '网络不可用',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://sports.example.invalid/login'),
    );
    final reportFailure = StudentReportQueryResult(
      status: StudentReportQueryStatus.networkError,
      message: '暂时无法读取第二课堂',
      detail: '网络不可用',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://oa.example.invalid/report'),
    );
    final academicClient = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      cachedOverviewResult: _academicEamsResult,
      cachedGradeResult: _academicEamsResult,
      examResult: academicFailure,
      gradeResult: academicFailure,
    );
    final sportsClient = _FakeSportsAttendanceClient(
      result: sportsFailure,
      cachedResult: _successResult,
    );
    final reportClient = _FakeStudentReportClient(
      result: reportFailure,
      cachedResult: _creditResult,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: academicClient,
      sportsAttendanceService: sportsClient,
      studentReportService: reportClient,
    );
    await pumpUntilFound(tester, find.text('3.0'));

    await tester.tap(find.byKey(const ValueKey('academic-overview-refresh')));
    await tester.pumpAndSettle();

    expect(find.text('3.0'), findsOneWidget);
    final bannerTexts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(YhBanner),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .whereType<String>();
    expect(
      bannerTexts,
      contains(
        '考试、成绩、体育考勤、第二课堂未完成；'
        '体育考勤、第二课堂继续显示最后有效数据；'
        '考试、成绩暂无可保留数据；可使用页面顶部刷新按钮重试。',
      ),
    );
    expect(find.text('教务数据部分更新'), findsOneWidget);
    expect(academicClient.overviewFetchCount, 1);
    expect(academicClient.examFetchCount, 1);
    expect(academicClient.gradeFetchCount, 1);
    expect(sportsClient.fetchCount, 1);
    expect(reportClient.fetchCount, 1);
    await disposeAcademicPage(tester);
  });

  testWidgets('单一来源恢复后立即清除页面失败标记', (tester) async {
    final sportsFailure = SportsAttendanceQueryResult(
      status: SportsAttendanceQueryStatus.networkError,
      message: '暂时无法读取体育考勤',
      detail: '网络不可用',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://sports.example.invalid/login'),
    );
    final sportsClient = _FakeSportsAttendanceClient(
      result: _successResult,
      cachedResult: _successResult,
      resultResolver: (fetchCount) =>
          fetchCount == 1 ? sportsFailure : _successResult,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
        cachedExamResult: _academicEamsResult,
        cachedGradeResult: _academicEamsResult,
      ),
      sportsAttendanceService: sportsClient,
      studentReportService: _FakeStudentReportClient(
        result: _creditResult,
        cachedResult: _creditResult,
      ),
    );
    await pumpUntilFound(tester, find.text('3.0'));

    await tester.tap(find.byKey(const ValueKey('academic-overview-refresh')));
    await tester.pumpAndSettle();
    final sportsFailureBanner = find.descendant(
      of: find.byType(YhBanner),
      matching: find.textContaining('体育考勤未完成'),
    );
    expect(sportsFailureBanner, findsOneWidget);

    final sportsRefresh = find.byKey(
      const ValueKey('academic-overview-refresh'),
    );
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await tester.pumpAndSettle();

    expect(sportsClient.fetchCount, 2);
    expect(sportsFailureBanner, findsNothing);
    await disposeAcademicPage(tester);
  });
}
