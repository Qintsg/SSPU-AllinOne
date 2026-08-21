/*
 * 体育与第二课堂详情回归测试
 * @Project : SSPU-AllinOne
 * @File : academic_page_test_life.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page_test.dart';

/// 注册体育与第二课堂详情测试。
///
/// :returns: 无返回值。
void _registerAcademicLifeTests() {
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
}
