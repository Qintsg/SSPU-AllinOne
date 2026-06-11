/*
 * 校历页面测试 — 校验校历列表详情、移动端布局和解析失败引导
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/pages/academic_calendar_page.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';

void main() {
  tearDown(() async {});

  testWidgets('校历页桌面宽度直接内嵌 PDF 并隐藏结构化摘要', (tester) async {
    final service = _FakeAcademicCalendarClient(entries: [_calendarEntry()]);
    await _pumpCalendarPage(
      tester,
      size: const Size(1100, 800),
      service: service,
    );

    await _pumpUntilFound(tester, find.text('2025-2026学年'));

    expect(find.text('2025-2026学年'), findsWidgets);
    expect(find.text('外部打开'), findsOneWidget);
    expect(find.text('校历已就绪'), findsNothing);
    expect(find.text('秋季学期'), findsNothing);
    expect(find.text('结构化解析不可用'), findsNothing);
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

    await _pumpUntilFound(tester, find.text('2025-2026学年'));

    expect(find.text('反馈解析问题'), findsNothing);
    expect(find.text('查看原始 PDF'), findsNothing);
    expect(find.text('外部打开'), findsOneWidget);
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

    await _pumpUntilFound(tester, find.text('2025-2026学年'));

    expect(service.viewerEnsureCount, 1);
    expect(service.refreshCount, 0);
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

    await _pumpUntilFound(tester, find.text('2025-2026学年'));
    await tester.tap(find.text('刷新校历'));
    await tester.pump();
    await _pumpUntilFound(tester, find.text('2026-2027学年'));

    expect(service.refreshCount, 1);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });
}

Future<void> _pumpCalendarPage(
  WidgetTester tester, {
  required Size size,
  required AcademicCalendarClient service,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    FluentApp(home: AcademicCalendarPage(service: service)),
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
  }) : refreshedEntries = refreshedEntries ?? entries;

  final List<AcademicCalendarCacheEntry> entries;
  final List<AcademicCalendarCacheEntry> refreshedEntries;
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
    return AcademicCalendarSyncResult(
      entries: entries.isEmpty ? refreshedEntries : entries,
      loadedFromCache: entries.isNotEmpty,
      refreshed: entries.isEmpty,
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
    return refreshedEntries;
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
    fetchedAt: DateTime(2026),
    parseVersion: AcademicCalendarService.parseVersion,
    pdfFilePath: null,
    rawTextFilePath: null,
    rawExtractedText: null,
    schedule: schedule,
    warnings: const [],
    errorMessage: errorMessage,
  );
}
