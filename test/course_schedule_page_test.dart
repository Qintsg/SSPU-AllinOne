/*
 * 课程表页面测试 — 校验独立课表页展示、自动刷新与错误状态
 * @Project : SSPU-AllinOne
 * @File : course_schedule_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/course_period.dart';
import 'package:sspu_allinone/pages/course_schedule_page.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/utils/course_week_parser.dart';

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> disposeCourseSchedulePage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> pumpCourseSchedulePage(
  WidgetTester tester, {
  required AcademicEamsClient academicEamsService,
  AcademicEamsQueryResult? initialResult,
  bool autoRefreshEnabledOverride = false,
  int autoRefreshIntervalOverride = 30,
  AcademicCalendarClient? academicCalendarService,
}) async {
  await tester.pumpWidget(
    FluentApp(
      home: CourseSchedulePage(
        academicEamsService: academicEamsService,
        initialResult: initialResult,
        autoRefreshEnabledOverride: autoRefreshEnabledOverride,
        autoRefreshIntervalOverride: autoRefreshIntervalOverride,
        academicCalendarService: academicCalendarService,
      ),
    ),
  );
}

void main() {
  test('内置作息时间表包含教务处 1-13 节数据', () {
    const table = CoursePeriodTable.standard;

    expect(table.periods.length, 13);
    expect(table.periodOf(1)?.timeRange, '08:00-08:45');
    expect(table.periodOf(5)?.timeRange, '11:25-12:10');
    expect(table.periodOf(13)?.timeRange, '19:40-20:25');
    expect(table.rangeText(1, 2), '08:00-09:35');
  });

  test('课程周次解析支持区间、单双周、枚举和异常文本', () {
    expect(CourseWeekParser.parse('1-16周').contains(16), isTrue);
    expect(CourseWeekParser.parse('1-16周 单周').contains(2), isFalse);
    expect(CourseWeekParser.parse('1-16周 双周').contains(2), isTrue);
    expect(CourseWeekParser.parse('1,3,5周').weeks, {1, 3, 5});
    expect(CourseWeekParser.parse('第 1-4 周, 7周').weeks, {1, 2, 3, 4, 7});
    expect(CourseWeekParser.parse('周次待定').showWhenUnknown, isTrue);
  });

  testWidgets('课程表页面自动刷新开启时会主动读取课表', (tester) async {
    final service = _FakeAcademicEamsClient(result: _successResult);
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      autoRefreshEnabledOverride: true,
      autoRefreshIntervalOverride: 1,
    );

    await pumpUntilFound(tester, find.text('高等数学'));

    expect(find.text('课程表'), findsOneWidget);
    expect(find.text('课程表说明'), findsNothing);
    expect(find.text('本学期概览'), findsOneWidget);
    expect(find.text('2025-2026 第2学期'), findsOneWidget);
    expect(find.textContaining('自动刷新每 1 分钟运行一次'), findsOneWidget);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.text('周一'), findsOneWidget);
    expect(find.textContaining('08:00-09:35'), findsOneWidget);
    expect(find.text('返回'), findsNothing);
    expect(service.courseTableFetchCount, 1);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(service.courseTableFetchCount, 2);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表页面展示缺少 OA 密码提示', (tester) async {
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _missingPassword),
      autoRefreshEnabledOverride: false,
    );

    await tester.tap(find.byKey(const Key('course-schedule-refresh')));
    await tester.pumpAndSettle();

    expect(find.text('请先保存 OA 账号密码'), findsOneWidget);
    expect(find.textContaining('刷新 OA/CAS 会话'), findsOneWidget);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表页面优先使用可用缓存覆盖无课表初始结果', (tester) async {
    final service = _FakeAcademicEamsClient(
      result: _missingPassword,
      cachedResult: _successResult,
    );
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _missingPassword,
      autoRefreshEnabledOverride: false,
    );

    await pumpUntilFound(tester, find.text('高等数学'));

    expect(find.text('高等数学'), findsOneWidget);
    expect(find.text('请先保存 OA 账号密码'), findsNothing);
    expect(service.cachedCourseTableReadCount, 1);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表页面作为二级页面打开时显示返回按钮', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        home: Navigator(
          onGenerateRoute: (_) =>
              FluentPageRoute(builder: (_) => const SizedBox.shrink()),
        ),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => CourseSchedulePage(
          academicEamsService: _FakeAcademicEamsClient(result: _successResult),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('返回'), findsOneWidget);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表页面显示校历入口并可进入校历页', (tester) async {
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _successResult),
      academicCalendarService: _FakeAcademicCalendarClient(
        entries: [_calendarEntry()],
      ),
    );

    await tester.tap(find.byKey(const Key('open-academic-calendar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await pumpUntilFound(tester, find.text('2025-2026学年'));

    expect(find.text('校历'), findsWidgets);
    expect(find.text('2025-2026学年'), findsWidgets);
    expect(find.text('外部打开'), findsOneWidget);
    expect(find.text('秋季学期'), findsNothing);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表概览隐藏无效培养计划并在窄屏自适应', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _successResultWithEmptyProgramCompletion,
      ),
      initialResult: _successResultWithEmptyProgramCompletion,
      autoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(tester, find.text('高等数学'));

    expect(find.text('课程表说明'), findsNothing);
    expect(find.text('2025-2026 学年春季学期（按校历推断）'), findsOneWidget);
    expect(find.textContaining('培养计划'), findsNothing);
    expect(find.textContaining('0.0/0.0'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeCourseSchedulePage(tester);
  });
}

class _FakeAcademicEamsClient implements AcademicEamsClient {
  _FakeAcademicEamsClient({required this.result, this.cachedResult});

  final AcademicEamsQueryResult result;
  final AcademicEamsQueryResult? cachedResult;
  int courseTableFetchCount = 0;
  int cachedCourseTableReadCount = 0;

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedCourseTable() async {
    cachedCourseTableReadCount++;
    return cachedResult;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedOverview() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedExamSchedule() async {
    return null;
  }

  @override
  Future<AcademicEamsProfile?> readCachedStudentProfile() async {
    return null;
  }

  @override
  Future<AcademicEamsProfile?> refreshStudentProfileIfIncomplete({
    bool forceRefresh = false,
  }) async {
    return result.snapshot?.profile;
  }

  @override
  Future<AcademicEamsQueryResult> fetchCourseTable({
    bool requireCampusNetwork = true,
  }) async {
    courseTableFetchCount++;
    return result;
  }

  @override
  Future<AcademicEamsQueryResult> fetchOverview({
    bool requireCampusNetwork = true,
  }) async {
    return result;
  }

  @override
  Future<AcademicEamsQueryResult> fetchExamSchedule({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    String? examTypeId,
    bool requireCampusNetwork = true,
  }) async {
    return result;
  }
}

class _FakeAcademicCalendarClient implements AcademicCalendarClient {
  _FakeAcademicCalendarClient({required this.entries});

  final List<AcademicCalendarCacheEntry> entries;

  @override
  Future<AcademicCalendarSyncResult> ensureCalendarsForDate({
    DateTime? now,
  }) async {
    return AcademicCalendarSyncResult(
      entries: entries,
      loadedFromCache: entries.isNotEmpty,
      refreshed: false,
    );
  }

  @override
  Future<AcademicCalendarSyncResult> ensureCalendarsForViewer({
    DateTime? now,
  }) async {
    return AcademicCalendarSyncResult(
      entries: entries,
      loadedFromCache: entries.isNotEmpty,
      refreshed: false,
    );
  }

  @override
  Future<List<AcademicCalendarCacheEntry>> readCachedCalendars() async {
    return entries;
  }

  @override
  Future<List<AcademicTermDefinition>> readCachedTermDefinitions() async {
    return AcademicCalendarService.termDefinitionsFromEntries(entries);
  }

  @override
  Future<AcademicCalendarCacheEntry?> readCachedCalendar(int schoolYear) async {
    for (final entry in entries) {
      if (entry.schoolYearStart == schoolYear) return entry;
    }
    return null;
  }

  @override
  Future<List<AcademicCalendarCacheEntry>> refreshCalendars({
    List<int>? targetYears,
  }) async {
    return entries;
  }
}

AcademicCalendarCacheEntry _calendarEntry() {
  final schedule = AcademicCalendarTermSchedule(
    schoolYearStart: 2025,
    fallStart: DateTime(2025, 9, 22),
    fallEnd: DateTime(2026, 1, 18),
    springStart: DateTime(2026, 3, 2),
    springEnd: DateTime(2026, 6, 28),
    summerStart: DateTime(2026, 6, 29),
    summerEnd: DateTime(2026, 9, 20),
    summerSegments: [
      AcademicTermTeachingSegment(
        startDate: DateTime(2026, 6, 29),
        endDate: DateTime(2026, 7, 12),
        startWeek: 1,
        endWeek: 2,
      ),
      AcademicTermTeachingSegment(
        startDate: DateTime(2026, 8, 31),
        endDate: DateTime(2026, 9, 20),
        startWeek: 3,
        endWeek: 5,
      ),
    ],
    dayTags: [
      AcademicCalendarDayTag(
        date: DateTime(2025, 11, 7),
        type: AcademicCalendarDayTagType.sportsDay,
        label: '校运会停课一天',
        sourceText: '校运会：11月7日（周五）停课一天',
      ),
    ],
    pendingHolidayNotices: const [
      AcademicCalendarPendingHolidayNotice(sourceText: '国庆节、元旦放假安排另行通知'),
    ],
    parseWarnings: const [],
  );
  return AcademicCalendarCacheEntry(
    schoolYearStart: 2025,
    title: '2025-2026学年校历',
    detailUrl: 'https://jwc.sspu.edu.cn/detail.htm',
    publishDate: '2025-04-24',
    pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
    imageUrls: const [],
    sourceType: AcademicCalendarSourceType.pdf,
    fetchedAt: DateTime(2026),
    parseVersion: AcademicCalendarService.parseVersion,
    pdfFilePath: null,
    rawTextFilePath: null,
    rawExtractedText: null,
    schedule: schedule,
    warnings: const [],
    errorMessage: null,
  );
}

final AcademicEamsQueryResult _successResult = AcademicEamsQueryResult(
  status: AcademicEamsQueryStatus.success,
  message: '本专科教务只读查询成功',
  detail: '已读取当前学期课表。',
  checkedAt: DateTime(2026, 5, 2, 10, 0),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
  ),
  snapshot: AcademicEamsSnapshot(
    fetchedAt: DateTime(2026, 5, 2, 10, 0),
    sourceUri: Uri.parse(
      'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
    ),
    warnings: const [],
    hasCourseOfferingEntry: true,
    hasFreeClassroomEntry: true,
    profile: const AcademicEamsProfile(
      name: '张三',
      studentId: '20260001',
      department: '计算机与信息工程学院',
      major: '软件工程',
      className: '软件 241',
      gender: '男',
      studyLength: '4 年',
      educationLevel: '本科',
      rawFields: {'姓名': '张三'},
    ),
    courseTable: AcademicCourseTableSnapshot(
      termName: '2025-2026 第2学期',
      entries: const [
        AcademicCourseTableEntry(
          courseName: '高等数学',
          weekday: 1,
          startUnit: 1,
          endUnit: 2,
          timeText: '周一 第1-2节',
          teacher: '张老师',
          location: '综合楼 A101',
          weekDescription: '1-16周',
          rawText: '高等数学 张老师 综合楼 A101 1-16周',
        ),
      ],
      fetchedAt: DateTime(2026, 5, 2, 10, 0),
      sourceUri: Uri.parse(
        'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
      ),
    ),
  ),
);

final AcademicEamsQueryResult _successResultWithEmptyProgramCompletion =
    AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.success,
      message: '本专科教务只读查询成功',
      detail: '已读取当前学期课表。',
      checkedAt: DateTime(2026, 5, 2, 10, 0),
      entranceUri: Uri.parse(
        'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
      ),
      snapshot: AcademicEamsSnapshot(
        fetchedAt: DateTime(2026, 5, 2, 10, 0),
        sourceUri: Uri.parse(
          'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
        ),
        warnings: const [],
        hasCourseOfferingEntry: true,
        hasFreeClassroomEntry: true,
        profile: _successResult.snapshot!.profile,
        courseTable: AcademicCourseTableSnapshot(
          entries: _successResult.snapshot!.courseTable!.entries,
          fetchedAt: DateTime(2026, 5, 2, 10, 0),
          sourceUri: Uri.parse(
            'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
          ),
        ),
        programCompletion: const AcademicProgramCompletionSnapshot(
          completedCourseCount: 0,
          pendingCourseCount: 0,
          completedCredits: 0,
          pendingCredits: 0,
          moduleProgress: [],
        ),
      ),
    );

final AcademicEamsQueryResult _missingPassword = AcademicEamsQueryResult(
  status: AcademicEamsQueryStatus.missingOaPassword,
  message: '请先保存 OA 账号密码',
  detail: '本专科教务查询需要在登录态失效时刷新 OA/CAS 会话。',
  checkedAt: DateTime(2026, 5, 2, 10, 0),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
  ),
);
