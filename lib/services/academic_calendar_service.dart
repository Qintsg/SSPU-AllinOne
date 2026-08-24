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

part 'academic_calendar_service_parsers.dart';

/// PDF 文本抽取函数。
typedef AcademicCalendarPdfTextExtractor =
    Future<String> Function(String pdfFilePath);

/// 校历只读客户端。
abstract class AcademicCalendarClient {
  /// 按日期确保当前学年和临近学年校历存在。
  Future<AcademicCalendarSyncResult> ensureCalendarsForDate({DateTime? now});

  /// 按页面访问节流策略确保校历 PDF 缓存存在。
  Future<AcademicCalendarSyncResult> ensureCalendarsForViewer({DateTime? now});

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

  /// 校历页自动刷新间隔。
  static const Duration viewerAutoRefreshInterval = Duration(days: 30);

  final HttpService _http;
  final AcademicCalendarPdfTextExtractor _pdfTextExtractor;
  Future<void>? _pendingEnsure;

  /// 按页面访问节流策略确保校历 PDF 缓存存在。
  @override
  Future<AcademicCalendarSyncResult> ensureCalendarsForViewer({
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    final cached = await readCachedCalendars();
    final lastRefresh = await _readLastViewerAutoRefreshAt();
    final shouldRefresh =
        cached.isEmpty ||
        lastRefresh == null ||
        resolvedNow.difference(lastRefresh) >= viewerAutoRefreshInterval;
    if (!shouldRefresh) {
      return AcademicCalendarSyncResult(
        entries: cached,
        loadedFromCache: cached.isNotEmpty,
        refreshed: false,
      );
    }

    try {
      await refreshCalendars();
      await StorageService.setString(
        StorageKeys.academicCalendarLastAutoRefreshAt,
        resolvedNow.toUtc().toIso8601String(),
      );
      final entries = await readCachedCalendars();
      return AcademicCalendarSyncResult(
        entries: entries,
        loadedFromCache: cached.isNotEmpty,
        refreshed: true,
      );
    } catch (error) {
      return AcademicCalendarSyncResult(
        entries: cached,
        loadedFromCache: cached.isNotEmpty,
        refreshed: false,
        errorMessage: HttpService.describeError(error),
      );
    }
  }

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

  static Future<DateTime?> _readLastViewerAutoRefreshAt() async {
    final raw = await StorageService.getString(
      StorageKeys.academicCalendarLastAutoRefreshAt,
    );
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
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
}
