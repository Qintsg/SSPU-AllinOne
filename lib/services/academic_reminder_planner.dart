/* 教务提醒计划器 — 将课表与考试快照转为本地调度请求。 */

import '../models/academic_eams.dart';
import '../models/academic_term.dart';
import '../models/course_period.dart';
import '../utils/course_week_parser.dart';

enum AcademicReminderKind { course, exam }

/// 一条可交给系统通知适配器的提醒请求。
class AcademicReminderRequest {
  const AcademicReminderRequest({
    required this.id,
    required this.kind,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final int id;
  final AcademicReminderKind kind;
  final DateTime scheduledAt;
  final String title;
  final String body;
}

/// 只负责时间和文案计算，不读写设置、缓存或平台通知。
class AcademicReminderPlanner {
  AcademicReminderPlanner._();

  static List<AcademicReminderRequest> plan({
    required AcademicCourseTableSnapshot? courseTable,
    required AcademicExamSnapshot? exams,
    required AcademicTermDefinition? term,
    required DateTime now,
    required Duration horizon,
    required Duration courseLeadTime,
    required Duration examLeadTime,
  }) {
    final reminders = <AcademicReminderRequest>[
      if (courseTable != null && term != null)
        ..._courseReminders(
          courseTable,
          term,
          now: now,
          horizon: horizon,
          leadTime: courseLeadTime,
        ),
      if (exams != null)
        ..._examReminders(
          exams,
          now: now,
          horizon: horizon,
          leadTime: examLeadTime,
        ),
    ]..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return List.unmodifiable(reminders);
  }

  static Iterable<AcademicReminderRequest> _courseReminders(
    AcademicCourseTableSnapshot snapshot,
    AcademicTermDefinition term, {
    required DateTime now,
    required Duration horizon,
    required Duration leadTime,
  }) sync* {
    final lastReminderAt = now.add(horizon);
    var date = AcademicTermDefinition.dateOnly(now);
    final lastDate = AcademicTermDefinition.dateOnly(
      lastReminderAt.add(leadTime),
    );
    while (!date.isAfter(lastDate) && !date.isAfter(term.endDate)) {
      final segment = term.teachingSegmentFor(date);
      if (segment != null) {
        final week = segment.resolveWeek(date);
        for (final course in snapshot.entries) {
          if (course.weekday != date.weekday ||
              !CourseWeekParser.parse(course.weekDescription).contains(week)) {
            continue;
          }
          final period = CoursePeriodTable.standard.periodOf(course.startUnit);
          final start = _dateWithTime(date, period?.startTime);
          if (start == null) continue;
          final scheduledAt = start.subtract(leadTime);
          if (!scheduledAt.isAfter(now) ||
              scheduledAt.isAfter(lastReminderAt)) {
            continue;
          }
          final location = course.location?.trim();
          final body = [
            period?.startTime ?? course.timeText,
            if (location != null && location.isNotEmpty) location,
          ].join(' · ');
          yield AcademicReminderRequest(
            id: _stableId(
              'course|${course.courseName}|${start.toIso8601String()}|$location',
            ),
            kind: AcademicReminderKind.course,
            scheduledAt: scheduledAt,
            title: '即将上课：${course.courseName}',
            body: body,
          );
        }
      }
      date = date.add(const Duration(days: 1));
    }
  }

  static Iterable<AcademicReminderRequest> _examReminders(
    AcademicExamSnapshot snapshot, {
    required DateTime now,
    required Duration horizon,
    required Duration leadTime,
  }) sync* {
    final lastReminderAt = now.add(horizon);
    for (final exam in snapshot.records) {
      final date = _parseDate(exam.displayExamDate);
      if (date == null) continue;
      final start = _dateWithTime(date, exam.displayExamArrange);
      // 缺少明确考试时间时不猜测 09:00，避免错误提醒。
      if (start == null) continue;
      final scheduledAt = start.subtract(leadTime);
      if (!scheduledAt.isAfter(now) || scheduledAt.isAfter(lastReminderAt)) {
        continue;
      }
      final time = _firstTime(exam.displayExamArrange)!;
      final location = exam.displayExamLocation?.trim();
      yield AcademicReminderRequest(
        id: _stableId(
          'exam|${exam.courseName}|${start.toIso8601String()}|$location',
        ),
        kind: AcademicReminderKind.exam,
        scheduledAt: scheduledAt,
        title: leadTime.inHours >= 12
            ? '明日考试：${exam.courseName}'
            : '即将考试：${exam.courseName}',
        body: [
          time,
          if (location != null && location.isNotEmpty) location,
        ].join(' · '),
      );
    }
  }

  static DateTime? _dateWithTime(DateTime date, String? source) {
    final time = _firstTime(source);
    if (time == null) return null;
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static DateTime? _parseDate(String? source) {
    final value = source?.trim() ?? '';
    final match = RegExp(
      r'(20\d{2})[-年./](\d{1,2})[-月./](\d{1,2})',
    ).firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static String? _firstTime(String? source) {
    final match = RegExp(
      r'([01]?\d|2[0-3]):([0-5]\d)',
    ).firstMatch(source ?? '');
    if (match == null) return null;
    final hour = int.parse(match.group(1)!).toString().padLeft(2, '0');
    return '$hour:${match.group(2)}';
  }

  static int _stableId(String source) {
    var hash = 0x811c9dc5;
    for (final unit in source.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
