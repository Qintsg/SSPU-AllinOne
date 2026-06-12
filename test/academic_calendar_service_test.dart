/*
 * 校历服务测试 — 校验教务处校历列表、详情、结构化解析与缓存
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/services/app_data_directory_service.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/http_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  late Directory tempDirectory;
  late HttpClientAdapter originalHttpAdapter;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'sspu-academic-calendar-test-',
    );
    originalHttpAdapter = HttpService.instance.dio.httpClientAdapter;
    AppDataDirectoryService.debugSetDirectoryForTesting(tempDirectory.path);
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    HttpService.instance.dio.httpClientAdapter = originalHttpAdapter;
    AppDataDirectoryService.debugSetDirectoryForTesting(null);
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('列表页解析 2021 年以后校历并跳过旧格式', () {
    final items = AcademicCalendarService.parseCalendarList(_listHtml);

    expect(items.map((item) => item.schoolYearStart), [2026, 2025, 2021]);
    expect(items.first.title, '2026-2027学年校历');
    expect(
      items.first.detailUrl,
      'https://jwc.sspu.edu.cn/2026/0604/c955a170325/page.htm',
    );
    expect(AcademicCalendarService.hasNextPage(_listHtml), isTrue);
  });

  test('详情页按 PDF 播放器、PDF 链接和图片提取资源', () {
    final playerAssets = AcademicCalendarService.parseCalendarDetailAssets(
      _detailPdfPlayerHtml,
    );
    expect(playerAssets.pdfUrl, 'https://jwc.sspu.edu.cn/_upload/a.pdf');
    expect(playerAssets.sourceType, AcademicCalendarSourceType.pdf);

    final mixedAssets = AcademicCalendarService.parseCalendarDetailAssets(
      _detailMixedHtml,
    );
    expect(mixedAssets.pdfUrl, 'https://jwc.sspu.edu.cn/files/calendar.pdf');
    expect(mixedAssets.imageUrls.single, 'https://jwc.sspu.edu.cn/img/a.png');
    expect(mixedAssets.sourceType, AcademicCalendarSourceType.mixed);

    final emptyAssets = AcademicCalendarService.parseCalendarDetailAssets(
      '<html><body><div class="wp_articlecontent">暂无附件</div></body></html>',
    );
    expect(emptyAssets.sourceType, AcademicCalendarSourceType.unknown);
  });

  test('分页抓取会合并 list.htm 和 list2.htm 并按学年去重排序', () async {
    HttpService.instance.dio.httpClientAdapter = _CalendarHttpAdapter({
      AcademicCalendarService.buildListUrl(1): _listHtml,
      AcademicCalendarService.buildListUrl(2): _listPage2Html,
    });
    final service = AcademicCalendarService();

    final items = await service.fetchCalendarList(maxPages: 3);

    expect(items.map((item) => item.schoolYearStart), [2026, 2025, 2024, 2021]);
  });

  test('详情页无资源时缓存元数据并返回结构化解析失败', () async {
    HttpService.instance.dio.httpClientAdapter = _CalendarHttpAdapter({
      'https://jwc.sspu.edu.cn/no-assets.htm':
          '<html><body><div class="wp_articlecontent">暂无附件</div></body></html>',
    });
    final service = AcademicCalendarService();

    final entry = await service.fetchAndParseCalendar(
      const AcademicCalendarListItem(
        title: '2026-2027学年校历',
        detailUrl: 'https://jwc.sspu.edu.cn/no-assets.htm',
        publishDate: '2026-06-04',
        schoolYearStart: 2026,
        schoolYearEnd: 2027,
      ),
    );

    expect(entry.sourceType, AcademicCalendarSourceType.unknown);
    expect(entry.schedule, isNull);
    expect(entry.errorMessage, contains('未识别到校历 PDF 或图片资源'));
  });

  test('PDF 文本解析学期范围、夏季教学段和特殊日期', () {
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfText2025,
      schoolYearStart: 2025,
    );

    expect(schedule, isNotNull);
    expect(schedule!.fallStart, DateTime(2025, 9, 22));
    expect(schedule.springStart, DateTime(2026, 3, 2));
    expect(schedule.summerSegments.first.startWeek, 1);
    expect(schedule.summerSegments.first.endWeek, 2);
    expect(schedule.summerSegments.last.startWeek, 3);
    expect(schedule.summerSegments.last.endWeek, 5);
    expect(schedule.dayTags.single.type, AcademicCalendarDayTagType.sportsDay);
    expect(schedule.dayTags.single.date, DateTime(2025, 11, 7));
    expect(schedule.pendingHolidayNotices.single.sourceText, contains('另行通知'));
  });

  test('明确日期的工作日休息日和假期可生成标签', () {
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfTextWithExplicitDayTags,
      schoolYearStart: 2025,
    );

    expect(schedule, isNotNull);
    expect(
      schedule!.dayTags.map((tag) => tag.type),
      containsAll([
        AcademicCalendarDayTagType.workday,
        AcademicCalendarDayTagType.restDay,
        AcademicCalendarDayTagType.holiday,
      ]),
    );
    expect(schedule.pendingHolidayNotices.single.sourceText, contains('另行通知'));
  });

  test('PDF 文本解析支持夏季 3+2 教学段且不把另行通知伪造成日期标签', () {
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfTextSummer3Plus2,
      schoolYearStart: 2024,
    );

    expect(schedule, isNotNull);
    expect(schedule!.summerSegments.first.startWeek, 1);
    expect(schedule.summerSegments.first.endWeek, 3);
    expect(schedule.summerSegments.last.startWeek, 4);
    expect(schedule.summerSegments.last.endWeek, 5);
    expect(schedule.dayTags, isEmpty);
    expect(schedule.pendingHolidayNotices.single.sourceText, contains('另行通知'));
  });

  test('PDF 文本缺少关键句或日期顺序异常时结构化解析失败', () {
    expect(
      AcademicCalendarService.parseTermScheduleFromText(
        '9月22日（周一）秋季学期开始',
        schoolYearStart: 2025,
      ),
      isNull,
    );

    expect(
      AcademicCalendarService.parseTermScheduleFromText(
        _pdfTextBadDateOrder,
        schoolYearStart: 2025,
      ),
      isNull,
    );
  });

  test('结构化缓存可转换为学期定义供 #172 复用', () {
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfText2025,
      schoolYearStart: 2025,
    )!;
    final entry = AcademicCalendarCacheEntry(
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
      rawExtractedText: _pdfText2025,
      schedule: schedule,
      warnings: const [],
      errorMessage: null,
      isStale: true,
    );

    final restored = AcademicCalendarCacheEntry.fromJson(entry.toJson());
    final definitions = AcademicCalendarService.termDefinitionsFromEntries([
      restored,
    ]);

    expect(definitions.length, 3);
    expect(
      definitions
          .firstWhere(
            (definition) => definition.choice.season == AcademicTermSeason.fall,
          )
          .startDate,
      DateTime(2025, 9, 22),
    );
    expect(
      definitions
          .firstWhere(
            (definition) =>
                definition.choice.season == AcademicTermSeason.summer,
          )
          .teachingSegments
          .last
          .endWeek,
      5,
    );
    expect(restored.isStale, isTrue);
  });

  test('日期触发当前学年和 7/8 月下一学年预取', () {
    expect(
      AcademicCalendarService.requiredSchoolYearsForDate(DateTime(2026, 6, 30)),
      [2025],
    );
    expect(
      AcademicCalendarService.requiredSchoolYearsForDate(DateTime(2026, 7)),
      [2025, 2026],
    );
    expect(
      AcademicCalendarService.requiredSchoolYearsForDate(DateTime(2026, 9, 1)),
      [2026],
    );
  });

  test('缓存集合保存和读取校历条目', () async {
    final service = AcademicCalendarService();
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfText2025,
      schoolYearStart: 2025,
    )!;
    final entry = _calendarEntry(schedule: schedule);
    await StorageService.saveData(
      AcademicCalendarService.cacheCollection,
      '2025',
      entry.toJson(),
    );

    final cached = await service.readCachedCalendar(2025);
    expect(cached?.schoolYearStart, 2025);
    expect(cached?.schedule?.springStart, DateTime(2026, 3, 2));
  });

  test('PDF 型校历会下载原始 PDF 并把抽取文本写入本地缓存目录', () async {
    HttpService.instance.dio.httpClientAdapter = _CalendarHttpAdapter({
      'https://jwc.sspu.edu.cn/detail.htm': _detailPdfPlayerHtml,
      'https://jwc.sspu.edu.cn/_upload/a.pdf': Uint8List.fromList([
        37,
        80,
        68,
        70,
      ]),
    });
    final service = AcademicCalendarService(
      pdfTextExtractor: (_) async => _pdfText2025,
    );

    final entry = await service.fetchAndParseCalendar(
      const AcademicCalendarListItem(
        title: '2025-2026学年校历',
        detailUrl: 'https://jwc.sspu.edu.cn/detail.htm',
        publishDate: '2025-04-24',
        schoolYearStart: 2025,
        schoolYearEnd: 2026,
      ),
    );

    expect(entry.schedule?.fallStart, DateTime(2025, 9, 22));
    expect(entry.pdfFilePath, isNotNull);
    expect(File(entry.pdfFilePath!).existsSync(), isTrue);
    expect(entry.rawTextFilePath, isNotNull);
    expect(File(entry.rawTextFilePath!).readAsStringSync(), _pdfText2025);
  });

  test('解析版本过旧时自动刷新并覆盖旧缓存', () async {
    final oldSchedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfText2025,
      schoolYearStart: 2025,
    )!;
    await StorageService.saveData(
      AcademicCalendarService.cacheCollection,
      '2025',
      _calendarEntry(schedule: oldSchedule, parseVersion: 0).toJson(),
    );
    HttpService.instance.dio.httpClientAdapter = _CalendarHttpAdapter({
      AcademicCalendarService.buildListUrl(1): _listOnly2025Html,
      'https://jwc.sspu.edu.cn/2025/0424/c955a161607/page.htm':
          _detailPdfPlayerHtml,
      'https://jwc.sspu.edu.cn/_upload/a.pdf': Uint8List.fromList([
        37,
        80,
        68,
        70,
      ]),
    });
    final service = AcademicCalendarService(
      pdfTextExtractor: (_) async => _pdfText2025,
    );

    final result = await service.ensureCalendarsForDate(
      now: DateTime(2026, 6, 30),
    );
    final cached = await service.readCachedCalendar(2025);

    expect(result.refreshed, isTrue);
    expect(cached?.parseVersion, AcademicCalendarService.parseVersion);
    expect(cached?.rawExtractedText, _pdfText2025);
  });

  test('刷新失败时保留旧缓存并标记为可能过期', () async {
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfText2025,
      schoolYearStart: 2025,
    )!;
    await StorageService.saveData(
      AcademicCalendarService.cacheCollection,
      '2025',
      _calendarEntry(schedule: schedule, parseVersion: 0).toJson(),
    );
    HttpService.instance.dio.httpClientAdapter = _CalendarHttpAdapter(
      const {},
      failAllRequests: true,
    );
    final service = AcademicCalendarService();

    final result = await service.ensureCalendarsForDate(
      now: DateTime(2026, 6, 30),
    );
    final cached = await service.readCachedCalendar(2025);

    expect(result.errorMessage, isNotNull);
    expect(result.entries.single.schoolYearStart, 2025);
    expect(result.entries.single.isStale, isTrue);
    expect(cached?.isStale, isTrue);
  });

  test('校历查看器首次或超过一个月进入时自动刷新', () async {
    final schedule = AcademicCalendarService.parseTermScheduleFromText(
      _pdfText2025,
      schoolYearStart: 2025,
    )!;
    await StorageService.saveData(
      AcademicCalendarService.cacheCollection,
      '2025',
      _calendarEntry(schedule: schedule).toJson(),
    );
    await StorageService.setString(
      StorageKeys.academicCalendarLastAutoRefreshAt,
      DateTime(2026, 6, 1).toUtc().toIso8601String(),
    );

    final adapter = _CalendarHttpAdapter({
      AcademicCalendarService.buildListUrl(1): _listOnly2025Html,
      'https://jwc.sspu.edu.cn/2025/0424/c955a161607/page.htm':
          _detailPdfPlayerHtml,
      'https://jwc.sspu.edu.cn/_upload/a.pdf': Uint8List.fromList([
        37,
        80,
        68,
        70,
      ]),
    });
    HttpService.instance.dio.httpClientAdapter = adapter;
    final service = AcademicCalendarService(
      pdfTextExtractor: (_) async => _pdfText2025,
    );

    final cachedResult = await service.ensureCalendarsForViewer(
      now: DateTime(2026, 6, 20),
    );
    final refreshedResult = await service.ensureCalendarsForViewer(
      now: DateTime(2026, 7, 5),
    );

    expect(cachedResult.refreshed, isFalse);
    expect(refreshedResult.refreshed, isTrue);
    expect(adapter.requestCount, 3);
  });
}

AcademicCalendarCacheEntry _calendarEntry({
  required AcademicCalendarTermSchedule schedule,
  int parseVersion = AcademicCalendarService.parseVersion,
}) {
  return AcademicCalendarCacheEntry(
    schoolYearStart: 2025,
    title: '2025-2026学年校历',
    detailUrl: 'https://jwc.sspu.edu.cn/detail.htm',
    publishDate: '2025-04-24',
    pdfUrl: 'https://jwc.sspu.edu.cn/calendar.pdf',
    imageUrls: const [],
    sourceType: AcademicCalendarSourceType.pdf,
    fetchedAt: DateTime(2026),
    parseVersion: parseVersion,
    pdfFilePath: null,
    rawTextFilePath: null,
    rawExtractedText: _pdfText2025,
    schedule: schedule,
    warnings: const [],
    errorMessage: null,
  );
}

class _CalendarHttpAdapter implements HttpClientAdapter {
  _CalendarHttpAdapter(this.responses, {this.failAllRequests = false});

  final Map<String, Object> responses;
  final bool failAllRequests;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (failAllRequests) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'network unavailable',
      );
    }
    final value = responses[options.uri.toString()];
    if (value == null) {
      return ResponseBody.fromString('not found', 404);
    }
    if (value is Uint8List) {
      return ResponseBody.fromBytes(value, 200);
    }
    return ResponseBody.fromString(value.toString(), 200);
  }

  @override
  void close({bool force = false}) {}
}

const _listHtml = '''
<html><body>
<div class="col_news_con"><ul class="news_list">
<li class="news"><span class="news_title"><a href="/2026/0604/c955a170325/page.htm" title="2026-2027学年校历">2026-2027学年校历</a></span><span class="news_meta">2026-06-04</span></li>
<li class="news"><span class="news_title"><a href="/2025/0424/c955a161607/page.htm" title="2025-2026学年校历">2025-2026学年校历</a></span><span class="news_meta">2025-04-24</span></li>
<li class="news"><span class="news_title"><a href="/2021/0923/c955a13165/page.htm" title="2021-2022学年校历">2021-2022学年校历</a></span><span class="news_meta">2021-09-23</span></li>
<li class="news"><span class="news_title"><a href="/2020/page.htm" title="2020-2021学年校历">2020-2021学年校历</a></span><span class="news_meta">2020-09-28</span></li>
</ul></div>
<div class="wp_paging"><a class="next" href="/xl/list2.htm">下一页</a></div>
</body></html>
''';

const _listPage2Html = '''
<html><body>
<div class="col_news_con"><ul class="news_list">
<li class="news"><span class="news_title"><a href="/2024/0524/c955a151607/page.htm" title="2024-2025学年校历">2024-2025学年校历</a></span><span class="news_meta">2024-05-24</span></li>
<li class="news"><span class="news_title"><a href="/2020/page.htm" title="2020-2021学年校历">2020-2021学年校历</a></span><span class="news_meta">2020-09-28</span></li>
</ul></div>
</body></html>
''';

const _listOnly2025Html = '''
<html><body>
<div class="col_news_con"><ul class="news_list">
<li class="news"><span class="news_title"><a href="/2025/0424/c955a161607/page.htm" title="2025-2026学年校历">2025-2026学年校历</a></span><span class="news_meta">2025-04-24</span></li>
</ul></div>
</body></html>
''';

const _detailPdfPlayerHtml = '''
<html><body><div class="wp_articlecontent">
<div class="wp_pdf_player" pdfsrc="/_upload/a.pdf"></div>
</div></body></html>
''';

const _detailMixedHtml = '''
<html><body><div class="wp_articlecontent">
<a href="/files/calendar.pdf">下载 PDF</a>
<img src="/img/a.png" />
</div></body></html>
''';

const _pdfText2025 = '''
2025-2026学年校历
秋季学期：17周
9月22日（周一）秋季学期开始
校运会：11月7日（周五）停课一天
国庆节、元旦放假安排根据国务院办公厅公布的2025年节假日安排另行通知
春季学期：17周
3月2日（周一）春季学期开始
夏季学期：5周，分二个阶段进行
第一阶段：6月29日（周一）开始，7月12日（周日）结束
第二阶段：8月31日（周一）开始，9月20日（周日）结束
''';

const _pdfTextWithExplicitDayTags = '''
2025-2026学年校历
9月22日（周一）秋季学期开始
10月4日（周六）上课
10月5日（周日）休息
10月6日（周一）放假一天
国庆节、元旦放假安排根据国务院办公厅公布的2025年节假日安排另行通知
3月2日（周一）春季学期开始
第一阶段：6月29日（周一）开始，7月12日（周日）结束
第二阶段：8月31日（周一）开始，9月20日（周日）结束
''';

const _pdfTextSummer3Plus2 = '''
2024-2025学年校历
9月16日（周一）秋季学期开始
清明节、劳动节、端午节放假安排根据国务院办公厅公布的2025年节假日安排另行通知
2月17日（周一）春季学期开始
第一阶段：6月16日（周一）开始，7月6日（周日）结束
第二阶段：9月8日（周一）开始，9月21日（周日）结束
''';

const _pdfTextBadDateOrder = '''
2025-2026学年校历
9月22日（周一）秋季学期开始
3月2日（周一）春季学期开始
第一阶段：7月12日（周日）开始，6月29日（周一）结束
第二阶段：8月31日（周一）开始，9月20日（周日）结束
''';
