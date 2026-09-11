import 'dart:convert';

import '../models/academic_eams.dart';
import '../models/academic_term.dart';
import '../models/course_period.dart';
import '../utils/course_week_parser.dart';

/// 将课表与考试快照转换为 RFC 5545 日历文本。
///
/// 生成器只做纯内存计算，不访问网络、不写文件，也不会把账号信息写入事件。
class AcademicIcsExportService {
  const AcademicIcsExportService._();

  static String buildCalendar({
    required AcademicCourseTableSnapshot? courseTable,
    required AcademicExamSnapshot? exams,
    required AcademicTermDefinition? term,
    DateTime? generatedAt,
    String calendarName = 'SSPU 课程与考试',
  }) {
    final events = buildEvents(
      courseTable: courseTable,
      exams: exams,
      term: term,
    );
    return buildCalendarFromEvents(
      events: events,
      generatedAt: generatedAt,
      calendarName: calendarName,
    );
  }

  /// 将已归一化的校园日程事件导出为 RFC 5545 文本。
  static String buildCalendarFromEvents({
    required List<AcademicCalendarEvent> events,
    DateTime? generatedAt,
    String calendarName = 'SSPU 课程与考试',
  }) {
    // RFC 5545 要求 DTSTAMP 使用 UTC（末尾 Z）；事件开始/结束时间仍保留
    // 上海墙上时间，避免把用户设备时区误当成课程时区。
    final stamp = _formatDateTime(generatedAt ?? DateTime.now(), utc: true);
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//SSPU-AllinOne//Academic Calendar//CN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:${_escape(calendarName)}',
      'X-WR-TIMEZONE:Asia/Shanghai',
      'BEGIN:VTIMEZONE',
      'TZID:Asia/Shanghai',
      'X-LIC-LOCATION:Asia/Shanghai',
      'BEGIN:STANDARD',
      'TZOFFSETFROM:+0800',
      'TZOFFSETTO:+0800',
      'TZNAME:CST',
      'DTSTART:19700101T000000',
      'END:STANDARD',
      'END:VTIMEZONE',
      for (final event in events) ...[
        'BEGIN:VEVENT',
        'UID:${_uid('${event.type.name}|${event.title}|${_formatDateTime(event.start)}|${event.location}')}',
        'DTSTAMP:$stamp',
        'DTSTART;TZID=Asia/Shanghai:${_formatDateTime(event.start)}',
        'DTEND;TZID=Asia/Shanghai:${_formatDateTime(event.end)}',
        'SUMMARY:${_escape(event.title)}',
        'LOCATION:${_escape(event.location)}',
        'DESCRIPTION:${_escape(event.description)}',
        'END:VEVENT',
      ],
      'END:VCALENDAR',
    ];
    final foldedLines = <String>[];
    for (final line in lines) {
      foldedLines.addAll(_foldLine(line));
    }
    return '${foldedLines.join('\r\n')}\r\n';
  }

  /// 构造供应用内日历与 ICS 导出共同使用的结构化事件。
  static List<AcademicCalendarEvent> buildEvents({
    required AcademicCourseTableSnapshot? courseTable,
    required AcademicExamSnapshot? exams,
    required AcademicTermDefinition? term,
  }) {
    final events = <AcademicCalendarEvent>[];
    if (courseTable != null && term != null) {
      events.addAll(_courseEvents(courseTable, term));
    }
    if (exams != null) events.addAll(_examEvents(exams));
    events.sort((left, right) => left.start.compareTo(right.start));
    return events;
  }

  static Iterable<AcademicCalendarEvent> _courseEvents(
    AcademicCourseTableSnapshot snapshot,
    AcademicTermDefinition term,
  ) sync* {
    for (
      var date = term.startDate;
      !date.isAfter(term.endDate);
      date = date.add(const Duration(days: 1))
    ) {
      final segment = term.teachingSegmentFor(date);
      if (segment == null) continue;
      final week = segment.resolveWeek(date);
      for (final course in snapshot.entries) {
        if (course.weekday != date.weekday ||
            !CourseWeekParser.parse(course.weekDescription).contains(week)) {
          continue;
        }
        final period = CoursePeriodTable.standard.periodOf(course.startUnit);
        final endPeriod = CoursePeriodTable.standard.periodOf(course.endUnit);
        final start = _atTime(date, period?.startTime);
        final end = _atTime(date, endPeriod?.endTime);
        if (start == null || end == null) continue;
        final location = course.location?.trim();
        final description = [
          if (course.teacher?.trim().isNotEmpty == true)
            '教师：${course.teacher!.trim()}',
          if (course.weekDescription?.trim().isNotEmpty == true)
            '周次：${course.weekDescription!.trim()}',
        ].join('；');
        yield AcademicCalendarEvent(
          type: AcademicCalendarEventType.course,
          title: course.courseName,
          start: start,
          end: end,
          location: location ?? '',
          description: description,
        );
      }
    }
  }

  static Iterable<AcademicCalendarEvent> _examEvents(
    AcademicExamSnapshot snapshot,
  ) sync* {
    for (final exam in snapshot.records) {
      final date = _parseDate(exam.displayExamDate);
      if (date == null) continue;
      final start = _atTime(date, exam.displayExamArrange);
      final end = _atEndTime(date, exam.displayExamArrange);
      // 没有完整时间范围时不猜测开始时间或考试时长。
      if (start == null || end == null || !end.isAfter(start)) continue;
      final location = exam.displayExamLocation?.trim();
      final details = exam.displayOtherExplanation?.trim();
      yield AcademicCalendarEvent(
        type: AcademicCalendarEventType.exam,
        title: '考试：${exam.courseName}',
        start: start,
        end: end,
        location: location ?? '',
        description: details ?? '',
      );
    }
  }

  static DateTime? _atTime(DateTime date, String? source) {
    final match = RegExp(
      r'([01]?\d|2[0-3]):([0-5]\d)',
    ).firstMatch(source ?? '');
    if (match == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  static DateTime? _atEndTime(DateTime date, String? source) {
    final matches = RegExp(
      r'([01]?\d|2[0-3]):([0-5]\d)',
    ).allMatches(source ?? '');
    if (matches.length < 2) return null;
    final match = matches.elementAt(1);
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  static DateTime? _parseDate(String? source) {
    final value = source?.trim() ?? '';
    final iso = RegExp(
      r'(\d{4})[-年./](\d{1,2})[-月./](\d{1,2})',
    ).firstMatch(value);
    if (iso == null) return null;
    return DateTime(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }

  static String _formatDateTime(DateTime value, {bool utc = false}) {
    // 非 UTC 值来自校园教务系统，字段本身就是 Asia/Shanghai 墙上时间；
    // 不调用 toLocal()，否则设备处于其他时区时会错误平移事件时间。
    final normalized = utc ? value.toUtc() : value;
    String two(int n) => n.toString().padLeft(2, '0');
    final formatted =
        '${normalized.year.toString().padLeft(4, '0')}${two(normalized.month)}${two(normalized.day)}T${two(normalized.hour)}${two(normalized.minute)}${two(normalized.second)}';
    return utc ? '${formatted}Z' : formatted;
  }

  static String _uid(String source) {
    var hash = 0x811c9dc5;
    for (final unit in source.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return 'sspu-$hash@allinone';
  }

  static String _escape(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\r\n', '\\n')
        .replaceAll('\r', '\\n')
        .replaceAll('\n', '\\n');
  }

  /// 按 RFC 5545 以 UTF-8 八位字节折叠内容行，避免截断多字节字符。
  static List<String> _foldLine(String line) {
    if (utf8.encode(line).length <= 75) return [line];
    final result = <String>[];
    var current = StringBuffer();
    var bytes = 0;
    var limit = 75;
    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final characterBytes = utf8.encode(character).length;
      if (current.isNotEmpty && bytes + characterBytes > limit) {
        result.add(current.toString());
        current = StringBuffer(' ');
        bytes = 1;
        limit = 75;
      }
      current.write(character);
      bytes += characterBytes;
    }
    if (current.isNotEmpty) result.add(current.toString());
    return result;
  }
}

enum AcademicCalendarEventType { course, exam }

/// 课程与考试统一日历事件，作为应用内视图和 ICS 的单一数据源。
class AcademicCalendarEvent {
  const AcademicCalendarEvent({
    required this.type,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.description,
  });

  final AcademicCalendarEventType type;
  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final String description;
}
