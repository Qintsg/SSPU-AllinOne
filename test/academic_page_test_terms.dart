/*
 * 学期换代与尾部证据回归测试
 * @Project : SSPU-AllinOne
 * @File : academic_page_test_terms.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page_test.dart';

/// 注册学期换代与尾部证据测试。
///
/// :returns: 无返回值。
void _registerAcademicTermsTests() {
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

    final refresh = find.byKey(const ValueKey('academic-overview-refresh'));
    await tester.ensureVisible(refresh);
    await tester.tap(refresh);
    await pumpUntilFound(tester, find.text('大学生心理健康教育'));

    expect(find.byKey(const Key('academic-eams-exam-card')), findsNothing);
    expect(find.byType(AcademicEamsSummaryCard), findsNothing);
    expect(find.text('大学生心理健康教育'), findsWidgets);
    expect(
      find.byKey(const Key('academic-eams-exam-year-select')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('academic-eams-exam-season-select')),
      findsNothing,
    );
    expect(academicService.overviewFetchCount, 1);
    expect(academicService.examFetchCount, 1);

    expect(find.byKey(const Key('academic-eams-exam-detail')), findsNothing);
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
