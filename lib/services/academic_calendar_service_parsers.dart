/*
 * 校历服务解析器 — 列表页与详情页 HTML 解析
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_service_parsers.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'academic_calendar_service.dart';

/// 解析列表页。
List<AcademicCalendarListItem> parseCalendarList(
  String htmlText, {
  String baseUrl = AcademicCalendarService.baseUrl,
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

    final yearMatch = RegExp(r'(20\d{2})\s*[-—－]\s*(20\d{2})\s*(?:学年|年)')
        .firstMatch(title);
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
bool hasNextPage(String htmlText) {
  final document = html_parser.parse(htmlText);
  final next = document.querySelector('.wp_paging a.next[href]');
  final href = next?.attributes['href']?.trim() ?? '';
  return href.isNotEmpty && !href.startsWith('javascript:');
}

/// 解析详情页资源。
AcademicCalendarAssets parseCalendarDetailAssets(
  String htmlText, {
  String baseUrl = AcademicCalendarService.baseUrl,
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
AcademicCalendarTermSchedule? parseTermScheduleFromText(
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

List<AcademicCalendarDayTag> _parseDayTags(
  String text, {
  required int schoolYearStart,
}) {
  final tags = <AcademicCalendarDayTag>[];
  final sportsMatch = RegExp(r'校运会[：:\s]*(\d{1,2}月\d{1,2}日)[^。；;\n]*(停课一天|停课)')
      .firstMatch(text);
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

AcademicCalendarDayTagType? _dayTagTypeForSource(String source) {
  if (source.contains('校运会')) return AcademicCalendarDayTagType.sportsDay;
  if (source.contains('放假') || source.contains('停课')) {
    return AcademicCalendarDayTagType.holiday;
  }
  if (source.contains('休息')) return AcademicCalendarDayTagType.restDay;
  if (source.contains('上班') || source.contains('上课') || source.contains('补班')) {
    return AcademicCalendarDayTagType.workday;
  }
  return null;
}

String _dayTagLabelForSource(String source, AcademicCalendarDayTagType type) {
  if (source.contains('校运会')) return '校运会停课一天';
  return switch (type) {
    AcademicCalendarDayTagType.workday => '工作日调整',
    AcademicCalendarDayTagType.restDay => '休息日',
    AcademicCalendarDayTagType.holiday => '假期',
    AcademicCalendarDayTagType.sportsDay => '运动会停课日',
  };
}

List<AcademicCalendarPendingHolidayNotice> _parsePendingHolidayNotices(
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

DateTime? _extractTermStart(
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

DateTime _parseChineseDate(String raw, {required int defaultYear}) {
  final match = RegExp(r'(?:(20\d{2})年)?(\d{1,2})月(\d{1,2})日').firstMatch(raw);
  if (match == null) {
    throw FormatException('无法解析日期：$raw');
  }
  return DateTime(
    int.tryParse(match.group(1) ?? '') ?? defaultYear,
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

int _weekCountInclusive(DateTime start, DateTime end) {
  final days =
      AcademicTermDefinition.dateOnly(end)
          .difference(AcademicTermDefinition.dateOnly(start))
          .inDays +
      1;
  return (days / 7).ceil();
}

String _normalizeText(String text) {
  return text
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t]+'), '')
      .replaceAll('（', '(')
      .replaceAll('）', ')');
}

String _resolveUrl(String baseUrl, String rawUrl) {
  final baseUri = Uri.parse(baseUrl);
  return baseUri.resolve(rawUrl).toString();
}
