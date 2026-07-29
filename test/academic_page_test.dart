/*
 * 教务中心页面测试 — 校验体育部课外活动考勤汇总与明细展示
 * @Project : SSPU-AllinOne
 * @File : academic_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

part 'academic_page_test_support.dart';

const _completeAcademicCredentials = AcademicCredentialsStatus(
  oaAccount: '20260001',
  emailAccount: '20260001@sspu.edu.cn',
  hasOaPassword: true,
  hasSportsQueryPassword: true,
  hasEmailPassword: true,
);

const _partialAcademicCredentials = AcademicCredentialsStatus(
  oaAccount: '20260001',
  emailAccount: '20260001@sspu.edu.cn',
  hasOaPassword: true,
  hasSportsQueryPassword: false,
  hasEmailPassword: true,
);

/// 等待异步卡片加载完成。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 推进页面动画和 Fluent 点击态短计时器，避免组件卸载后残留 timer。
Future<void> disposeAcademicPage(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> pumpAcademicPage(
  WidgetTester tester, {
  required AcademicEamsClient academicEamsService,
  required SportsAttendanceClient sportsAttendanceService,
  required StudentReportClient studentReportService,
  AcademicTermService? academicTermService,
  bool academicEamsAutoRefreshEnabledOverride = false,
  int academicEamsAutoRefreshIntervalOverride = 30,
  bool sportsAttendanceAutoRefreshEnabledOverride = false,
  int sportsAttendanceAutoRefreshIntervalOverride = 30,
  bool studentReportAutoRefreshEnabledOverride = false,
  int studentReportAutoRefreshIntervalOverride = 30,
  VoidCallback? onOpenAccountConnections,
  VoidCallback? onAdjustAcademicTerm,
  AcademicCredentialsStatus credentialsStatusOverride =
      _completeAcademicCredentials,
}) async {
  await tester.pumpWidget(
    YhApp(
      home: AcademicPage(
        academicEamsService: academicEamsService,
        academicTermService: academicTermService,
        sportsAttendanceService: sportsAttendanceService,
        studentReportService: studentReportService,
        academicEamsAutoRefreshEnabledOverride:
            academicEamsAutoRefreshEnabledOverride,
        academicEamsAutoRefreshIntervalOverride:
            academicEamsAutoRefreshIntervalOverride,
        sportsAttendanceAutoRefreshEnabledOverride:
            sportsAttendanceAutoRefreshEnabledOverride,
        sportsAttendanceAutoRefreshIntervalOverride:
            sportsAttendanceAutoRefreshIntervalOverride,
        studentReportAutoRefreshEnabledOverride:
            studentReportAutoRefreshEnabledOverride,
        studentReportAutoRefreshIntervalOverride:
            studentReportAutoRefreshIntervalOverride,
        onOpenAccountConnections: onOpenAccountConnections,
        onAdjustAcademicTerm: onAdjustAcademicTerm,
        credentialsStatusOverride: credentialsStatusOverride,
      ),
    ),
  );
}

void main() {
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
        '考试、成绩暂无可保留数据；可在详细数据源中分别重试。',
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

    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await tester.pumpAndSettle();

    expect(sportsClient.fetchCount, 2);
    expect(sportsFailureBanner, findsNothing);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂详情通过查询结果展示加载与错误状态', (tester) async {
    await tester.pumpWidget(
      const YhApp(home: StudentReportDetailPage(result: null, isLoading: true)),
    );

    expect(find.text('正在读取第二课堂成绩单'), findsOneWidget);

    await tester.pumpWidget(
      YhApp(
        home: StudentReportDetailPage(
          result: StudentReportQueryResult(
            status: StudentReportQueryStatus.networkError,
            message: '暂时无法读取第二课堂学分',
            detail: '请检查 OA 登录与校园网络后重试。',
            checkedAt: DateTime(2026, 7, 18, 9, 30),
            entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('已有有效缓存不会被清空'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看失败原因'));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂时无法读取第二课堂学分'), findsOneWidget);
    expect(find.textContaining('请检查 OA 登录与校园网络后重试。'), findsOneWidget);
  });

  testWidgets('第二课堂详情使用独立证据任务页并将规则分层', (tester) async {
    final summaryJson = _creditResult.summary!.toJson();
    summaryJson['totals'] = {
      ..._creditResult.summary!.totals!.toJson(),
      'totalRequiredCredit': 10,
    };
    summaryJson['rules'] = [
      for (final item in summaryJson['rules']! as List<dynamic>)
        if ((item as Map<String, dynamic>)['category'] == '报告与讲座')
          {...item, 'category': '报告讲座'}
        else
          item,
    ];
    final resultWithTenRequiredCredits = StudentReportQueryResult(
      status: _creditResult.status,
      message: _creditResult.message,
      detail: _creditResult.detail,
      checkedAt: _creditResult.checkedAt,
      entranceUri: _creditResult.entranceUri,
      finalUri: _creditResult.finalUri,
      summary: SecondClassroomCreditSummary.fromJson(summaryJson),
    );
    await tester.pumpWidget(
      YhApp(
        home: StudentReportDetailPage(result: resultWithTenRequiredCredits),
      ),
    );

    expect(find.text('第二课堂成绩单'), findsOneWidget);
    expect(find.text('课外成长'), findsWidgets);
    expect(find.text('刷新成绩单'), findsOneWidget);
    expect(find.text('查看积分规则'), findsOneWidget);
    expect(find.text('已获积分记录'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('1.50 / 2.00'), findsOneWidget);
    expect(find.text('规则矩阵'), findsNothing);
  });

  testWidgets('第二课堂详情刷新单飞且失败保留当前证据', (tester) async {
    final completion = Completer<StudentReportQueryResult>();
    var refreshCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: StudentReportDetailPage(
          result: _creditResult,
          onRefresh: () {
            refreshCount++;
            return completion.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('刷新成绩单'));
    await tester.pump();
    await tester.tap(find.text('正在刷新…'));
    await tester.pump();

    expect(refreshCount, 1);
    expect(find.text('10.55'), findsOneWidget);
    expect(find.textContaining('当前内容和返回路径保持可用'), findsOneWidget);

    completion.complete(
      StudentReportQueryResult(
        status: StudentReportQueryStatus.networkError,
        message: '暂时无法刷新第二课堂学分',
        detail: '请检查 OA 登录与校园网络后重试。',
        checkedAt: DateTime(2026, 7, 18, 9, 30),
        entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('10.55'), findsOneWidget);
    expect(find.textContaining('暂时无法刷新第二课堂学分'), findsOneWidget);
  });

  testWidgets('教务详情外部快照换代立即解除旧刷新并隔离其结果', (tester) async {
    final oldRefresh = Completer<StudentReportQueryResult>();
    final replacementJson = _creditResult.summary!.toJson();
    replacementJson['totals'] = {
      ..._creditResult.summary!.totals!.toJson(),
      'totalRequiredCredit': 20,
    };
    final replacement = StudentReportQueryResult(
      status: StudentReportQueryStatus.success,
      message: '账户换代后的第二课堂快照',
      detail: '已切换到新账户代次。',
      checkedAt: DateTime(2026, 7, 18, 10),
      entranceUri: _creditResult.entranceUri,
      summary: SecondClassroomCreditSummary.fromJson(replacementJson),
    );
    const pageKey = ValueKey('student-report-generation-test');

    await tester.pumpWidget(
      YhApp(
        home: StudentReportDetailPage(
          key: pageKey,
          result: _creditResult,
          onRefresh: () => oldRefresh.future,
        ),
      ),
    );
    await tester.tap(find.text('刷新成绩单'));
    await tester.pump();
    expect(find.text('正在刷新…'), findsOneWidget);

    await tester.pumpWidget(
      YhApp(
        home: StudentReportDetailPage(
          key: pageKey,
          result: replacement,
          onRefresh: () async => replacement,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('刷新成绩单'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);

    oldRefresh.complete(_creditResult);
    await tester.pump();
    await tester.pump();

    expect(find.text('20'), findsOneWidget);
    expect(find.text('8'), findsNothing);
  });

  testWidgets('教务证据详情退出后丢弃未完成刷新视图回写', (tester) async {
    final completion = Completer<StudentReportQueryResult>();
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开第二课堂证据',
            onTap: () => Navigator.of(context).push(
              YhPageRoute(
                builder: (_) => StudentReportDetailPage(
                  result: _creditResult,
                  onRefresh: () => completion.future,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开第二课堂证据'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刷新成绩单'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    completion.complete(_creditResult);
    await tester.pump();

    expect(find.text('打开第二课堂证据'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('体育考勤详情通过查询结果展示加载与错误状态', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: SportsAttendanceDetailPage(result: null, isLoading: true),
      ),
    );

    expect(find.text('正在读取体育考勤'), findsOneWidget);

    await tester.pumpWidget(
      YhApp(
        home: SportsAttendanceDetailPage(
          result: SportsAttendanceQueryResult(
            status: SportsAttendanceQueryStatus.networkError,
            message: '暂时无法读取体育考勤',
            detail: '请检查校园网络或 VPN 后重试。',
            checkedAt: DateTime(2026, 7, 18, 9, 30),
            entranceUri: Uri.parse('https://sports.example.invalid/login'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('已有有效缓存不会被清空'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看失败原因'));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂时无法读取体育考勤'), findsOneWidget);
    expect(find.textContaining('请检查校园网络或 VPN 后重试。'), findsOneWidget);
  });

  testWidgets('体育考勤详情使用证据任务页且紧凑布局无需横向表格', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(home: SportsAttendanceDetailPage(result: _successResult)),
    );

    expect(find.text('体育考勤'), findsOneWidget);
    expect(find.text('刷新考勤'), findsOneWidget);
    expect(find.text('考勤明细'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
    expect(find.textContaining('2026-04-01'), findsWidgets);
    expect(find.text('原始记录已保留'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('体育考勤详情刷新成功后整体替换为同代快照', (tester) async {
    final completion = Completer<SportsAttendanceQueryResult>();
    await tester.pumpWidget(
      YhApp(
        home: SportsAttendanceDetailPage(
          result: _successResult,
          onRefresh: () => completion.future,
        ),
      ),
    );

    await tester.tap(find.text('刷新考勤'));
    await tester.pump();
    expect(find.textContaining('当前内容和返回路径保持可用'), findsOneWidget);

    completion.complete(
      SportsAttendanceQueryResult(
        status: SportsAttendanceQueryStatus.success,
        message: '体育考勤已同步',
        detail: '已读取新快照。',
        checkedAt: DateTime(2026, 7, 18, 10),
        entranceUri: Uri.parse('https://sports.example.invalid/login'),
        summary: SportsAttendanceSummary(
          morningExerciseCount: 10,
          extracurricularActivityCount: 10,
          countAdjustmentCount: 0,
          sportsCorridorCount: 0,
          records: const [],
          fetchedAt: DateTime(2026, 7, 18, 10),
          sourceUri: Uri.parse('https://sports.example.invalid/attendance'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('20'), findsOneWidget);
    expect(find.text('暂无明细记录：体育部页面返回了汇总次数，但没有可展示的考勤明细。'), findsOneWidget);
  });

  testWidgets('第二课堂规则页复用规则矩阵并独立呈现', (tester) async {
    await tester.pumpWidget(
      YhApp(home: StudentReportRulesPage(summary: _creditResult.summary!)),
    );

    expect(find.text('第二课堂规则'), findsOneWidget);
    expect(find.text('规则矩阵'), findsOneWidget);
    expect(find.text('志愿服务'), findsWidgets);
  });

  testWidgets('教务详情页保留 summary 构造兼容入口', (tester) async {
    await tester.pumpWidget(
      YhApp(home: StudentReportDetailPage(summary: _creditResult.summary!)),
    );
    expect(find.text('第二课堂成绩单'), findsOneWidget);
    expect(find.text('总已获分数'), findsOneWidget);

    await tester.pumpWidget(
      YhApp(home: SportsAttendanceDetailPage(summary: _successResult.summary!)),
    );
    await tester.pump();
    expect(find.text('体育考勤'), findsOneWidget);
    expect(find.text('2 条记录'), findsOneWidget);
  });

  testWidgets('教务中心通过注入学期服务解析默认学期', (tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(() {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
    });
    final calendar = _FakeAcademicCalendarClient();
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      academicTermService: AcademicTermService(calendarService: calendar),
    );
    for (
      var attempt = 0;
      attempt < 20 && calendar.ensureForDateCount == 0;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(calendar.ensureForDateCount, 1);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心有缓存快照时仍明确展示部分降级提示', (tester) async {
    final partial = AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.partialSuccess,
      message: '正在显示昨日教务缓存',
      detail: '网络恢复后可手动刷新。',
      checkedAt: DateTime(2026, 7, 17, 18),
      entranceUri: Uri.parse('https://oa.example.invalid/academic'),
      snapshot: _academicEamsResult.snapshot,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: partial,
        cachedOverviewResult: partial,
      ),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );
    await pumpUntilFound(tester, find.textContaining('正在显示昨日教务缓存'));

    expect(
      find.text('当前显示 7 月 17 日 18:00 的本地教务快照；刷新失败不会删除这些内容。'),
      findsOneWidget,
    );
    expect(find.text('OA 数据部分读取'), findsOneWidget);
    expect(find.text('OA 状态未校验'), findsNothing);
    expect(find.text('正在显示昨日教务缓存：网络恢复后可手动刷新。'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示体育部考勤总次数并可进入明细页', (tester) async {
    final sportsService = _FakeSportsAttendanceClient(result: _successResult);
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: sportsService,
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    expect(find.textContaining('自动刷新未开启'), findsWidgets);
    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('8'));

    expect(find.text('课外活动考勤'), findsOneWidget);
    expect(find.textContaining('体育部查询系统只读汇总'), findsNothing);
    expect(find.textContaining('展示晨跑'), findsNothing);
    expect(find.text('总次数'), findsOneWidget);
    expect(find.text('早操 2 次'), findsOneWidget);
    expect(find.text('课外活动 3 次'), findsOneWidget);
    expect(find.text('次数调整 -1 次'), findsOneWidget);
    expect(find.text('体育长廊 4 次'), findsOneWidget);
    expect(find.text('上次刷新：2026-04-30 00:00'), findsOneWidget);
    final sportsTitleCenter = tester.getCenter(find.text('课外活动考勤'));
    final sportsLastRefreshCenter = tester.getCenter(
      find.text('上次刷新：2026-04-30 00:00'),
    );
    final sportsSummaryBottom = tester.getBottomLeft(find.text('总次数')).dy;
    final sportsButtonCenter = tester.getCenter(find.text('查看考勤记录'));
    expect(sportsLastRefreshCenter.dy, greaterThan(sportsTitleCenter.dy));
    expect(sportsLastRefreshCenter.dy, greaterThan(sportsSummaryBottom));
    expect((sportsButtonCenter.dy - sportsTitleCenter.dy).abs(), lessThan(20));
    expect(sportsService.requireCampusNetworkValues, [false]);

    await tester.ensureVisible(find.text('查看考勤记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看考勤记录'));
    await tester.pumpAndSettle();

    expect(find.text('体育考勤'), findsOneWidget);
    expect(find.text('2 条记录'), findsOneWidget);
    expect(find.text('总次数'), findsWidgets);
    expect(find.text('晨跑次数'), findsOneWidget);
    expect(find.text('考勤明细'), findsOneWidget);
    expect(find.text('04·01'), findsOneWidget);
    expect(find.textContaining('原始记录已保留'), findsWidgets);
    expect(find.textContaining('体育长廊'), findsWidgets);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示体育部登录失败状态', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: SportsAttendanceQueryResult(
          status: SportsAttendanceQueryStatus.missingSportsPassword,
          message: '请先保存体育部查询密码',
          detail: '体育部查询系统密码与 OA 密码不同，需单独配置。',
          checkedAt: DateTime(2026, 4, 30),
          entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
        ),
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('请先保存体育部查询密码'));

    expect(find.text('请先保存体育部查询密码'), findsOneWidget);
    expect(find.textContaining('OA 密码不同'), findsOneWidget);
    expect(find.text('刷新失败:未设置体育密码×'), findsOneWidget);
    expect(find.text('上次刷新：2026-04-30 00:00'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心自动刷新开启时会主动读取体育考勤', (tester) async {
    final sportsService = _FakeSportsAttendanceClient(result: _successResult);
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: sportsService,
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      sportsAttendanceAutoRefreshIntervalOverride: 1,
    );

    await pumpUntilFound(tester, find.text('8'));

    expect(find.text('总次数'), findsOneWidget);
    expect(sportsService.fetchCount, 1);
    expect(sportsService.requireCampusNetworkValues, [true]);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(sportsService.fetchCount, 2);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示校园网或 VPN 不可用状态', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: SportsAttendanceQueryResult(
          status: SportsAttendanceQueryStatus.campusNetworkUnavailable,
          message: '校园网 / VPN 不可用，无法访问体育部查询系统',
          detail: '无法访问 tygl.sspu.edu.cn',
          checkedAt: DateTime(2026, 4, 30),
          entranceUri: Uri.parse('https://tygl.sspu.edu.cn/sportscore/'),
        ),
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.textContaining('校园网 / VPN 不可用'));

    expect(find.textContaining('无法访问体育部查询系统'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示第二课堂学分并可进入明细页', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('总已获分数'));

    expect(find.text('刷新成功√'), findsOneWidget);
    expect(find.text('第二课堂学分'), findsOneWidget);
    expect(find.text('总已获分数'), findsOneWidget);
    expect(find.text('总必修积分'), findsOneWidget);
    expect(find.text('总体通过情况'), findsOneWidget);
    expect(find.text('详情记录'), findsOneWidget);
    expect(find.text('10.55'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('未通过'), findsOneWidget);
    expect(find.text('5 项'), findsOneWidget);
    expect(find.text('社会实践'), findsWidgets);
    expect(find.text('报告与讲座'), findsWidgets);
    expect(find.text('校园文化活动'), findsWidgets);
    expect(find.text('创新创业活动'), findsWidgets);
    expect(find.text('4.65/2.00'), findsWidgets);
    expect(find.text('1.50/2.00'), findsWidgets);
    expect(find.text('1.00/2.00'), findsWidgets);
    expect(find.text('2.00/0.00'), findsWidgets);
    expect(find.text('上次刷新：2026-05-01 00:00'), findsOneWidget);
    expect(find.textContaining('数据来自学工报表系统'), findsNothing);
    final titleCenter = tester.getCenter(find.text('第二课堂学分'));
    final lastRefreshCenter = tester.getCenter(
      find.text('上次刷新：2026-05-01 00:00'),
    );
    final refreshCenter = tester.getCenter(studentReportRefresh);
    final lastRefreshRight = tester
        .getTopRight(find.text('上次刷新：2026-05-01 00:00'))
        .dx;
    final titleLeft = tester.getTopLeft(find.text('第二课堂学分')).dx;
    final lastRefreshLeft = tester
        .getTopLeft(find.text('上次刷新：2026-05-01 00:00'))
        .dx;
    final refreshLeft = tester.getTopLeft(studentReportRefresh).dx;
    expect(lastRefreshCenter.dy, greaterThan(titleCenter.dy));
    expect((lastRefreshLeft - titleLeft).abs(), lessThan(1));
    expect((refreshCenter.dy - lastRefreshCenter.dy).abs(), lessThan(1));
    expect(refreshLeft - lastRefreshRight, greaterThanOrEqualTo(0));
    expect(refreshLeft - lastRefreshRight, lessThan(16));
    expect(
      lastRefreshCenter.dy,
      lessThan(tester.getTopLeft(find.text('总已获分数')).dy),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新成功√'), findsNothing);

    final detailButton = find.byKey(
      const Key('academic-student-report-detail'),
    );
    await tester.ensureVisible(detailButton);
    await tester.pumpAndSettle();
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('第二课堂成绩单'), findsOneWidget);
    expect(find.text('积分证据'), findsOneWidget);
    expect(find.text('总积分'), findsNothing);
    expect(find.text('总已获分数'), findsOneWidget);
    expect(find.text('已获积分记录'), findsOneWidget);
    expect(find.text('规则矩阵'), findsNothing);
    expect(find.bySemanticsLabel('收起已获积分详情'), findsNothing);
    expect(find.textContaining('志愿服务'), findsWidgets);
    expect(find.textContaining('创新训练项目'), findsWidgets);

    await tester.ensureVisible(find.text('查看积分规则'));
    await tester.tap(find.text('查看积分规则'));
    await tester.pumpAndSettle();
    expect(find.text('第二课堂规则'), findsOneWidget);
    expect(find.text('规则矩阵'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心自动刷新开启时会主动读取第二课堂学分', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    expect(find.text('详情记录'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂手动刷新失败时显示预置短原因', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(
        result: StudentReportQueryResult(
          status: StudentReportQueryStatus.campusNetworkUnavailable,
          message: '校园网 / VPN 不可用，无法访问学工报表系统',
          detail: '无法访问 xgbb.sspu.edu.cn',
          checkedAt: DateTime(2026, 5, 1),
          entranceUri: Uri.parse(
            'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=xgreport',
          ),
        ),
      ),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('刷新失败:校园网/VPN不可用×'));

    expect(find.textContaining('无法访问学工报表系统'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新失败:校园网/VPN不可用×'), findsNothing);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂卡片和详情页在移动端宽度下不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('社会实践'));

    expect(find.text('4.65/2.00'), findsOneWidget);
    expect(find.text('1.50/2.00'), findsOneWidget);
    expect(find.text('1.00/2.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final detailButton = find.byKey(
      const Key('academic-student-report-detail'),
    );
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('已获积分记录'), findsOneWidget);
    expect(find.text('规则矩阵'), findsNothing);
    expect(find.byType(Table), findsNothing);

    await tester.ensureVisible(find.text('查看积分规则'));
    await tester.tap(find.text('查看积分规则'));
    await tester.pumpAndSettle();
    expect(find.text('规则矩阵'), findsOneWidget);
    expect(find.text('必修'), findsWidgets);
    expect(find.text('通过'), findsWidgets);
    expect(find.text('参与情况'), findsWidgets);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('体育考勤详情页在移动端以完整字段记录卡展示且不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final sportsRefresh = find.byKey(const Key('academic-sports-refresh'));
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('8'));

    await tester.ensureVisible(find.text('查看考勤记录'));
    await tester.tap(find.text('查看考勤记录'));
    await tester.pumpAndSettle();

    expect(find.text('体育考勤'), findsOneWidget);
    expect(find.text('考勤明细'), findsOneWidget);
    expect(find.text('晨跑次数'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
    expect(find.text('04·01'), findsOneWidget);
    expect(find.text('06:50'), findsOneWidget);
    expect(find.textContaining('原始记录已保留'), findsWidgets);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('第二课堂摘要中等宽度下固定为二乘二布局', (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final studentReportRefresh = find.byKey(
      const Key('academic-student-report-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('创新创业活动'));

    final socialTop = tester.getTopLeft(find.text('社会实践')).dy;
    final reportTop = tester.getTopLeft(find.text('报告与讲座')).dy;
    final cultureTop = tester.getTopLeft(find.text('校园文化活动')).dy;
    final innovationTop = tester.getTopLeft(find.text('创新创业活动')).dy;

    expect((socialTop - reportTop).abs(), lessThan(1));
    expect((cultureTop - innovationTop).abs(), lessThan(1));
    expect(cultureTop, greaterThan(socialTop));
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心宽屏下体育与第二课堂卡片行内等高', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    final sportsCard = find.byKey(const Key('academic-sports-card'));
    final studentReportCard = find.byKey(
      const Key('academic-student-report-card'),
    );
    final sportsSize = tester.getSize(sportsCard);
    final studentReportSize = tester.getSize(studentReportCard);
    expect((sportsSize.height - studentReportSize.height).abs(), lessThan(1));
    expect(
      tester.getBottomLeft(sportsCard).dy,
      tester.getBottomLeft(studentReportCard).dy,
    );
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心中屏下体育与第二课堂卡片行内等高', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    final sportsCard = find.byKey(const Key('academic-sports-card'));
    final studentReportCard = find.byKey(
      const Key('academic-student-report-card'),
    );
    final sportsSize = tester.getSize(sportsCard);
    final studentReportSize = tester.getSize(studentReportCard);
    expect((sportsSize.height - studentReportSize.height).abs(), lessThan(1));
    expect(
      tester.getBottomLeft(sportsCard).dy,
      tester.getBottomLeft(studentReportCard).dy,
    );
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心窄屏下单列卡片不强制等高且无溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      sportsAttendanceAutoRefreshEnabledOverride: true,
      studentReportAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('总已获分数'));

    final sportsCard = find.byKey(const Key('academic-sports-card'));
    final studentReportCard = find.byKey(
      const Key('academic-student-report-card'),
    );
    expect(
      tester.getTopLeft(studentReportCard).dy,
      greaterThan(tester.getBottomLeft(sportsCard).dy),
    );
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务中心展示本专科教务摘要并可进入课程表页', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final legacyRefresh = find.byKey(const Key('academic-eams-refresh'));
    await tester.ensureVisible(legacyRefresh);
    await tester.tap(legacyRefresh);
    await pumpUntilFound(tester, find.textContaining('姓名：张三'));

    expect(find.text('本专科教务'), findsOneWidget);
    expect(find.textContaining('课表 1门'), findsOneWidget);
    expect(find.textContaining('开课检索：入口已识别'), findsOneWidget);

    final openCourseSchedule = find.byKey(const Key('open-course-schedule'));
    await tester.ensureVisible(openCourseSchedule);
    await tester.tap(openCourseSchedule);
    await tester.pumpAndSettle();

    expect(find.text('课程表'), findsWidgets);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.text('1–2'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('本专科教务成绩卡片只展示GPA与门数并可进入详情和过程化成绩页', (tester) async {
    final academicService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: academicService,
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final refresh = find.byKey(const Key('academic-eams-refresh'));
    await tester.ensureVisible(refresh);
    await tester.tap(refresh);
    final gradeCard = find.byKey(const Key('academic-eams-grade-card'));
    await pumpUntilFound(
      tester,
      find.descendant(of: gradeCard, matching: find.text('成绩门数')),
    );

    final primaryCard = find.byType(AcademicEamsSummaryCard);
    expect(
      find.descendant(of: primaryCard, matching: gradeCard),
      findsOneWidget,
    );
    // 卡片仅展示 GPA 与成绩门数指标块，不再列课程预览。
    expect(
      find.descendant(of: gradeCard, matching: find.textContaining('GPA')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: gradeCard, matching: find.text('高等数学')),
      findsNothing,
    );
    expect(academicService.gradeFetchCount, 1);

    final detailButton = find.byKey(const Key('academic-eams-grade-detail'));
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('课程成绩'), findsWidgets);
    expect(
      find.byKey(const Key('academic-eams-grade-term-select')),
      findsOneWidget,
    );
    // 默认查看全部学期。
    expect(find.text('全部学期'), findsWidgets);
    expect(find.text('高等数学'), findsWidgets);

    // 命令栏进入过程化成绩三级页（按学期独立请求平时成绩明细）。
    final processEntry = find.byKey(
      const Key('academic-eams-grade-process-entry'),
    );
    expect(processEntry, findsOneWidget);
    await tester.tap(processEntry);
    await pumpUntilFound(tester, find.text('平时成绩Ⅰ'));
    expect(find.text('高等数学D1'), findsWidgets);
    expect(academicService.gradeProcessFetchCount, 1);
    await disposeAcademicPage(tester);
  });

  testWidgets('成绩详情刷新单飞且失败保留筛选范围与当前成绩', (tester) async {
    final pending = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      pendingGrades: pending,
    );
    var callbackCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeDetailPage(
          academicEamsService: service,
          initialResult: _academicEamsResult,
          onResultChanged: (_) => callbackCount++,
        ),
      ),
    );
    await tester.pump();

    final refresh = find.byKey(const Key('academic-eams-grade-detail-refresh'));
    await tester.tap(refresh);
    await tester.pump();
    await tester.tap(refresh);
    await tester.pump();

    expect(service.gradeFetchCount, 1);
    expect(find.text('高等数学'), findsWidgets);
    expect(find.text('全部学期'), findsWidgets);

    pending.complete(_academicDetailFailureResult);
    await tester.pump();
    await tester.pump();

    expect(find.text('高等数学'), findsWidgets);
    expect(find.textContaining('校园网络或 VPN'), findsOneWidget);
    expect(callbackCount, 0);
    await disposeAcademicPage(tester);
  });

  testWidgets('考试详情搜索单飞且失败保留筛选范围与当前安排', (tester) async {
    final pending = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _academicExamResult,
      pendingExam: pending,
    );
    var callbackCount = 0;
    final semester = _academicExamResult.snapshot!.exams!.selectedSemester!;
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: service,
          initialResult: _academicExamResult,
          initialSelectedTerm: semester.termChoice,
          initialSelectedSemester: semester,
          onResultChanged: (_, _, _) => callbackCount++,
        ),
      ),
    );
    await tester.pump();

    final search = find.byKey(const Key('academic-eams-exam-detail-search'));
    await tester.tap(search);
    await tester.pump();
    await tester.tap(search);
    await tester.pump();

    expect(service.examFetchCount, 1);
    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(find.text('春季学期'), findsOneWidget);

    pending.complete(_academicDetailFailureResult);
    await tester.pump();
    await tester.pump();

    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(find.textContaining('校园网络或 VPN'), findsOneWidget);
    expect(callbackCount, 0);
    await disposeAcademicPage(tester);
  });

  testWidgets('过程化成绩刷新单飞且失败保留学期与评价证据', (tester) async {
    final pending = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      gradeProcessResultResolver: (fetchCount) =>
          fetchCount == 1 ? Future.value(_gradeProcessResult) : pending.future,
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          academicEamsService: service,
          initialTerm: const AcademicTermChoice(
            academicYear: 2025,
            season: AcademicTermSeason.spring,
          ),
          initialSemester:
              _gradeProcessResult.snapshot!.gradeProcess!.selectedSemester,
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('平时成绩Ⅰ'));

    final search = find.byKey(const Key('academic-eams-grade-process-search'));
    await tester.tap(search);
    await tester.pump();
    await tester.tap(search);
    await tester.pump();

    expect(service.gradeProcessFetchCount, 2);
    expect(find.text('平时成绩Ⅰ'), findsOneWidget);
    expect(find.text('2025-2026-2'), findsWidgets);

    pending.complete(_academicDetailFailureResult);
    await tester.pump();
    await tester.pump();

    expect(find.text('平时成绩Ⅰ'), findsOneWidget);
    expect(find.textContaining('校园网络或 VPN'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('成绩与考试凭据换代立即解锁且同一结果对象也不得触发旧代回写', (tester) async {
    final oldGrade = Completer<AcademicEamsQueryResult>();
    final oldGradeService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      pendingGrades: oldGrade,
    );
    final newGradeService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      gradeResult: _academicEamsResult,
    );
    var gradeCallbackCount = 0;
    const gradeKey = ValueKey('grade-credential-generation');
    Widget gradePage(AcademicEamsClient service) => YhApp(
      home: AcademicEamsGradeDetailPage(
        key: gradeKey,
        academicEamsService: service,
        initialResult: _academicEamsResult,
        onResultChanged: (_) => gradeCallbackCount++,
      ),
    );

    await tester.pumpWidget(gradePage(oldGradeService));
    await tester.tap(
      find.byKey(const Key('academic-eams-grade-detail-refresh')),
    );
    await tester.pump();
    expect(find.text('正在刷新…'), findsOneWidget);

    await tester.pumpWidget(gradePage(newGradeService));
    await tester.pump();
    expect(find.text('刷新成绩'), findsOneWidget);
    oldGrade.complete(_academicEamsResult);
    await tester.pump();
    await tester.pump();
    expect(gradeCallbackCount, 0);

    await tester.tap(
      find.byKey(const Key('academic-eams-grade-detail-refresh')),
    );
    await tester.pump();
    expect(newGradeService.gradeFetchCount, 1);
    expect(gradeCallbackCount, 1);

    final oldExam = Completer<AcademicEamsQueryResult>();
    final oldExamService = _FakeAcademicEamsClient(
      result: _academicExamResult,
      pendingExam: oldExam,
    );
    final newExamService = _FakeAcademicEamsClient(
      result: _academicExamResult,
      examResult: _academicExamResult,
    );
    var examCallbackCount = 0;
    const examKey = ValueKey('exam-credential-generation');
    final semester = _academicExamResult.snapshot!.exams!.selectedSemester!;
    Widget examPage(AcademicEamsClient service) => YhApp(
      home: AcademicEamsExamDetailPage(
        key: examKey,
        academicEamsService: service,
        initialResult: _academicExamResult,
        initialSelectedTerm: semester.termChoice,
        initialSelectedSemester: semester,
        onResultChanged: (_, _, _) => examCallbackCount++,
      ),
    );

    await tester.pumpWidget(examPage(oldExamService));
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await tester.pump();
    expect(find.text('正在刷新…'), findsOneWidget);

    await tester.pumpWidget(examPage(newExamService));
    await tester.pump();
    expect(find.text('刷新安排'), findsOneWidget);
    oldExam.complete(_academicExamResult);
    await tester.pump();
    await tester.pump();
    expect(examCallbackCount, 0);

    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await tester.pump();
    expect(newExamService.examFetchCount, 1);
    expect(examCallbackCount, 1);
    await disposeAcademicPage(tester);
  });

  testWidgets('过程化成绩凭据与学期换代清除旧证据并只接纳新代结果', (tester) async {
    final oldResult = Completer<AcademicEamsQueryResult>();
    final oldService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      gradeProcessResultResolver: (_) => oldResult.future,
    );
    final newService = _FakeAcademicEamsClient(result: _academicEamsResult);
    const pageKey = ValueKey('grade-process-credential-generation');
    const oldTerm = AcademicTermChoice(
      academicYear: 2024,
      season: AcademicTermSeason.fall,
    );
    final oldSemester = AcademicEamsSemesterOption.fromEamsFields(
      id: 'old-semester',
      schoolYear: '2024-2025',
      termCode: '1',
    );
    final newSemester =
        _gradeProcessResult.snapshot!.gradeProcess!.selectedSemester!;

    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          key: pageKey,
          academicEamsService: oldService,
          initialTerm: oldTerm,
          initialSemester: oldSemester,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('正在读取过程化成绩'), findsOneWidget);

    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          key: pageKey,
          academicEamsService: newService,
          initialTerm: newSemester.termChoice,
          initialSemester: newSemester,
        ),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.text('平时成绩Ⅰ'));
    expect(newService.gradeProcessFetchCount, 1);
    expect(newService.gradeProcessSemesterValues.single?.id, newSemester.id);

    oldResult.complete(_gradeProcessResult);
    await tester.pump();
    await tester.pump();
    expect(find.text('平时成绩Ⅰ'), findsOneWidget);
    expect(find.text('2025-2026-2'), findsWidgets);
    expect(find.text('2024-2025-1'), findsNothing);
    await disposeAcademicPage(tester);
  });

  testWidgets('考试父级仅切换学期也立即隔离进行中的旧查询', (tester) async {
    final pending = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _academicExamResult,
      pendingExam: pending,
    );
    var callbackCount = 0;
    const pageKey = ValueKey('exam-selection-generation');
    final exams = _academicExamResult.snapshot!.exams!;
    final spring = exams.selectedSemester!;
    final fall = exams.semesterOptions.first;

    Widget page(AcademicEamsSemesterOption semester) => YhApp(
      home: AcademicEamsExamDetailPage(
        key: pageKey,
        academicEamsService: service,
        initialResult: _academicExamResult,
        initialSelectedTerm: semester.termChoice,
        initialSelectedSemester: semester,
        onResultChanged: (_, _, _) => callbackCount++,
      ),
    );

    await tester.pumpWidget(page(spring));
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await tester.pump();
    expect(find.text('正在刷新…'), findsOneWidget);

    await tester.pumpWidget(page(fall));
    await tester.pump();
    expect(find.text('刷新安排'), findsOneWidget);

    pending.complete(_academicExamResult);
    await tester.pump();
    await tester.pump();
    expect(callbackCount, 0);
    await disposeAcademicPage(tester);
  });

  testWidgets('过程化成绩新快照移除旧学期时回退到服务有效选项', (tester) async {
    final replacementSemester = AcademicEamsSemesterOption.fromEamsFields(
      id: 'replacement-semester',
      schoolYear: '2026-2027',
      termCode: '1',
    );
    final replacement = _gradeProcessResultWithSemesterOptions(
      options: [replacementSemester],
      selectedSemester: AcademicEamsSemesterOption.fromEamsFields(
        id: 'removed-semester',
        schoolYear: '2024-2025',
        termCode: '1',
      ),
    );
    final service = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      gradeProcessResultResolver: (count) =>
          Future.value(count == 1 ? _gradeProcessResult : replacement),
    );
    final initialSemester =
        _gradeProcessResult.snapshot!.gradeProcess!.selectedSemester!;
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          academicEamsService: service,
          initialTerm: initialSemester.termChoice,
          initialSemester: initialSemester,
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('平时成绩Ⅰ'));

    final refresh = find.byKey(const Key('academic-eams-grade-process-search'));
    await tester.tap(refresh);
    await tester.pump();
    await tester.pump();
    expect(find.text('2026–2027 学年秋季学期'), findsWidgets);
    expect(find.text('2025–2026 学年春季学期'), findsNothing);
    expect(find.text('2024–2025 学年秋季学期'), findsNothing);

    await tester.tap(refresh);
    await tester.pump();
    await tester.pump();
    expect(service.gradeProcessSemesterValues.last?.id, replacementSemester.id);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务证据初次失败展示服务原因且缓存提示使用真实时间', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeDetailPage(
          academicEamsService: _FakeAcademicEamsClient(
            result: _academicDetailFailureResult,
          ),
          initialResult: _academicDetailFailureResult,
          onResultChanged: (_) {},
        ),
      ),
    );
    expect(find.textContaining('教务数据暂不可用'), findsOneWidget);
    expect(find.textContaining('校园网络或 VPN'), findsOneWidget);

    final cached = AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.partialSuccess,
      message: '正在显示成绩缓存',
      detail: '远端更新暂不可用。',
      checkedAt: DateTime(2026, 7, 17, 18),
      entranceUri: _academicEamsResult.entranceUri,
      snapshot: _academicEamsResult.snapshot,
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeDetailPage(
          academicEamsService: _FakeAcademicEamsClient(result: cached),
          initialResult: cached,
          onResultChanged: (_) {},
        ),
      ),
    );
    expect(find.textContaining('07-17 18:00 缓存'), findsOneWidget);
    expect(find.textContaining('昨日缓存'), findsNothing);
    await disposeAcademicPage(tester);
  });

  testWidgets('考试刷新返回的类型选项移除当前值时回退到有效范围', (tester) async {
    final replacement = _academicExamResultWithExamTypes(const {'4': '缓考'});
    final service = _FakeAcademicEamsClient(
      result: replacement,
      examResult: replacement,
    );
    final semester = _academicExamResult.snapshot!.exams!.selectedSemester!;
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: service,
          initialResult: _academicExamResult,
          initialSelectedTerm: semester.termChoice,
          initialSelectedSemester: semester,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );

    final refresh = find.byKey(const Key('academic-eams-exam-detail-search'));
    await tester.tap(refresh);
    await tester.pump();
    await tester.pump();
    expect(service.examTypeValues.single, '1');
    expect(find.text('缓考'), findsWidgets);

    await tester.tap(refresh);
    await tester.pump();
    await tester.pump();
    expect(service.examTypeValues.last, '4');
    await disposeAcademicPage(tester);
  });

  testWidgets('三类教务证据服务抛异常后解除操作锁并保留当前内容', (tester) async {
    Future<AcademicEamsQueryResult> failure() =>
        Future<AcademicEamsQueryResult>.error(StateError('credential expired'));

    final gradePending = Completer<AcademicEamsQueryResult>();
    final gradeService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      pendingGrades: gradePending,
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeDetailPage(
          academicEamsService: gradeService,
          initialResult: _academicEamsResult,
          onResultChanged: (_) {},
        ),
      ),
    );
    await tester.tap(
      find.byKey(const Key('academic-eams-grade-detail-refresh')),
    );
    await tester.pump();
    gradePending.completeError(StateError('credential expired'));
    await tester.pump();
    await tester.pump();
    expect(find.text('刷新成绩'), findsOneWidget);
    expect(find.text('高等数学'), findsWidgets);
    expect(find.textContaining('刷新未完成'), findsOneWidget);

    final semester = _academicExamResult.snapshot!.exams!.selectedSemester!;
    final examPending = Completer<AcademicEamsQueryResult>();
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: _FakeAcademicEamsClient(
            result: _academicExamResult,
            pendingExam: examPending,
          ),
          initialResult: _academicExamResult,
          initialSelectedTerm: semester.termChoice,
          initialSelectedSemester: semester,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await tester.pump();
    examPending.completeError(StateError('credential expired'));
    await tester.pump();
    await tester.pump();
    expect(find.text('刷新安排'), findsOneWidget);
    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(find.textContaining('刷新未完成'), findsOneWidget);

    final processService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      gradeProcessResultResolver: (count) =>
          count == 1 ? Future.value(_gradeProcessResult) : failure(),
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          academicEamsService: processService,
          initialTerm: semester.termChoice,
          initialSemester: semester,
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('平时成绩Ⅰ'));
    await tester.tap(
      find.byKey(const Key('academic-eams-grade-process-search')),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('刷新明细'), findsOneWidget);
    expect(find.text('平时成绩Ⅰ'), findsOneWidget);
    expect(find.textContaining('刷新未完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('三类教务证据页面退出后丢弃 pending 完成与回写', (tester) async {
    final gradePending = Completer<AcademicEamsQueryResult>();
    final examPending = Completer<AcademicEamsQueryResult>();
    final processPending = Completer<AcademicEamsQueryResult>();
    var callbackCount = 0;
    final semester = _academicExamResult.snapshot!.exams!.selectedSemester!;

    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => Column(
            children: [
              YhButton(
                label: '打开成绩证据',
                onTap: () => Navigator.of(context).push(
                  YhPageRoute(
                    builder: (_) => AcademicEamsGradeDetailPage(
                      academicEamsService: _FakeAcademicEamsClient(
                        result: _academicEamsResult,
                        pendingGrades: gradePending,
                      ),
                      initialResult: _academicEamsResult,
                      onResultChanged: (_) => callbackCount++,
                    ),
                  ),
                ),
              ),
              YhButton(
                label: '打开考试证据',
                onTap: () => Navigator.of(context).push(
                  YhPageRoute(
                    builder: (_) => AcademicEamsExamDetailPage(
                      academicEamsService: _FakeAcademicEamsClient(
                        result: _academicExamResult,
                        pendingExam: examPending,
                      ),
                      initialResult: _academicExamResult,
                      initialSelectedTerm: semester.termChoice,
                      initialSelectedSemester: semester,
                      onResultChanged: (_, _, _) => callbackCount++,
                    ),
                  ),
                ),
              ),
              YhButton(
                label: '打开过程证据',
                onTap: () => Navigator.of(context).push(
                  YhPageRoute(
                    builder: (_) => AcademicEamsGradeProcessPage(
                      academicEamsService: _FakeAcademicEamsClient(
                        result: _academicEamsResult,
                        gradeProcessResultResolver: (_) =>
                            processPending.future,
                      ),
                      initialTerm: semester.termChoice,
                      initialSemester: semester,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开成绩证据'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('academic-eams-grade-detail-refresh')),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    gradePending.complete(_academicEamsResult);
    await tester.pump();

    await tester.tap(find.text('打开考试证据'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    examPending.complete(_academicExamResult);
    await tester.pump();

    await tester.tap(find.text('打开过程证据'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    processPending.complete(_gradeProcessResult);
    await tester.pump();

    expect(callbackCount, 0);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('本专科教务考试卡片预览并在详情页切换学期', (tester) async {
    final academicService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      examResultResolver: (term, _) => _academicExamResultForSeason(
        term?.season ?? AcademicTermSeason.spring,
      ),
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: academicService,
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final refresh = find.byKey(const Key('academic-eams-refresh'));
    await tester.ensureVisible(refresh);
    await tester.tap(refresh);
    await pumpUntilFound(tester, find.text('大学生心理健康教育'));

    expect(find.byKey(const Key('academic-eams-exam-card')), findsOneWidget);
    final primaryCard = find.byType(AcademicEamsSummaryCard);
    final examCard = find.byKey(const Key('academic-eams-exam-card'));
    expect(
      find.descendant(of: primaryCard, matching: examCard),
      findsOneWidget,
    );
    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(find.text('高等数学D2'), findsNothing);
    expect(find.text('通用学术英语B'), findsNothing);
    expect(find.textContaining('考试情况尚未发布'), findsNothing);
    expect(find.textContaining('暂无信息'), findsNothing);
    expect(find.textContaining('2026-06-17'), findsOneWidget);
    expect(find.textContaining('4201'), findsWidgets);
    expect(find.textContaining('考试 3场'), findsOneWidget);
    expect(find.textContaining('还有 2 门考试信息'), findsOneWidget);
    expect(
      find.byKey(const Key('academic-eams-exam-year-select')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-select')),
      findsNothing,
    );
    expect(find.textContaining('教务学期'), findsNothing);
    expect(find.textContaining('semester.id'), findsNothing);
    expect(academicService.overviewFetchCount, 1);
    expect(academicService.examFetchCount, 1);

    final detailButton = find.byKey(const Key('academic-eams-exam-detail'));
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('考试安排'), findsWidgets);
    expect(
      find.byKey(const Key('academic-eams-exam-year-select')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-select')),
      findsOneWidget,
    );
    expect(find.text('2025–2026'), findsOneWidget);
    expect(find.text('春季学期'), findsOneWidget);
    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('academic-eams-exam-season-option-fall')),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-option-spring')),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-option-summer')),
      findsWidgets,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('考试时间轴'), findsOneWidget);
    expect(find.text('连续时间正序'), findsOneWidget);
    expect(find.text('考试类型'), findsOneWidget);
    expect(find.text('高等数学D2'), findsOneWidget);
    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(find.text('通用学术英语B'), findsOneWidget);
    expect(find.textContaining('考试情况尚未发布'), findsNothing);
    expect(find.textContaining('暂无信息'), findsNothing);
    expect(find.textContaining('第17周期末考试'), findsWidgets);
    expect(find.byType(Table), findsNothing);
    expect(
      tester.getTopLeft(find.text('大学生心理健康教育').first).dy,
      lessThan(tester.getTopLeft(find.text('高等数学D2')).dy),
      reason: '已排期考试应按时间排在无时间占位记录之前',
    );

    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    final fallOption = find
        .byKey(const Key('academic-eams-exam-season-option-fall'))
        .last;
    await tester.tapAt(tester.getCenter(fallOption));
    await tester.pumpAndSettle();

    expect(academicService.examFetchCount, 1);
    expect(find.text('大学生心理健康教育'), findsOneWidget);
    expect(find.text('程序设计基础'), findsNothing);

    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('程序设计基础'));

    expect(
      academicService.examTermValues.last?.season,
      AcademicTermSeason.fall,
    );
    // 下拉解析出的真实 semester.id 会随查询传入，便于学期接口失败时复用。
    expect(academicService.examSemesterValues.last?.id, '1041');
    expect(find.text('考试课程'), findsOneWidget);
    expect(find.text('已经排期'), findsOneWidget);

    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    final summerOption = find
        .byKey(const Key('academic-eams-exam-season-option-summer'))
        .last;
    await tester.tapAt(tester.getCenter(summerOption));
    await tester.pumpAndSettle();
    expect(academicService.examFetchCount, 2);
    expect(find.text('程序设计基础'), findsOneWidget);

    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('当前学期暂无可展示的考试信息。'));
    expect(
      academicService.examTermValues.last?.season,
      AcademicTermSeason.summer,
    );
    expect(academicService.examSemesterValues.last, isNull);

    await tester.tap(find.byKey(const Key('academic-eams-exam-season-select')));
    await tester.pumpAndSettle();
    final springOption = find
        .byKey(const Key('academic-eams-exam-season-option-spring'))
        .last;
    await tester.tapAt(tester.getCenter(springOption));
    await tester.pumpAndSettle();
    expect(academicService.examFetchCount, 3);
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await pumpUntilFound(tester, find.text('大学生心理健康教育'));
    expect(
      academicService.examTermValues.last?.season,
      AcademicTermSeason.spring,
    );
    expect(academicService.examSemesterValues.last, isNull);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();
    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(find.textContaining('考试 3场'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  test('考试缓存学期与目标学期一致时才作为可展示缓存', () {
    const springTerm = AcademicTermChoice(
      academicYear: 2025,
      season: AcademicTermSeason.spring,
    );
    const fallTerm = AcademicTermChoice(
      academicYear: 2025,
      season: AcademicTermSeason.fall,
    );

    // _academicExamResult 的缓存学期是 2025-2026 春季。
    expect(
      displayableExamCacheForTerm(_academicExamResult, springTerm),
      same(_academicExamResult),
    );
    // 学期不一致（春季缓存 vs 秋季默认）时不展示该缓存，避免标题与记录错位。
    expect(displayableExamCacheForTerm(_academicExamResult, fallTerm), isNull);
    // 明显过期的缓存（2020 秋）对任何近期学期都不展示。
    expect(
      displayableExamCacheForTerm(_staleExamCacheResult, springTerm),
      isNull,
    );
    // 缺省入参时安全返回 null。
    expect(displayableExamCacheForTerm(null, springTerm), isNull);
    expect(displayableExamCacheForTerm(_academicExamResult, null), isNull);
  });

  testWidgets('考试详情页缺少初始快照时解析默认学期并自动读取', (tester) async {
    final academicService = _FakeAcademicEamsClient(
      result: _academicEamsResult,
      examResultResolver: (term, _) =>
          _academicExamResultForSeason(term?.season ?? AcademicTermSeason.fall),
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: academicService,
          academicTermService: _DeferredAcademicTermService(
            Future.value(_academicTermContext(AcademicTermService.defaultTerm)),
          ),
          initialResult: null,
          initialSelectedTerm: null,
          initialSelectedSemester: null,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('程序设计基础'));

    expect(academicService.examFetchCount, 1);
    expect(academicService.examTermValues.last, isNotNull);
    expect(
      academicService.examTermValues.last,
      AcademicTermService.defaultTerm,
    );
    await disposeAcademicPage(tester);
  });

  testWidgets('考试时间轴可本地切换正倒序且不增加远端请求', (tester) async {
    final result = _academicExamResultForSeason(AcademicTermSeason.fall);
    final exams = result.snapshot!.exams!;
    final service = _FakeAcademicEamsClient(result: result, examResult: result);
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: service,
          initialResult: result,
          initialSelectedTerm: exams.selectedSemester!.termChoice,
          initialSelectedSemester: exams.selectedSemester,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );

    expect(find.text('连续时间正序'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('程序设计基础')).dy,
      lessThan(tester.getTopLeft(find.text('大学物理')).dy),
    );

    await tester.tap(find.text('倒序'));
    await tester.pump();
    expect(find.text('连续时间倒序'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('大学物理')).dy,
      lessThan(tester.getTopLeft(find.text('程序设计基础')).dy),
    );
    expect(service.examFetchCount, 0);
    await disposeAcademicPage(tester);
  });

  testWidgets('考试默认学期异步结果在父级换代后不得覆盖新查询', (tester) async {
    final termContext = Completer<AcademicTermContext>();
    final termService = _DeferredAcademicTermService(termContext.future);
    final pending = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _academicExamResult,
      pendingExam: pending,
    );
    const pageKey = ValueKey('exam-default-term-generation');

    Widget page(AcademicTermChoice? term) => YhApp(
      home: AcademicEamsExamDetailPage(
        key: pageKey,
        academicEamsService: service,
        academicTermService: termService,
        initialResult: null,
        initialSelectedTerm: term,
        initialSelectedSemester: null,
        onResultChanged: (_, _, _) {},
      ),
    );

    await tester.pumpWidget(page(null));
    await tester.pump();
    expect(find.text('正在刷新…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
    await tester.pump();
    expect(service.examFetchCount, 0);
    const spring = AcademicTermChoice(
      academicYear: 2026,
      season: AcademicTermSeason.spring,
    );
    await tester.pumpWidget(page(spring));
    await tester.pump();
    expect(service.examFetchCount, 1);
    expect(service.examTermValues.single, spring);

    termContext.complete(_academicTermContext(AcademicTermService.defaultTerm));
    await tester.pump();
    await tester.pump();
    expect(service.examFetchCount, 1);
    expect(service.examTermValues.single, spring);

    pending.complete(_academicExamResult);
    await tester.pump();
    await disposeAcademicPage(tester);
  });

  testWidgets('考试默认学期服务异常时使用安全学期并解除准备锁', (tester) async {
    final service = _FakeAcademicEamsClient(
      result: _academicExamResult,
      examResultResolver: (term, _) =>
          _academicExamResultForSeason(term?.season ?? AcademicTermSeason.fall),
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: service,
          academicTermService: _ThrowingAcademicTermService(),
          initialResult: null,
          initialSelectedTerm: null,
          initialSelectedSemester: null,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('程序设计基础'));

    expect(service.examFetchCount, 1);
    expect(service.examTermValues.single, AcademicTermService.defaultTerm);
    expect(find.text('刷新安排'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('过程化成绩筛选在刷新失败时保持用户可见选择', (tester) async {
    final first = AcademicEamsSemesterOption.fromEamsFields(
      id: 'first',
      schoolYear: '2025-2026',
      termCode: '1',
    );
    final second = AcademicEamsSemesterOption.fromEamsFields(
      id: 'second',
      schoolYear: '2025-2026',
      termCode: '2',
    );
    final content = _gradeProcessResultWithSemesterOptions(
      options: [first, second],
      selectedSemester: first,
    );
    final pending = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: content,
      gradeProcessResultResolver: (count) =>
          count == 1 ? Future.value(content) : pending.future,
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          academicEamsService: service,
          initialTerm: first.termChoice,
          initialSemester: first,
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('平时成绩Ⅰ'));

    await tester.tap(
      find.byKey(const Key('academic-eams-grade-process-semester-select')),
    );
    await tester.pump();
    await tester.tap(
      find
          .byKey(
            const Key('academic-eams-grade-process-semester-option-second'),
          )
          .last,
    );
    await tester.pump();
    expect(find.text('2025–2026 学年春季学期'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('academic-eams-grade-process-search')),
    );
    await tester.pump();
    expect(service.gradeProcessSemesterValues.last?.id, second.id);
    pending.complete(_academicDetailFailureResult);
    await tester.pump();
    await tester.pump();
    expect(find.text('2025–2026 学年春季学期'), findsWidgets);
    await disposeAcademicPage(tester);
  });
}
