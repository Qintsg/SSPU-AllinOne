/*
 * 教务总览布局与入口回归测试
 * @Project : SSPU-AllinOne
 * @File : academic_page_test_layout.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page_test.dart';

/// 注册教务总览布局与入口测试。
///
/// :returns: 无返回值。
void _registerAcademicLayoutTests() {
  testWidgets('教务总览窄屏使用精简标题且不溢出', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
        cachedExamResult: _academicExamResult,
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
    final shortTitle = find.text('教务中心');
    await pumpUntilFound(tester, shortTitle);
    expect(shortTitle, findsOneWidget);
    expect(MediaQuery.sizeOf(tester.element(shortTitle)).width, 360);

    expect(find.text('教务中心'), findsOneWidget);
    expect(find.text('学习进度，一处看全。'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务总览宽屏删除完成度和学习档案卡片', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
        cachedExamResult: _academicExamResult,
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
    await pumpUntilFound(tester, find.text('教务中心'));
    expect(find.text('完成度'), findsNothing);
    expect(find.text('学习档案'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务总览将详细数据源作为连续页内分区', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
        cachedExamResult: _academicExamResult,
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
    final sourceJump = find.byKey(
      const ValueKey('academic-overview-detailed-sources'),
    );
    final sourceHeading = find.text('详细数据源');
    await pumpUntilFound(tester, find.text('课外活动考勤'));

    expect(sourceJump, findsNothing);
    expect(sourceHeading, findsNothing);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务总览凭据不足状态在宽屏按内容收束', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final missingCredentials = AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.missingOaAccount,
      message: '请先保存学工号（OA账号）',
      detail: '当前不会访问校园服务。',
      checkedAt: DateTime(2026, 7, 18, 9),
      entranceUri: Uri.parse('https://oa.example.invalid/academic'),
    );
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: missingCredentials,
        cachedOverviewResult: missingCredentials,
      ),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
      credentialsStatusOverride: const AcademicCredentialsStatus.empty(),
      onOpenAccountConnections: () {},
    );
    final title = find.text('需要先完成教务账户连接');
    await pumpUntilFound(tester, title);

    final stateCard = find.ancestor(of: title, matching: find.byType(YhCard));
    expect(stateCard, findsOneWidget);
    expect(tester.getSize(stateCard).width, lessThanOrEqualTo(560));
    expect(tester.getSize(stateCard).height, lessThan(320));
    expect(find.text('前往账户与连接'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('教务总览窄屏将指标收束为二乘二布局', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _academicEamsResult,
        cachedOverviewResult: _academicEamsResult,
        cachedExamResult: _academicExamResult,
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
    await pumpUntilFound(tester, find.text('平均绩点'));

    final labels = [find.text('平均绩点'), find.text('已获学分'), find.text('已读成绩')];
    final labelTops = [for (final label in labels) tester.getTopLeft(label).dy];
    expect(labelTops[1], greaterThan(labelTops[0]));
    expect(labelTops[2], closeTo(labelTops[1], 2));
    final overviewCard = find.ancestor(
      of: find.text('教务中心'),
      matching: find.byType(YhCard),
    );
    expect(overviewCard, findsOneWidget);
    expect(tester.getSize(overviewCard).height, lessThan(520));
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
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
    expect(find.text('OA 数据部分读取'), findsNothing);
    expect(find.text('OA 状态未校验'), findsNothing);
    expect(find.text('正在显示昨日教务缓存：网络恢复后可手动刷新。'), findsNothing);
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
    final sportsRefresh = find.byKey(
      const ValueKey('academic-overview-refresh'),
    );
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
    expect(sportsService.requireCampusNetworkValues, [true]);

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

    final sportsRefresh = find.byKey(
      const ValueKey('academic-overview-refresh'),
    );
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('教务数据部分更新'));

    expect(find.text('教务数据部分更新'), findsOneWidget);
    expect(find.textContaining('体育考勤未完成'), findsWidgets);
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

    final sportsRefresh = find.byKey(
      const ValueKey('academic-overview-refresh'),
    );
    await tester.ensureVisible(sportsRefresh);
    await tester.tap(sportsRefresh);
    await pumpUntilFound(tester, find.text('教务数据部分更新'));

    expect(find.textContaining('体育考勤未完成'), findsWidgets);
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
      const ValueKey('academic-overview-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('总已获分数'));

    expect(find.text('教务数据已刷新'), findsOneWidget);
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
    final titleLeft = tester.getTopLeft(find.text('第二课堂学分')).dx;
    final lastRefreshLeft = tester
        .getTopLeft(find.text('上次刷新：2026-05-01 00:00'))
        .dx;
    expect(lastRefreshCenter.dy, greaterThan(titleCenter.dy));
    expect((lastRefreshLeft - titleLeft).abs(), lessThan(1));
    expect(
      lastRefreshCenter.dy,
      lessThan(tester.getTopLeft(find.text('总已获分数')).dy),
    );

    await tester.pump(const Duration(seconds: 4));
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
    expect(find.text('第二课堂积分规则'), findsOneWidget);
    expect(find.text('完成差额'), findsOneWidget);
    expect(find.text('报告与讲座'), findsWidgets);
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

  testWidgets('第二课堂统一刷新失败时显示聚合来源原因', (tester) async {
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
      const ValueKey('academic-overview-refresh'),
    );
    await tester.ensureVisible(studentReportRefresh);
    await tester.tap(studentReportRefresh);
    await pumpUntilFound(tester, find.text('教务数据部分更新'));

    expect(find.textContaining('第二课堂未完成'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('教务数据部分更新'), findsNothing);
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
      const ValueKey('academic-overview-refresh'),
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
    expect(find.text('第二课堂积分规则'), findsOneWidget);
    expect(find.text('完成差额'), findsOneWidget);
    expect(find.text('计分类别'), findsWidgets);
    expect(find.text('志愿服务'), findsWidgets);
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

    final sportsRefresh = find.byKey(
      const ValueKey('academic-overview-refresh'),
    );
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
      const ValueKey('academic-overview-refresh'),
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
    expect(sportsSize.height, greaterThan(0));
    expect(studentReportSize.height, greaterThan(0));
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
    expect(sportsSize.height, greaterThan(0));
    expect(studentReportSize.height, greaterThan(0));
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
}
