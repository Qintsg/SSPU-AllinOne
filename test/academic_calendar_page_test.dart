/*
 * 校历页面测试 — 校验校历列表详情、移动端布局和解析失败引导
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/pages/academic_calendar_page.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';

void main() {
  tearDown(() async {});

  testWidgets('校历页桌面宽度同时呈现原始 PDF 与结构化学期证据', (tester) async {
    final service = _FakeAcademicCalendarClient(entries: [_calendarEntry()]);
    await _pumpCalendarPage(
      tester,
      size: const Size(1100, 800),
      service: service,
    );

    await _pumpUntilFound(tester, find.text('2025–2026 学年'));

    expect(find.text('2025–2026 学年'), findsWidgets);
    expect(find.bySemanticsLabel('外部打开校历 PDF'), findsOneWidget);
    expect(find.text('学期边界'), findsOneWidget);
    expect(find.text('秋季'), findsOneWidget);
    expect(find.text('09.22—01.18'), findsOneWidget);
    expect(find.text('春季'), findsOneWidget);
    expect(find.text('03.02—06.28'), findsOneWidget);
    expect(find.text('夏季'), findsOneWidget);
    expect(find.text('5 个教学周'), findsOneWidget);
    expect(find.textContaining('校运会'), findsOneWidget);
    expect(find.textContaining('另行通知'), findsOneWidget);
    final evidence = find.byKey(const Key('academic-calendar-evidence-card'));
    final document = find.byKey(const Key('academic-calendar-document-panel'));
    expect(evidence, findsOneWidget);
    expect(document, findsOneWidget);
    expect(
      tester.getSize(evidence).height,
      lessThan(tester.getSize(document).height),
    );
    expect(service.viewerEnsureCount, 1);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('校历页移动宽度下使用横向学年选择器且不溢出', (tester) async {
    await _pumpCalendarPage(
      tester,
      size: const Size(390, 844),
      service: _FakeAcademicCalendarClient(entries: [_failedCalendarEntry()]),
    );

    await _pumpUntilFound(tester, find.text('2025–2026 学年'));

    expect(find.text('反馈解析问题'), findsNothing);
    expect(find.text('查看原始 PDF'), findsNothing);
    expect(find.bySemanticsLabel('外部打开校历 PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('首次进入校历页会按查看器策略触发自动刷新', (tester) async {
    final service = _FakeAcademicCalendarClient(
      entries: const [],
      refreshedEntries: [_calendarEntry()],
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: service,
    );

    await _pumpUntilFound(tester, find.text('2025–2026 学年'));

    expect(service.viewerEnsureCount, 1);
    expect(service.refreshCount, 0);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('初始加载以活动环账本呈现且不提供假操作', (tester) async {
    final service = _FakeAcademicCalendarClient(
      entries: const [],
      refreshedEntries: [_calendarEntry()],
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(360, 800),
      service: service,
    );

    // 立即断言加载账本，不等待异步刷新完成。
    expect(find.text('正在读取校历'), findsWidgets);
    expect(find.textContaining('正在读取本机档案并检查公开来源'), findsOneWidget);
    expect(find.bySemanticsLabel('正在读取校历'), findsWidgets);
    expect(find.text('重新读取公开校历'), findsNothing);
    expect(find.text('刷新公开校历'), findsNothing);
    expect(find.bySemanticsLabel('刷新校历'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 窄屏下加载账本不横向溢出。
    await _pumpUntilFound(tester, find.text('2025–2026 学年'));
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('手动刷新校历后更新页面条目', (tester) async {
    final service = _FakeAcademicCalendarClient(
      entries: [_calendarEntry()],
      refreshedEntries: [_calendarEntry(year: 2026)],
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: service,
    );

    await _pumpUntilFound(tester, find.text('2025–2026 学年'));
    await tester.tap(find.bySemanticsLabel('刷新校历'));
    await tester.pump();
    await _pumpUntilFound(tester, find.text('2026–2027 学年'));

    expect(service.refreshCount, 1);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('校历缓存可用但刷新失败时保留条目并显示提示', (tester) async {
    const message = '正在显示本地校历缓存；网络恢复后可刷新。';
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: _FakeAcademicCalendarClient(
        entries: [_calendarEntry()],
        errorMessage: message,
      ),
    );

    await _pumpUntilFound(tester, find.text(message));

    expect(find.text('2025–2026 学年'), findsWidgets);
    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('校历页可通过查看器 seam 隔离外部 PDF 区域', (tester) async {
    tester.view.physicalSize = const Size(800, 720);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(800, 720));
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPage(
          service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
          viewerBuilder: (context, entry) =>
              Text('固定查看器：${entry?.schoolYearLabel}'),
        ),
      ),
    );

    await _pumpUntilFound(tester, find.text('固定查看器：2025-2026学年'));

    expect(find.text('固定查看器：2025-2026学年'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('服务换代后旧校历请求不得回写新页面', (tester) async {
    final oldResult = Completer<AcademicCalendarSyncResult>();
    final oldService = _FakeAcademicCalendarClient(
      entries: [_calendarEntry()],
      viewerResult: oldResult.future,
    );
    final newService = _FakeAcademicCalendarClient(
      entries: [_calendarEntry(year: 2026)],
    );

    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: oldService,
    );
    await _pumpUntilFound(tester, find.text('2025–2026 学年'));
    await tester.pumpWidget(
      YhApp(home: AcademicCalendarPage(service: newService)),
    );
    await _pumpUntilFound(tester, find.text('2026–2027 学年'));

    oldResult.complete(
      AcademicCalendarSyncResult(
        entries: [_calendarEntry(year: 2027)],
        loadedFromCache: false,
        refreshed: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026–2027 学年'), findsWidgets);
    expect(find.text('2027–2028 学年'), findsNothing);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('外部打开先确认且失败后保留当前学年与 PDF', (tester) async {
    var launchCount = 0;
    tester.view.physicalSize = const Size(800, 720);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(800, 720));
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPage(
          service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
          launchExternalOverride: (uri) async {
            launchCount++;
            return false;
          },
          viewerBuilder: (context, entry) => Text('PDF：${entry?.title}'),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('PDF：2025-2026学年校历'));

    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    await tester.pumpAndSettle();
    expect(find.text('在外部应用打开校历？'), findsOneWidget);
    expect(find.textContaining('jwc.sspu.edu.cn'), findsOneWidget);
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();

    expect(launchCount, 1);
    expect(find.textContaining('系统未能打开教务处校历 PDF'), findsOneWidget);
    expect(find.text('2025–2026 学年'), findsWidgets);
    expect(find.text('PDF：2025-2026学年校历'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('缓存恢复后的自动检查与手动刷新不得并发', (tester) async {
    final ensure = Completer<AcademicCalendarSyncResult>();
    final service = _FakeAcademicCalendarClient(
      entries: [_calendarEntry()],
      viewerResult: ensure.future,
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: service,
    );
    await _pumpUntilFound(tester, find.text('2025–2026 学年'));

    await tester.tap(find.bySemanticsLabel('刷新校历'), warnIfMissed: false);
    await tester.pump();
    expect(service.refreshCount, 0);
    expect(find.textContaining('正在检查公开校历更新'), findsOneWidget);

    ensure.complete(
      AcademicCalendarSyncResult(
        entries: [_calendarEntry()],
        loadedFromCache: true,
        refreshed: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('正在检查公开校历更新'), findsNothing);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('校历页分别标注当前实际与查询使用学期并允许原位调整', (tester) async {
    final termService = _FakeAcademicTermService(
      actual: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.summer,
      ),
      query: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.fall,
      ),
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 900),
      service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
      termService: termService,
    );
    await _pumpUntilFound(tester, find.textContaining('当前实际：2025-2026 学年夏季学期'));

    expect(find.textContaining('当前实际：2025-2026 学年夏季学期'), findsOneWidget);
    expect(find.text('查询使用：2025-2026 学年秋季学期'), findsOneWidget);
    expect(find.byKey(const Key('academic-term-year-select')), findsOneWidget);
    expect(
      find.byKey(const Key('academic-term-season-select')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('查询学期保存失败时保留原选择并允许原位重试', (tester) async {
    final original = const AcademicTermChoice(
      academicYear: 2025,
      season: AcademicTermSeason.fall,
    );
    final termService = _FakeAcademicTermService(
      actual: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.summer,
      ),
      query: original,
      throwOnSet: true,
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 900),
      service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
      termService: termService,
    );
    await _pumpUntilFound(tester, find.text('查询使用：2025-2026 学年秋季学期'));

    final seasonSelect = tester.widget<YhSelect<AcademicTermSeason>>(
      find.byKey(const Key('academic-term-season-select')),
    );
    seasonSelect.onChanged!(AcademicTermSeason.spring);
    await tester.pumpAndSettle();

    expect(find.textContaining('查询学期未能保存'), findsOneWidget);
    expect(find.text('查询使用：2025-2026 学年秋季学期'), findsOneWidget);
    expect(termService.settings.selectedTerm, original);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('紧凑端仍完整呈现特殊日期与后续通知', (tester) async {
    await _pumpCalendarPage(
      tester,
      size: const Size(390, 844),
      service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
    );
    await _pumpUntilFound(tester, find.textContaining('校运会：11月7日'));

    expect(find.textContaining('校运会：11月7日'), findsOneWidget);
    expect(find.textContaining('放假安排另行通知'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('刷新抛出异常后保留内容并解除操作锁', (tester) async {
    final service = _FakeAcademicCalendarClient(
      entries: [_calendarEntry()],
      refreshError: true,
    );
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 900),
      service: service,
    );
    await _pumpUntilFound(tester, find.text('2025–2026 学年'));

    await tester.tap(find.bySemanticsLabel('刷新校历'));
    await tester.pumpAndSettle();
    expect(find.textContaining('当前有效内容已保留'), findsOneWidget);
    expect(find.text('2025–2026 学年'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('刷新校历'));
    await tester.pumpAndSettle();
    expect(service.refreshCount, 2);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('外部打开等待期间重复触发保持单飞', (tester) async {
    final launch = Completer<bool>();
    var launchCount = 0;
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(800, 900));
    await tester.pumpWidget(
      YhApp(
        home: AcademicCalendarPage(
          service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
          launchExternalOverride: (uri) {
            launchCount++;
            return launch.future;
          },
          viewerBuilder: (context, entry) => const Text('固定 PDF 正文'),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('固定 PDF 正文'));
    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pump();
    expect(launchCount, 1);
    await tester.tap(find.bySemanticsLabel('外部打开校历 PDF'), warnIfMissed: false);
    await tester.pump();
    expect(launchCount, 1);

    launch.complete(true);
    await tester.pumpAndSettle();
    expect(launchCount, 1);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('页面销毁后迟到的校历结果不会回写或抛出异常', (tester) async {
    final pending = Completer<AcademicCalendarSyncResult>();
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 900),
      service: _FakeAcademicCalendarClient(
        entries: [_calendarEntry()],
        viewerResult: pending.future,
      ),
    );
    await _pumpUntilFound(tester, find.text('2025–2026 学年'));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(
      AcademicCalendarSyncResult(
        entries: [_calendarEntry(year: 2027)],
        loadedFromCache: false,
        refreshed: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2027–2028 学年'), findsNothing);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });
}

Future<void> _pumpCalendarPage(
  WidgetTester tester, {
  required Size size,
  required AcademicCalendarClient service,
  AcademicTermService? termService,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    YhApp(
      home: AcademicCalendarPage(
        service: service,
        termService: termService,
        now: DateTime(2026, 7, 18, 9, 30),
      ),
    ),
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _resetView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.binding.setSurfaceSize(null);
}

class _FakeAcademicCalendarClient implements AcademicCalendarClient {
  _FakeAcademicCalendarClient({
    required this.entries,
    List<AcademicCalendarCacheEntry>? refreshedEntries,
    this.errorMessage,
    this.viewerResult,
    this.refreshError = false,
  }) : refreshedEntries = refreshedEntries ?? entries;

  final List<AcademicCalendarCacheEntry> entries;
  final List<AcademicCalendarCacheEntry> refreshedEntries;
  final String? errorMessage;
  final Future<AcademicCalendarSyncResult>? viewerResult;
  final bool refreshError;
  int refreshCount = 0;
  int viewerEnsureCount = 0;

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
    viewerEnsureCount++;
    final override = viewerResult;
    if (override != null) return override;
    return AcademicCalendarSyncResult(
      entries: entries.isEmpty ? refreshedEntries : entries,
      loadedFromCache: entries.isNotEmpty,
      refreshed: entries.isEmpty,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<List<AcademicCalendarCacheEntry>> readCachedCalendars() async {
    return entries;
  }

  @override
  Future<AcademicCalendarCacheEntry?> readCachedCalendar(int schoolYear) async {
    for (final entry in entries) {
      if (entry.schoolYearStart == schoolYear) return entry;
    }
    return null;
  }

  @override
  Future<List<AcademicTermDefinition>> readCachedTermDefinitions() async {
    return AcademicCalendarService.termDefinitionsFromEntries(entries);
  }

  @override
  Future<List<AcademicCalendarCacheEntry>> refreshCalendars({
    List<int>? targetYears,
  }) async {
    refreshCount++;
    if (refreshError) throw StateError('refresh failed');
    return refreshedEntries;
  }
}

class _FakeAcademicTermService extends AcademicTermService {
  _FakeAcademicTermService({
    required this.actual,
    AcademicTermChoice? query,
    this.throwOnSet = false,
  }) : _settings = AcademicTermSettings(selectedTerm: query);

  final AcademicTermChoice actual;
  AcademicTermSettings _settings;
  final bool throwOnSet;

  @override
  AcademicTermSettings get settings => _settings;

  @override
  List<AcademicTermChoice> get availableTerms => [
    for (final season in AcademicTermSeason.values)
      AcademicTermChoice(academicYear: actual.academicYear, season: season),
  ];

  @override
  Future<AcademicTermSettings> loadSettings() async => _settings;

  @override
  Future<AcademicTermContext> getEffectiveContext({DateTime? now}) async =>
      AcademicTermContext(
        term: actual,
        queryTerm: _settings.selectedTerm,
        source: _settings.selectedTerm == null
            ? AcademicTermContextSource.automatic
            : AcademicTermContextSource.selected,
        dateStatus: AcademicTermDateStatus.summerVacation,
        resolvedAt: now ?? DateTime(2026, 7, 18, 9, 30),
        isTeachingWeek: false,
      );

  @override
  Future<void> setSelectedTerm(AcademicTermChoice term) async {
    if (throwOnSet) throw StateError('save failed');
    _settings = AcademicTermSettings(selectedTerm: term);
  }
}

AcademicCalendarCacheEntry _calendarEntry({int year = 2025}) {
  final schedule = AcademicCalendarTermSchedule(
    schoolYearStart: year,
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
  return _baseEntry(
    schoolYearStart: year,
    schedule: schedule,
    errorMessage: null,
  );
}

AcademicCalendarCacheEntry _failedCalendarEntry() {
  return _baseEntry(
    schoolYearStart: 2025,
    schedule: null,
    errorMessage: 'PDF 文本抽取结果为空。',
  );
}

AcademicCalendarCacheEntry _baseEntry({
  required int schoolYearStart,
  required AcademicCalendarTermSchedule? schedule,
  required String? errorMessage,
}) {
  return AcademicCalendarCacheEntry(
    schoolYearStart: schoolYearStart,
    title: '$schoolYearStart-${schoolYearStart + 1}学年校历',
    detailUrl: 'https://jwc.sspu.edu.cn/detail.htm',
    publishDate: '2025-04-24',
    pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
    imageUrls: const ['https://jwc.sspu.edu.cn/calendar.png'],
    sourceType: AcademicCalendarSourceType.mixed,
    fetchedAt: DateTime(2026, 7, 18, 9, 30),
    parseVersion: AcademicCalendarService.parseVersion,
    pdfFilePath: null,
    rawTextFilePath: null,
    rawExtractedText: null,
    schedule: schedule,
    warnings: const [],
    errorMessage: errorMessage,
  );
}
