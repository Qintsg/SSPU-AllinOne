/*
 * 校历服务 — 抓取教务处校历、解析 PDF 文本并提供本地缓存
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_service.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/academic_calendar.dart';
import '../models/academic_term.dart';
import 'academic_calendar_file_ops.dart' as file_ops;
import 'http_service.dart';
import 'storage_service.dart';

/// PDF 文本抽取函数。
typedef AcademicCalendarPdfTextExtractor =
    Future<String> Function(String pdfFilePath);

/// 校历只读客户端。
abstract class AcademicCalendarClient {
  /// 按日期确保当前学年和临近学年校历存在。
  Future<AcademicCalendarSyncResult> ensureCalendarsForDate({DateTime? now});

  /// 刷新校历缓存。
  Future<List<AcademicCalendarCacheEntry>> refreshCalendars({
    List<int>? targetYears,
  });

  /// 读取全部校历缓存。
  Future<List<AcademicCalendarCacheEntry>> readCachedCalendars();

  /// 读取指定学年校历缓存。
  Future<AcademicCalendarCacheEntry?> readCachedCalendar(int schoolYear);

  /// 读取可用于学期计算的定义。
  Future<List<AcademicTermDefinition>> readCachedTermDefinitions();
}

/// 校历服务。
class AcademicCalendarService implements AcademicCalendarClient {
  AcademicCalendarService({
    HttpService? httpService,
    AcademicCalendarPdfTextExtractor? pdfTextExtractor,
  }) : _http = httpService ?? HttpService.instance,
       _pdfTextExtractor =
           pdfTextExtractor ?? file_ops.extractAcademicCalendarPdfText;

  /// 单例。
  static final AcademicCalendarService instance = AcademicCalendarService();

  /// 教务处基础 URL。
  static const String baseUrl = 'https://jwc.sspu.edu.cn';

  /// 校历列表路径。
  static const String calendarListPath = '/xl/list.htm';

  /// 缓存集合。
  static const String cacheCollection = StorageKeys.academicCalendarCollection;

  /// 当前解析版本。
  static const int parseVersion = 1;

  final HttpService _http;
  final AcademicCalendarPdfTextExtractor _pdfTextExtractor;
  Future<void>? _pendingEnsure;

  /// 按日期确保当前学年和临近学年校历存在。
  @override
  Future<AcademicCalendarSyncResult> ensureCalendarsForDate({
    DateTime? now,
  }) async {
    final pending = _pendingEnsure;
    if (pending != null) await pending;

    final completer = Completer<void>();
    _pendingEnsure = completer.future;
    try {
      final targetYears = requiredSchoolYearsForDate(now ?? DateTime.now());
      final cached = await readCachedCalendars();
      final refreshYears = targetYears.where((year) {
        final entry = _findEntryBySchoolYear(cached, year);
        return entry == null || entry.parseVersion != parseVersion;
      }).toList();

      if (refreshYears.isEmpty) {
        return AcademicCalendarSyncResult(
          entries: cached,
          loadedFromCache: cached.isNotEmpty,
          refreshed: false,
        );
      }

      try {
        final refreshed = await refreshCalendars(targetYears: refreshYears);
        final merged = await readCachedCalendars();
        final unresolvedYears = refreshYears
            .where(
              (year) =>
                  _findEntryBySchoolYear(merged, year)?.parseVersion !=
                  parseVersion,
            )
            .toList();
        if (unresolvedYears.isNotEmpty) {
          final message = '未在教务处校历列表中找到 ${unresolvedYears.join('、')} 学年校历。';
          for (final entry in merged.where(
            (entry) => unresolvedYears.contains(entry.schoolYearStart),
          )) {
            await StorageService.saveData(
              cacheCollection,
              entry.schoolYearStart.toString(),
              entry.copyWith(isStale: true, errorMessage: message).toJson(),
            );
          }
          final staleMerged = await readCachedCalendars();
          return AcademicCalendarSyncResult(
            entries: staleMerged.isEmpty ? refreshed : staleMerged,
            loadedFromCache: cached.isNotEmpty,
            refreshed: true,
            errorMessage: message,
          );
        }
        return AcademicCalendarSyncResult(
          entries: merged.isEmpty ? refreshed : merged,
          loadedFromCache: cached.isNotEmpty,
          refreshed: true,
        );
      } catch (error) {
        for (final entry in cached.where(
          (entry) => refreshYears.contains(entry.schoolYearStart),
        )) {
          await StorageService.saveData(
            cacheCollection,
            entry.schoolYearStart.toString(),
            entry
                .copyWith(
                  isStale: true,
                  errorMessage: HttpService.describeError(error),
                )
                .toJson(),
          );
        }
        return AcademicCalendarSyncResult(
          entries: cached
              .map(
                (entry) => refreshYears.contains(entry.schoolYearStart)
                    ? entry.copyWith(
                        isStale: true,
                        errorMessage: HttpService.describeError(error),
                      )
                    : entry,
              )
              .toList(),
          loadedFromCache: cached.isNotEmpty,
          refreshed: false,
          errorMessage: HttpService.describeError(error),
        );
      }
    } finally {
      completer.complete();
      if (identical(_pendingEnsure, completer.future)) _pendingEnsure = null;
    }
  }

  /// 刷新校历。targetYears 为空时刷新所有 2021 年以后可识别条目。
  @override
  Future<List<AcademicCalendarCacheEntry>> refreshCalendars({
    List<int>? targetYears,
  }) async {
    final targetSet = targetYears?.toSet();
    final listItems = await fetchCalendarList(maxPages: 3);
    final entries = <AcademicCalendarCacheEntry>[];

    for (final item in listItems) {
      if (targetSet != null && !targetSet.contains(item.schoolYearStart)) {
        continue;
      }
      final entry = await fetchAndParseCalendar(item);
      await StorageService.saveData(
        cacheCollection,
        item.schoolYearStart.toString(),
        entry.toJson(),
      );
      entries.add(entry);
    }

    return entries;
  }

  /// 抓取校历列表。
  Future<List<AcademicCalendarListItem>> fetchCalendarList({
    int maxPages = 3,
  }) async {
    final items = <AcademicCalendarListItem>[];
    for (var page = 1; page <= maxPages; page++) {
      final htmlText = await _http.fetchText(buildListUrl(page));
      final pageItems = parseCalendarList(htmlText, baseUrl: baseUrl);
      if (pageItems.isEmpty) break;
      items.addAll(pageItems);
      if (!hasNextPage(htmlText)) break;
    }

    final deduped = <int, AcademicCalendarListItem>{};
    for (final item in items) {
      deduped[item.schoolYearStart] = item;
    }
    return deduped.values.toList()
      ..sort((a, b) => b.schoolYearStart.compareTo(a.schoolYearStart));
  }

  /// 获取并解析单个校历。
  Future<AcademicCalendarCacheEntry> fetchAndParseCalendar(
    AcademicCalendarListItem item,
  ) async {
    final detailHtml = await _http.fetchText(item.detailUrl);
    final assets = parseCalendarDetailAssets(detailHtml, baseUrl: baseUrl);
    if (assets.sourceType == AcademicCalendarSourceType.unknown) {
      return AcademicCalendarCacheEntry(
        schoolYearStart: item.schoolYearStart,
        title: item.title,
        detailUrl: item.detailUrl,
        publishDate: item.publishDate,
        pdfUrl: null,
        imageUrls: const [],
        sourceType: AcademicCalendarSourceType.unknown,
        fetchedAt: DateTime.now(),
        parseVersion: parseVersion,
        pdfFilePath: null,
        rawTextFilePath: null,
        rawExtractedText: null,
        schedule: null,
        warnings: const ['未识别到 PDF 或图片资源。'],
        errorMessage: '未识别到校历 PDF 或图片资源。',
      );
    }

    String? pdfPath;
    String? textPath;
    String? rawText;
    AcademicCalendarTermSchedule? schedule;
    final warnings = <String>[];
    String? errorMessage;

    if (assets.pdfUrl != null) {
      try {
        if (!kIsWeb) {
          pdfPath = await file_ops.downloadAcademicCalendarPdf(
            _http,
            assets.pdfUrl!,
            schoolYearStart: item.schoolYearStart,
          );
          rawText = await _pdfTextExtractor(pdfPath);
          textPath = await file_ops.writeAcademicCalendarRawText(
            rawText,
            schoolYearStart: item.schoolYearStart,
          );
        }

        if (rawText != null && rawText.trim().isNotEmpty) {
          schedule = parseTermScheduleFromText(
            rawText,
            schoolYearStart: item.schoolYearStart,
          );
        } else if (!kIsWeb) {
          warnings.add('PDF 文本抽取结果为空。');
          errorMessage = 'PDF 文本抽取结果为空。';
        }
      } catch (error) {
        warnings.add(HttpService.describeError(error));
        errorMessage = HttpService.describeError(error);
      }
    } else {
      warnings.add('该校历仅识别到图片，暂不承担自动学期计算。');
      errorMessage = '该校历仅识别到图片，暂不承担自动学期计算。';
    }

    return AcademicCalendarCacheEntry(
      schoolYearStart: item.schoolYearStart,
      title: item.title,
      detailUrl: item.detailUrl,
      publishDate: item.publishDate,
      pdfUrl: assets.pdfUrl,
      imageUrls: assets.imageUrls,
      sourceType: assets.sourceType,
      fetchedAt: DateTime.now(),
      parseVersion: parseVersion,
      pdfFilePath: pdfPath,
      rawTextFilePath: textPath,
      rawExtractedText: rawText,
      schedule: schedule,
      warnings: [...warnings, if (schedule != null) ...schedule.parseWarnings],
      errorMessage: schedule == null ? errorMessage ?? '校历结构化解析失败。' : null,
    );
  }

  /// 读取全部缓存。
  @override
  Future<List<AcademicCalendarCacheEntry>> readCachedCalendars() async {
    final records = await StorageService.getAllData(cacheCollection);
    final entries = records.values
        .map(AcademicCalendarCacheEntry.fromJson)
        .toList();
    entries.sort((a, b) => b.schoolYearStart.compareTo(a.schoolYearStart));
    return entries;
  }

  /// 读取指定学年缓存。
  @override
  Future<AcademicCalendarCacheEntry?> readCachedCalendar(int schoolYear) async {
    final data = await StorageService.getData(
      cacheCollection,
      schoolYear.toString(),
    );
    return data == null ? null : AcademicCalendarCacheEntry.fromJson(data);
  }

  /// 读取可用于学期计算的定义。
  @override
  Future<List<AcademicTermDefinition>> readCachedTermDefinitions() async {
    final entries = await readCachedCalendars();
    return termDefinitionsFromEntries(entries);
  }

  /// 从缓存条目转换学期定义。
  static List<AcademicTermDefinition> termDefinitionsFromEntries(
    List<AcademicCalendarCacheEntry> entries,
  ) {
    return entries
        .where((entry) => entry.schedule != null)
        .expand((entry) => entry.schedule!.toTermDefinitions())
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  static AcademicCalendarCacheEntry? _findEntryBySchoolYear(
    List<AcademicCalendarCacheEntry> entries,
    int schoolYear,
  ) {
    for (final entry in entries) {
      if (entry.schoolYearStart == schoolYear) return entry;
    }
    return null;
  }

  /// 计算某日期需要的校历学年。
  static List<int> requiredSchoolYearsForDate(DateTime date) {
    final normalized = AcademicTermDefinition.dateOnly(date);
    final schoolYear = normalized.month >= 9
        ? normalized.year
        : normalized.year - 1;
    final years = <int>{schoolYear};
    if (normalized.month == 7 || normalized.month == 8) {
      years.add(schoolYear + 1);
    }
    return years.toList()..sort();
  }

  /// 构建列表页 URL。
  static String buildListUrl(int page) {
    if (page <= 1) return '$baseUrl$calendarListPath';
    return '$baseUrl/xl/list$page.htm';
  }

  /// 解析列表页。
  static List<AcademicCalendarListItem> parseCalendarList(
    String htmlText, {
    String baseUrl = baseUrl,
  }) {
    final document = html_parser.parse(htmlText);
    final items = <AcademicCalendarListItem>[];
    for (final node in document.querySelectorAll(
      '.col_news_con ul.news_list li.news',
    )) {
      final anchor = node.querySelector('span.news_title a');
      if (anchor == null) continue;
      final title = anchor.attributes['title']?.trim() ?? anchor.text.trim();
      final href = anchor.attributes['href']?.trim() ?? '';
      if (title.isEmpty || href.isEmpty) continue;

      final yearMatch = RegExp(
        r'(20\d{2})\s*[-—－]\s*(20\d{2})\s*(?:学年|年)',
      ).firstMatch(title);
      if (yearMatch == null) continue;

      final startYear = int.parse(yearMatch.group(1)!);
      final endYear = int.parse(yearMatch.group(2)!);
      if (startYear < 2021) continue;

      final dateNode = node.querySelector('span.news_meta');
      items.add(
        AcademicCalendarListItem(
          title: title,
          detailUrl: _resolveUrl(baseUrl, href),
          publishDate: dateNode?.text.trim() ?? '',
          schoolYearStart: startYear,
          schoolYearEnd: endYear,
        ),
      );
    }
    return items;
  }

  /// 判断列表页是否存在下一页。
  static bool hasNextPage(String htmlText) {
    final document = html_parser.parse(htmlText);
    final next = document.querySelector('.wp_paging a.next[href]');
    final href = next?.attributes['href']?.trim() ?? '';
    return href.isNotEmpty && !href.startsWith('javascript:');
  }

  /// 解析详情页资源。
  static AcademicCalendarAssets parseCalendarDetailAssets(
    String htmlText, {
    String baseUrl = baseUrl,
  }) {
    final document = html_parser.parse(htmlText);
    final article =
        document.querySelector('.wp_articlecontent') ??
        document.querySelector('.article') ??
        document.body;
    if (article == null) {
      return const AcademicCalendarAssets(
        pdfUrl: null,
        imageUrls: [],
        sourceType: AcademicCalendarSourceType.unknown,
      );
    }

    String? pdfUrl;
    final pdfPlayer = article.querySelector('div.wp_pdf_player[pdfsrc]');
    final pdfPlayerSrc = pdfPlayer?.attributes['pdfsrc']?.trim() ?? '';
    if (pdfPlayerSrc.isNotEmpty) {
      pdfUrl = _resolveUrl(baseUrl, pdfPlayerSrc);
    }

    pdfUrl ??= article
        .querySelectorAll('a[href]')
        .map((anchor) => anchor.attributes['href']?.trim() ?? '')
        .where((href) => href.toLowerCase().split('?').first.endsWith('.pdf'))
        .map((href) => _resolveUrl(baseUrl, href))
        .cast<String?>()
        .firstWhere((value) => value != null, orElse: () => null);

    final imageUrls = article
        .querySelectorAll('img[src]')
        .map((image) => image.attributes['src']?.trim() ?? '')
        .where((src) => src.isNotEmpty && !src.contains('_visitcount'))
        .map((src) => _resolveUrl(baseUrl, src))
        .toList();

    final sourceType = pdfUrl != null && imageUrls.isNotEmpty
        ? AcademicCalendarSourceType.mixed
        : pdfUrl != null
        ? AcademicCalendarSourceType.pdf
        : imageUrls.isNotEmpty
        ? AcademicCalendarSourceType.image
        : AcademicCalendarSourceType.unknown;

    return AcademicCalendarAssets(
      pdfUrl: pdfUrl,
      imageUrls: imageUrls,
      sourceType: sourceType,
    );
  }

  /// 从 PDF 文本解析结构化学期。
  static AcademicCalendarTermSchedule? parseTermScheduleFromText(
    String text, {
    required int schoolYearStart,
  }) {
    final normalized = _normalizeText(text);
    final fallStart = _extractTermStart(
      normalized,
      '秋季',
      defaultYear: schoolYearStart,
    );
    final springStart = _extractTermStart(
      normalized,
      '春季',
      defaultYear: schoolYearStart + 1,
    );
    final summerStageMatches = RegExp(
      r'第[一二1-2]阶段[：:\s\S]{0,80}?'
      r'((?:20\d{2}年)?\d{1,2}月\d{1,2}日)[^。；;\n]{0,40}?开始'
      r'[\s\S]{0,80}?((?:20\d{2}年)?\d{1,2}月\d{1,2}日)[^。；;\n]{0,40}?结束',
    ).allMatches(normalized).toList();

    if (fallStart == null ||
        springStart == null ||
        summerStageMatches.length < 2) {
      return null;
    }

    final summerSegments = <AcademicTermTeachingSegment>[];
    for (var index = 0; index < 2; index++) {
      final match = summerStageMatches[index];
      final start = _parseChineseDate(
        match.group(1)!,
        defaultYear: index == 0 ? schoolYearStart + 1 : schoolYearStart + 1,
      );
      final end = _parseChineseDate(match.group(2)!, defaultYear: start.year);
      final weekCount = _weekCountInclusive(start, end);
      if (end.isBefore(start)) return null;
      final previousEndWeek = summerSegments.isEmpty
          ? 0
          : summerSegments.last.endWeek;
      summerSegments.add(
        AcademicTermTeachingSegment(
          startDate: start,
          endDate: end,
          startWeek: previousEndWeek + 1,
          endWeek: previousEndWeek + weekCount,
        ),
      );
    }

    final fallEnd = fallStart.add(
      Duration(days: AcademicTermSeason.fall.totalWeeks * 7 - 1),
    );
    final springEnd = springStart.add(
      Duration(days: AcademicTermSeason.spring.totalWeeks * 7 - 1),
    );
    final summerStart = summerSegments.first.startDate;
    final summerEnd = summerSegments.last.endDate;
    final warnings = <String>[];

    if (!fallStart.isBefore(springStart)) {
      return null;
    }
    if (summerSegments.length >= 2 &&
        !summerSegments.first.endDate.isBefore(summerSegments.last.startDate)) {
      return null;
    }
    if (summerSegments.last.endWeek != AcademicTermSeason.summer.totalWeeks) {
      warnings.add('夏季学期解析得到 ${summerSegments.last.endWeek} 周。');
    }
    if (summerStart.isBefore(springEnd.subtract(const Duration(days: 14)))) {
      warnings.add('夏季第一阶段开始时间早于春季结束附近。');
    }

    return AcademicCalendarTermSchedule(
      schoolYearStart: schoolYearStart,
      fallStart: fallStart,
      fallEnd: fallEnd,
      springStart: springStart,
      springEnd: springEnd,
      summerStart: summerStart,
      summerEnd: summerEnd,
      summerSegments: summerSegments,
      dayTags: _parseDayTags(normalized, schoolYearStart: schoolYearStart),
      pendingHolidayNotices: _parsePendingHolidayNotices(normalized),
      parseWarnings: warnings,
    );
  }

  static List<AcademicCalendarDayTag> _parseDayTags(
    String text, {
    required int schoolYearStart,
  }) {
    final tags = <AcademicCalendarDayTag>[];
    final sportsMatch = RegExp(
      r'校运会[：:\s]*(\d{1,2}月\d{1,2}日)[^。；;\n]*(停课一天|停课)',
    ).firstMatch(text);
    if (sportsMatch != null) {
      final source = sportsMatch.group(0)!;
      tags.add(
        AcademicCalendarDayTag(
          date: _parseChineseDate(
            sportsMatch.group(1)!,
            defaultYear: schoolYearStart,
          ),
          type: AcademicCalendarDayTagType.sportsDay,
          label: '校运会停课一天',
          sourceText: source,
        ),
      );
    }
    for (final match in RegExp(
      r'[^。；;\n]*(\d{1,2}月\d{1,2}日)[^。；;\n]*(?:上班|上课|补班|休息|放假|停课)[^。；;\n]*',
    ).allMatches(text)) {
      final source = match.group(0)?.trim();
      final rawDate = match.group(1);
      if (source == null || source.isEmpty || rawDate == null) continue;
      if (source.contains('另行通知') || source.contains('国务院办公厅公布')) {
        continue;
      }
      if (source.contains('校运会')) continue;
      final type = _dayTagTypeForSource(source);
      if (type == null) continue;
      final date = _parseChineseDate(rawDate, defaultYear: schoolYearStart);
      if (tags.any((tag) => tag.date == date && tag.type == type)) continue;
      tags.add(
        AcademicCalendarDayTag(
          date: date,
          type: type,
          label: _dayTagLabelForSource(source, type),
          sourceText: source,
        ),
      );
    }
    return tags;
  }

  static AcademicCalendarDayTagType? _dayTagTypeForSource(String source) {
    if (source.contains('校运会')) return AcademicCalendarDayTagType.sportsDay;
    if (source.contains('放假') || source.contains('停课')) {
      return AcademicCalendarDayTagType.holiday;
    }
    if (source.contains('休息')) return AcademicCalendarDayTagType.restDay;
    if (source.contains('上班') ||
        source.contains('上课') ||
        source.contains('补班')) {
      return AcademicCalendarDayTagType.workday;
    }
    return null;
  }

  static String _dayTagLabelForSource(
    String source,
    AcademicCalendarDayTagType type,
  ) {
    if (source.contains('校运会')) return '校运会停课一天';
    return switch (type) {
      AcademicCalendarDayTagType.workday => '工作日调整',
      AcademicCalendarDayTagType.restDay => '休息日',
      AcademicCalendarDayTagType.holiday => '假期',
      AcademicCalendarDayTagType.sportsDay => '运动会停课日',
    };
  }

  static List<AcademicCalendarPendingHolidayNotice> _parsePendingHolidayNotices(
    String text,
  ) {
    final notices = <AcademicCalendarPendingHolidayNotice>[];
    for (final match in RegExp(
      r'[^。；;\n]*(?:放假安排|节假日安排)[^。；;\n]*(?:另行通知|国务院办公厅公布)[^。；;\n]*',
    ).allMatches(text)) {
      final source = match.group(0)?.trim();
      if (source == null || source.isEmpty) continue;
      notices.add(AcademicCalendarPendingHolidayNotice(sourceText: source));
    }
    return notices;
  }

  static DateTime? _extractTermStart(
    String text,
    String seasonName, {
    required int defaultYear,
  }) {
    final match = RegExp(
      r'((?:20\d{2}年)?\d{1,2}月\d{1,2}日)[^。；;\n]{0,50}?'
      '$seasonName学期开始',
    ).firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)!;
    return _parseChineseDate(raw, defaultYear: defaultYear);
  }

  static DateTime _parseChineseDate(String raw, {required int defaultYear}) {
    final match = RegExp(
      r'(?:(20\d{2})年)?(\d{1,2})月(\d{1,2})日',
    ).firstMatch(raw);
    if (match == null) {
      throw FormatException('无法解析日期：$raw');
    }
    return DateTime(
      int.tryParse(match.group(1) ?? '') ?? defaultYear,
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static int _weekCountInclusive(DateTime start, DateTime end) {
    final days =
        AcademicTermDefinition.dateOnly(
          end,
        ).difference(AcademicTermDefinition.dateOnly(start)).inDays +
        1;
    return (days / 7).ceil();
  }

  static String _normalizeText(String text) {
    return text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), '')
        .replaceAll('（', '(')
        .replaceAll('）', ')');
  }

  static String _resolveUrl(String baseUrl, String rawUrl) {
    final baseUri = Uri.parse(baseUrl);
    return baseUri.resolve(rawUrl).toString();
  }
}
