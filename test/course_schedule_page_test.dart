/*
 * 课程表页面测试 — 校验独立课表页展示、自动刷新与错误状态
 * @Project : SSPU-AllinOne
 * @File : course_schedule_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/course_period.dart';
import 'package:sspu_allinone/pages/course_schedule_page.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/data_module_preferences.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import 'support/responsive_test_sizes.dart';
import 'package:sspu_allinone/utils/course_week_parser.dart';

/// 推进测试时钟直到目标组件出现或达到尝试上限。
///
/// :param tester: 当前组件测试器。
/// :param finder: 等待出现的目标组件。
/// :returns: 等待流程结束时完成。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 销毁课程表页面并释放定时器。
///
/// :param tester: 当前组件测试器。
/// :returns: 页面销毁流程结束时完成。
Future<void> disposeCourseSchedulePage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
}

/// 构建课程表测试页面。
///
/// :param tester: 当前组件测试器。
/// :param academicEamsService: 测试用教务客户端。
/// :param initialResult: 可选初始课表快照。
/// :param autoRefreshEnabledOverride: 自动刷新开关覆盖值。
/// :param autoRefreshIntervalOverride: 自动刷新间隔覆盖值；为空时读取共享偏好。
/// :param nowOverride: 可选确定性时钟。
/// :param academicCalendarService: 可选校历客户端。
/// :returns: 页面完成首帧构建时结束。
Future<void> pumpCourseSchedulePage(
  WidgetTester tester, {
  required AcademicEamsClient academicEamsService,
  AcademicEamsQueryResult? initialResult,
  bool autoRefreshEnabledOverride = false,
  bool? fetchEnabledOverride = true,
  int? autoRefreshIntervalOverride = 30,
  DateTime? nowOverride,
  AcademicCalendarClient? academicCalendarService,
}) async {
  await tester.pumpWidget(
    YhApp(
      home: CourseSchedulePage(
        academicEamsService: academicEamsService,
        initialResult: initialResult,
        autoRefreshEnabledOverride: autoRefreshEnabledOverride,
        fetchEnabledOverride: fetchEnabledOverride,
        autoRefreshIntervalOverride: autoRefreshIntervalOverride,
        nowOverride: nowOverride,
        academicCalendarService: academicCalendarService,
      ),
    ),
  );
}

/// 注册课程表功能、刷新与布局测试。
///
/// :returns: 无返回值。
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
    expect(find.text('2025–2026 第2学期'), findsOneWidget);
    expect(find.text('1 门课程'), findsOneWidget);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.text('周一'), findsWidgets);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('返回'), findsNothing);
    expect(service.courseTableFetchCount, 1);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(service.courseTableFetchCount, 2);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('夏季课表刷新将学期上下文传给考试聚合查询', (tester) async {
    final summerResult = _resultWithCourseTerm(
      _successResult,
      '2025-2026 第3学期',
    );
    final service = _FakeAcademicEamsClient(result: summerResult);

    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      autoRefreshEnabledOverride: true,
      nowOverride: DateTime(2026, 7, 1),
    );
    await pumpUntilFound(tester, find.text('高等数学'));

    expect(service.examFetchTerms, [
      const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.summer,
      ),
    ]);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('页面停留期间共享刷新时长变化会重启课表定时器', (tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(() {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
    });
    await AcademicEamsService.instance.setAutoRefreshIntervalMinutes(60);
    final service = _FakeAcademicEamsClient(result: _successResult);
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      autoRefreshEnabledOverride: true,
      autoRefreshIntervalOverride: null,
      nowOverride: DateTime(2026, 5, 4),
    );
    await pumpUntilFound(tester, find.text('高等数学'));
    expect(service.courseTableFetchCount, 1);

    await AcademicEamsService.instance.setAutoRefreshIntervalMinutes(1);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(service.courseTableFetchCount, 2);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('页面停留期间停止教务获取会立即取消课表定时刷新', (tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    addTearDown(() {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
    });
    final service = _FakeAcademicEamsClient(result: _successResult);
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      autoRefreshEnabledOverride: true,
      fetchEnabledOverride: null,
      autoRefreshIntervalOverride: 1,
    );
    await pumpUntilFound(tester, find.text('高等数学'));
    expect(service.courseTableFetchCount, 1);

    await DataModulePreferences.instance.setFetchEnabled(
      CampusDataModule.academicEams,
      false,
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(service.courseTableFetchCount, 1);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表原地刷新单飞且失败保留星期选择与当前课程', (tester) async {
    final completion = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _missingPassword,
      pendingCourseTable: completion,
    );
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _successResult,
      nowOverride: DateTime(2026, 5, 4),
    );
    await tester.pump();

    final refresh = find.byKey(const Key('course-schedule-refresh'));
    await tester.tap(refresh);
    await tester.pump();
    await tester.tap(refresh);
    await tester.pump();

    expect(service.courseTableFetchCount, 1);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.byKey(const Key('course-week-block-1-1-高等数学')), findsOneWidget);
    expect(find.byKey(const Key('course-week-header-1')), findsOneWidget);

    completion.complete(_missingPassword);
    await tester.pump();
    await tester.pump();

    expect(find.text('高等数学'), findsOneWidget);
    expect(find.textContaining('请先保存 OA 账号密码'), findsOneWidget);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表操作锁期间保留内容且重复行动不产生第二个请求', (tester) async {
    final completion = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _successResult,
      pendingCourseTable: completion,
    );
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _successResult,
      nowOverride: DateTime(2026, 5, 4),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('course-schedule-refresh')));
    await tester.pump();

    expect(find.bySemanticsLabel('正在刷新课程表'), findsOneWidget);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.textContaining('星期选择和校历入口保持可用'), findsOneWidget);
    expect(find.byKey(const Key('course-week-block-1-1-高等数学')), findsOneWidget);

    await tester.tap(find.byKey(const Key('course-schedule-refresh')));
    await tester.pump();
    expect(service.courseTableFetchCount, 1);

    completion.complete(_successResult);
    await tester.pump();
    await tester.pump();
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表凭据换代立即解除刷新且旧结果不得回写', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final completion = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _successResult,
      pendingCourseTable: completion,
    );
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _successResult,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('course-schedule-refresh')));
    await tester.pump();
    expect(find.text('高等数学'), findsOneWidget);

    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260002',
      oaPassword: 'new-password',
      sportsQueryPassword: 'new-sports-password',
    );
    await tester.pump();
    expect(find.text('高等数学'), findsNothing);

    completion.complete(_successResult);
    await tester.pump();
    await tester.pump();

    expect(find.text('高等数学'), findsNothing);
    expect(find.text('准备读取课程表'), findsOneWidget);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表凭据换代后迟到的旧缓存不得重新进入页面', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final cachedCompletion = Completer<AcademicEamsQueryResult?>();
    final service = _FakeAcademicEamsClient(
      result: _successResult,
      pendingCachedCourseTable: cachedCompletion,
    );
    await pumpCourseSchedulePage(tester, academicEamsService: service);
    await tester.pump();

    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260003',
      oaPassword: 'replacement-password',
    );
    await tester.pump();

    cachedCompletion.complete(_successResult);
    await tester.pump();
    await tester.pump();

    expect(find.text('高等数学'), findsNothing);
    expect(find.text('准备读取课程表'), findsOneWidget);
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
      YhApp(
        home: Navigator(
          onGenerateRoute: (_) =>
              YhPageRoute(builder: (_) => const SizedBox.shrink()),
        ),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    Navigator.of(context).push(
      YhPageRoute(
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
    await pumpUntilFound(tester, find.text('2025–2026 学年'));

    expect(find.text('校历'), findsWidgets);
    expect(find.text('2025–2026 学年'), findsWidgets);
    expect(find.bySemanticsLabel('外部打开校历 PDF'), findsOneWidget);
    expect(find.text('秋季学期'), findsNothing);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表紧凑端仍保留可触达的校历与文字刷新行动', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _successResult),
      initialResult: _successResult,
    );
    await tester.pump();

    expect(find.byKey(const Key('open-academic-calendar')), findsOneWidget);
    expect(find.bySemanticsLabel('刷新课程表'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('1084x706 桌面周课表可滚动访问第 13 节且无底部溢出', (tester) async {
    await setResponsiveTestViewport(tester, courseOverflowRegressionViewport);
    addTearDown(() => resetResponsiveTestViewport(tester));
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _successResult),
      initialResult: _successResult,
      nowOverride: DateTime(2026, 5, 4),
    );
    await tester.pump();

    final finalPeriod = find.byKey(const Key('course-period-13'));
    expect(finalPeriod, findsOneWidget);
    await tester.scrollUntilVisible(
      finalPeriod,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getBottomLeft(finalPeriod).dy,
      lessThanOrEqualTo(courseOverflowRegressionViewport.height),
    );
    expect(tester.takeException(), isNull);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表页头推断缺失学期并在窄屏自适应', (tester) async {
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
    expect(find.textContaining('周视图在桌面保持七天空间关系'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表可通过固定时钟锁定移动端当日选中态', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _successResult),
      initialResult: _successResult,
      nowOverride: DateTime(2026, 5, 4),
    );
    await pumpUntilFound(tester, find.text('高等数学'));

    expect(
      find.byWidgetPredicate(
        (widget) => widget is YhTabs<int> && widget.value == 1,
      ),
      findsOneWidget,
    );
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表紧凑端日期带完整展示七天并保留完整语义', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(result: _successResult),
      initialResult: _successResult,
      nowOverride: DateTime(2026, 5, 9),
    );
    await pumpUntilFound(tester, find.text('高等数学'));

    for (final label in const ['周一', '周二', '周三', '周四', '周五', '今天', '周日']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byType(YhTabs<int>),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    for (final semanticLabel in const [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六，今天',
      '周日',
    ]) {
      final target = find.byWidgetPredicate(
        (widget) =>
            widget is YhPressable && widget.semanticLabel == semanticLabel,
      );
      expect(target, findsOneWidget);
      expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    }

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is YhPressable && widget.semanticLabel == '周日',
      ),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is YhTabs<int> && widget.value == 7,
      ),
      findsOneWidget,
    );
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表在成功返回空记录时展示明确空态', (tester) async {
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        result: _successResultWithEmptyCourseTable,
      ),
      initialResult: _successResultWithEmptyCourseTable,
    );
    await tester.pump();

    expect(find.text('本学期暂无课程'), findsOneWidget);
    expect(find.textContaining('刚完成选课时'), findsOneWidget);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表空态可在原位置重新读取并恢复课程', (tester) async {
    final service = _FakeAcademicEamsClient(result: _successResult);
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _successResultWithEmptyCourseTable,
      nowOverride: DateTime(2026, 5, 4),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('schedule-state-primary')));
    await tester.pumpAndSettle();

    expect(service.courseTableFetchCount, 1);
    expect(find.text('高等数学'), findsOneWidget);
    expect(find.text('本学期暂无课程'), findsNothing);
    await disposeCourseSchedulePage(tester);
  });

  testWidgets('课程表页面退出后忽略尚未完成的读取结果', (tester) async {
    final completion = Completer<AcademicEamsQueryResult>();
    final service = _FakeAcademicEamsClient(
      result: _successResult,
      pendingCourseTable: completion,
    );
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _successResult,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('course-schedule-refresh')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    completion.complete(_successResult);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('课程与考试日历可切换本周和整学期议程', (tester) async {
    final service = _FakeAcademicEamsClient(result: _successResultWithExam);
    await pumpCourseSchedulePage(
      tester,
      academicEamsService: service,
      initialResult: _successResultWithExam,
      nowOverride: DateTime(2026, 5, 4, 9),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('课程与考试'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('academic-integrated-agenda')), findsOneWidget);
    expect(find.text('考试：高等数学'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);
    expect(find.text('整学期'), findsOneWidget);
    await disposeCourseSchedulePage(tester);
  });
}

class _FakeAcademicEamsClient implements AcademicEamsClient {
  _FakeAcademicEamsClient({
    required this.result,
    this.cachedResult,
    this.pendingCourseTable,
    this.pendingCachedCourseTable,
  });

  final AcademicEamsQueryResult result;
  final AcademicEamsQueryResult? cachedResult;
  final Completer<AcademicEamsQueryResult>? pendingCourseTable;
  final Completer<AcademicEamsQueryResult?>? pendingCachedCourseTable;
  int courseTableFetchCount = 0;
  int cachedCourseTableReadCount = 0;
  final List<AcademicTermChoice?> examFetchTerms = [];

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedCourseTable() async {
    cachedCourseTableReadCount++;
    return pendingCachedCourseTable?.future ?? cachedResult;
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
    return pendingCourseTable?.future ?? result;
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
    examFetchTerms.add(term);
    return result;
  }

  @override
  Future<AcademicEamsQueryResult> fetchGrades({
    bool requireCampusNetwork = true,
  }) async {
    return result;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGrades() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult> fetchGradeProcess({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    bool requireCampusNetwork = true,
  }) async {
    return result;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGradeProcess() async {
    return null;
  }
}

AcademicEamsQueryResult _resultWithCourseTerm(
  AcademicEamsQueryResult source,
  String termName,
) {
  final snapshot = source.snapshot!;
  final courseTable = snapshot.courseTable!;
  return AcademicEamsQueryResult(
    status: source.status,
    message: source.message,
    detail: source.detail,
    checkedAt: source.checkedAt,
    entranceUri: source.entranceUri,
    finalUri: source.finalUri,
    campusNetworkStatus: source.campusNetworkStatus,
    snapshot: AcademicEamsSnapshot(
      fetchedAt: snapshot.fetchedAt,
      sourceUri: snapshot.sourceUri,
      warnings: snapshot.warnings,
      hasCourseOfferingEntry: snapshot.hasCourseOfferingEntry,
      hasFreeClassroomEntry: snapshot.hasFreeClassroomEntry,
      courseTable: AcademicCourseTableSnapshot(
        termName: termName,
        entries: courseTable.entries,
        fetchedAt: courseTable.fetchedAt,
        sourceUri: courseTable.sourceUri,
      ),
      exams: snapshot.exams,
    ),
  );
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

final AcademicEamsQueryResult _successResultWithExam = AcademicEamsQueryResult(
  status: AcademicEamsQueryStatus.success,
  message: '本专科教务只读查询成功',
  detail: '已读取当前学期课表与考试。',
  checkedAt: DateTime(2026, 5, 2, 10),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
  ),
  snapshot: AcademicEamsSnapshot(
    fetchedAt: DateTime(2026, 5, 2, 10),
    sourceUri: Uri.parse('https://jx.sspu.edu.cn/eams/home.action'),
    warnings: const [],
    hasCourseOfferingEntry: true,
    hasFreeClassroomEntry: true,
    courseTable: _successResult.snapshot!.courseTable,
    exams: AcademicExamSnapshot(
      records: const [
        AcademicExamRecord(
          courseName: '高等数学',
          rawCells: [],
          examDate: '2026-05-05',
          examArrange: '14:00-16:00',
          examLocation: '教学楼 A101',
        ),
      ],
      fetchedAt: DateTime(2026, 5, 2, 10),
      sourceUri: Uri.parse('https://jx.sspu.edu.cn/eams/stdExamTable.action'),
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

final AcademicEamsQueryResult _successResultWithEmptyCourseTable =
    AcademicEamsQueryResult(
      status: AcademicEamsQueryStatus.success,
      message: '本专科教务只读查询成功',
      detail: '当前学期没有课程记录。',
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
          termName: '2025-2026 第2学期',
          entries: const [],
          fetchedAt: DateTime(2026, 5, 2, 10, 0),
          sourceUri: Uri.parse(
            'https://jx.sspu.edu.cn/eams/courseTableForStd.action',
          ),
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
