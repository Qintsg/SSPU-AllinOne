import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/services/academic_ics_export_service.dart';

void main() {
  test('导出包含课程、考试、转义文本并使用 CRLF', () {
    final term = AcademicTermDefinition(
      choice: const AcademicTermChoice(
        academicYear: 2025,
        season: AcademicTermSeason.fall,
      ),
      startDate: DateTime(2025, 9, 22),
      endDate: DateTime(2025, 9, 28),
      teachingSegments: [
        AcademicTermTeachingSegment(
          startDate: DateTime(2025, 9, 22),
          endDate: DateTime(2025, 9, 28),
          startWeek: 1,
          endWeek: 1,
        ),
      ],
    );
    final course = AcademicCourseTableSnapshot(
      entries: [
        const AcademicCourseTableEntry(
          courseName: '数据库,原理',
          weekday: 1,
          startUnit: 1,
          endUnit: 2,
          timeText: '',
          rawText: '',
          location: 'A;101',
          weekDescription: '1周',
        ),
      ],
      fetchedAt: DateTime(2025, 9, 1),
      sourceUri: Uri.parse('https://example.test'),
    );
    final exams = AcademicExamSnapshot(
      records: [
        const AcademicExamRecord(
          courseName: '高等数学',
          rawCells: [],
          examDate: '2025年9月27日',
          examArrange: '14:00-16:00',
          examLocation: 'B-202',
        ),
      ],
      fetchedAt: DateTime(2025, 9, 1),
      sourceUri: Uri.parse('https://example.test'),
    );
    final ics = AcademicIcsExportService.buildCalendar(
      courseTable: course,
      exams: exams,
      term: term,
      generatedAt: DateTime.utc(2025, 9, 1),
    );
    expect(ics, contains('BEGIN:VCALENDAR\r\n'));
    expect(ics, contains('SUMMARY:数据库\\,原理'));
    expect(ics, contains('LOCATION:A\\;101'));
    expect(ics, contains('SUMMARY:考试：高等数学'));
    expect(ics, contains('DTSTART;TZID=Asia/Shanghai:20250922T080000'));
    expect(ics, contains('BEGIN:VTIMEZONE\r\n'));
    expect(ics, contains('TZID:Asia/Shanghai\r\n'));
    expect(ics, contains('TZOFFSETFROM:+0800\r\n'));
    expect(ics, contains('TZOFFSETTO:+0800\r\n'));
    expect(ics, contains('DTSTAMP:20250901T000000Z'));
    expect(ics, endsWith('END:VCALENDAR\r\n'));

    final events = AcademicIcsExportService.buildEvents(
      courseTable: course,
      exams: exams,
      term: term,
    );
    expect(events, hasLength(2));
    expect(events.first.type, AcademicCalendarEventType.course);
    expect(events.last.type, AcademicCalendarEventType.exam);
    expect(events.last.start, DateTime(2025, 9, 27, 14));
  });

  test('考试结束时间来自原始时间范围，缺少时间时不生成猜测事件', () {
    final exams = AcademicExamSnapshot(
      records: const [
        AcademicExamRecord(
          courseName: '有完整时间',
          rawCells: [],
          examDate: '2025年9月27日',
          examArrange: '14:00-16:00',
          examLocation: 'B-202',
        ),
        AcademicExamRecord(
          courseName: '没有时间',
          rawCells: [],
          examDate: '2025年9月28日',
          examArrange: '-',
          examLocation: 'B-203',
        ),
      ],
      fetchedAt: DateTime(2025, 9, 1),
      sourceUri: Uri.parse('https://example.test'),
    );

    final events = AcademicIcsExportService.buildEvents(
      courseTable: null,
      exams: exams,
      term: null,
    );

    expect(events, hasLength(1));
    expect(events.single.start, DateTime(2025, 9, 27, 14));
    expect(events.single.end, DateTime(2025, 9, 27, 16));
  });

  test('导出使用上海时区并按 RFC 5545 折叠超长 UTF-8 行', () {
    final exams = AcademicExamSnapshot(
      records: [
        AcademicExamRecord(
          courseName: '一门非常非常长的考试名称' * 12,
          rawCells: const [],
          examDate: '2025-09-27',
          examArrange: '14:00-16:00',
          examLocation: 'B-202',
          otherExplanation: '说明' * 80,
        ),
      ],
      fetchedAt: DateTime(2025, 9, 1),
      sourceUri: Uri.parse('https://example.test'),
    );

    final ics = AcademicIcsExportService.buildCalendar(
      courseTable: null,
      exams: exams,
      term: null,
      generatedAt: DateTime.utc(2025, 9, 1),
    );
    expect(ics, contains('DTSTART;TZID=Asia/Shanghai:20250927T140000'));
    expect(ics, contains('DTEND;TZID=Asia/Shanghai:20250927T160000'));
    final lines = ics.split('\r\n');
    for (final line in lines.where((line) => line.isNotEmpty)) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
    }
    expect(lines.any((line) => line.startsWith(' ')), isTrue);
  });

  test('上海墙上时间不随 DateTime 的设备时区语义发生平移', () {
    final ics = AcademicIcsExportService.buildCalendarFromEvents(
      events: [
        AcademicCalendarEvent(
          type: AcademicCalendarEventType.exam,
          title: '跨时区测试',
          start: DateTime.utc(2026, 1, 12, 14),
          end: DateTime.utc(2026, 1, 12, 16),
          location: '教学楼 101',
          description: '',
        ),
      ],
      generatedAt: DateTime.utc(2026, 1, 1),
    );

    expect(ics, contains('DTSTART;TZID=Asia/Shanghai:20260112T140000'));
    expect(ics, contains('DTEND;TZID=Asia/Shanghai:20260112T160000'));
  });
}
