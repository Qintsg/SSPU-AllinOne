/*
 * 成绩考试与过程化证据回归测试
 * @Project : SSPU-AllinOne
 * @File : academic_page_test_evidence.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'academic_page_test.dart';

/// 注册成绩考试与过程化证据测试。
///
/// :returns: 无返回值。
void _registerAcademicEvidenceTests() {
  testWidgets('教务中心展示本专科教务摘要并可进入课程表页', (tester) async {
    await pumpAcademicPage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _academicEamsResult),
      sportsAttendanceService: _FakeSportsAttendanceClient(
        result: _successResult,
      ),
      studentReportService: _FakeStudentReportClient(result: _creditResult),
    );

    final legacyRefresh = find.byKey(
      const ValueKey('academic-overview-refresh'),
    );
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

    final refresh = find.byKey(const ValueKey('academic-overview-refresh'));
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

  testWidgets('教务详情失败状态按内容收束到表单内容宽度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pumpAndSettle();

    final stateTitle = find.text('课程成绩暂不可用');
    final stateCard = find.ancestor(
      of: stateTitle,
      matching: find.byType(YhCard),
    );
    final theme = tester.element(stateTitle).yhTheme;
    expect(stateCard, findsOneWidget);
    expect(tester.getSize(stateCard).width, theme.layout.formContentWidth);
    expect(
      tester.getSize(stateCard).height,
      lessThan(theme.control.regular * 8),
    );
    final gradeFilterCard = find.ancestor(
      of: find.byKey(const Key('academic-eams-grade-term-select')),
      matching: find.byType(YhCard),
    );
    expect(gradeFilterCard, findsOneWidget);
    expect(
      tester.getSize(gradeFilterCard).width,
      lessThan(theme.layout.pageContentWidth / 2),
    );
    expect(find.text('检查后重试'), findsOneWidget);
    await disposeAcademicPage(tester);
  });

  testWidgets('考试详情窄屏错误状态紧凑呈现恢复账本且可重试', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final semester = _academicExamResult.snapshot!.exams!.selectedSemester!;
    final service = _FakeAcademicEamsClient(
      result: _academicDetailFailureResult,
    );
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsExamDetailPage(
          academicEamsService: service,
          initialResult: _academicDetailFailureResult,
          initialSelectedTerm: semester.termChoice,
          initialSelectedSemester: semester,
          onResultChanged: (_, _, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('考试安排暂不可用');
    final stateCard = find.ancestor(of: title, matching: find.byType(YhCard));
    final action = find.ancestor(
      of: find.text('检查后重试'),
      matching: find.byType(YhButton),
    );
    final theme = tester.element(title).yhTheme;
    expect(stateCard, findsOneWidget);
    expect(
      tester.getSize(stateCard).height,
      lessThan(theme.control.minimumTarget * 5),
    );
    expect(
      tester.getSize(action).height,
      greaterThanOrEqualTo(theme.control.minimumTarget),
    );
    expect(
      tester.getTopLeft(action).dy,
      greaterThan(tester.getTopLeft(title).dy),
    );

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(service.examFetchCount, 1);
    expect(tester.takeException(), isNull);
    await disposeAcademicPage(tester);
  });

  testWidgets('过程化成绩宽屏单筛选字段不再套用外层卡片', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semester =
        _gradeProcessResult.snapshot!.gradeProcess!.selectedSemester!;
    await tester.pumpWidget(
      YhApp(
        home: AcademicEamsGradeProcessPage(
          academicEamsService: _FakeAcademicEamsClient(
            result: _academicEamsResult,
            gradeProcessResultResolver: (_) async => _gradeProcessResult,
          ),
          initialTerm: semester.termChoice,
          initialSemester: semester,
        ),
      ),
    );
    final select = find.byKey(
      const Key('academic-eams-grade-process-semester-select'),
    );
    await pumpUntilFound(tester, select);

    expect(
      find.ancestor(of: select, matching: find.byType(YhCard)),
      findsNothing,
    );
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
}
