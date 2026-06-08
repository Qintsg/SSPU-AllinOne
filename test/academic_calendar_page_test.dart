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
import 'package:sspu_allinone/pages/academic_calendar_pdf_page.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';

void main() {
  tearDown(() async {});

  testWidgets('校历页桌面宽度展示列表、详情和特殊日期', (tester) async {
    await _pumpCalendarPage(
      tester,
      size: const Size(1100, 800),
      service: _FakeAcademicCalendarClient(entries: [_calendarEntry()]),
    );

    await _pumpUntilFound(tester, find.text('校历已就绪'));

    expect(find.text('2025-2026学年'), findsWidgets);
    expect(find.text('秋季学期'), findsOneWidget);
    expect(find.text('运动会停课日'), findsOneWidget);
    expect(find.textContaining('另行通知'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('校历页移动宽度下不溢出并保留反馈入口', (tester) async {
    await _pumpCalendarPage(
      tester,
      size: const Size(390, 844),
      service: _FakeAcademicCalendarClient(entries: [_failedCalendarEntry()]),
    );

    await _pumpUntilFound(tester, find.text('结构化解析不可用'));

    expect(find.text('反馈解析问题'), findsOneWidget);
    expect(find.text('查看原始 PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('解析失败弹窗包含提交 issue 引导', (tester) async {
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: _FakeAcademicCalendarClient(entries: [_failedCalendarEntry()]),
    );

    await _pumpUntilFound(tester, find.text('反馈解析问题'));
    await tester.tap(find.text('反馈解析问题'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('校历解析失败'), findsOneWidget);
    expect(find.text('提交 issue'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _resetView(tester);
  });

  testWidgets('PDF 查看入口失败时不阻断校历详情页', (tester) async {
    await _pumpCalendarPage(
      tester,
      size: const Size(800, 720),
      service: _FakeAcademicCalendarClient(entries: [_failedCalendarEntry()]),
    );

    await _pumpUntilFound(tester, find.text('查看原始 PDF'));
    await tester.tap(find.text('查看原始 PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(AcademicCalendarPdfPage), findsOneWidget);
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
  return _baseEntry(schedule: schedule, errorMessage: null);
}

AcademicCalendarCacheEntry _failedCalendarEntry() {
  return _baseEntry(schedule: null, errorMessage: 'PDF 文本抽取结果为空。');
}

AcademicCalendarCacheEntry _baseEntry({
  required AcademicCalendarTermSchedule? schedule,
  required String? errorMessage,
}) {
  return AcademicCalendarCacheEntry(
    schoolYearStart: 2025,
    title: '2025-2026学年校历',
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
