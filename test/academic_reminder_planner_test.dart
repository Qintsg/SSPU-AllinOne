import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/services/academic_reminder_planner.dart';

void main() {
  test('课程与考试转为稳定、可预期的本地提醒请求', () {
    final term = AcademicTermDefinition(
      choice: const AcademicTermChoice(
        academicYear: 2026,
        season: AcademicTermSeason.fall,
      ),
      startDate: DateTime(2026, 9, 21),
      endDate: DateTime(2027, 1, 17),
      teachingSegments: [
        AcademicTermTeachingSegment(
          startDate: DateTime(2026, 9, 21),
          endDate: DateTime(2027, 1, 17),
          startWeek: 1,
          endWeek: 17,
        ),
      ],
    );
    final courseTable = AcademicCourseTableSnapshot(
      entries: const [
        AcademicCourseTableEntry(
          courseName: '高等数学',
          weekday: DateTime.monday,
          startUnit: 1,
          endUnit: 2,
          timeText: '周一 第1-2节',
          rawText: '高等数学',
          location: '教学楼 101',
          weekDescription: '1-2周',
        ),
      ],
      fetchedAt: DateTime(2026, 9, 20),
      sourceUri: Uri.parse('https://jx.sspu.edu.cn/course-table'),
    );
    final exams = AcademicExamSnapshot(
      records: const [
        AcademicExamRecord(
          courseName: '大学英语',
          examDate: '2026-09-30',
          examArrange: '09:00-11:00',
          examLocation: '教学楼 202',
          rawCells: [],
        ),
      ],
      fetchedAt: DateTime(2026, 9, 20),
      sourceUri: Uri.parse('https://jx.sspu.edu.cn/exams'),
    );

    final reminders = AcademicReminderPlanner.plan(
      courseTable: courseTable,
      exams: exams,
      term: term,
      now: DateTime(2026, 9, 20, 12),
      horizon: const Duration(days: 30),
      courseLeadTime: const Duration(minutes: 15),
      examLeadTime: const Duration(days: 1),
    );

    expect(reminders, hasLength(3));
    expect(reminders[0].kind, AcademicReminderKind.course);
    expect(reminders[0].scheduledAt, DateTime(2026, 9, 21, 7, 45));
    expect(reminders[0].title, '即将上课：高等数学');
    expect(reminders[0].body, '08:00 · 教学楼 101');
    expect(reminders[1].scheduledAt, DateTime(2026, 9, 28, 7, 45));
    expect(reminders[2].kind, AcademicReminderKind.exam);
    expect(reminders[2].scheduledAt, DateTime(2026, 9, 29, 9));
    expect(reminders[2].title, '明日考试：大学英语');
    expect(reminders[2].body, '09:00 · 教学楼 202');
    expect(reminders.map((reminder) => reminder.id).toSet(), hasLength(3));
  });

  test('考试日期兼容中文格式，缺少考试时间时不猜测提醒时间', () {
    final exams = AcademicExamSnapshot(
      records: const [
        AcademicExamRecord(
          courseName: '中文日期考试',
          examDate: '2026年9月30日',
          examArrange: '09:00-11:00',
          examLocation: '教学楼 202',
          rawCells: [],
        ),
        AcademicExamRecord(
          courseName: '无时间考试',
          examDate: '2026年10月1日',
          examArrange: '-',
          examLocation: '教学楼 203',
          rawCells: [],
        ),
      ],
      fetchedAt: DateTime(2026, 9, 20),
      sourceUri: Uri.parse('https://jx.sspu.edu.cn/exams'),
    );
    final reminders = AcademicReminderPlanner.plan(
      courseTable: null,
      exams: exams,
      term: null,
      now: DateTime(2026, 9, 20, 12),
      horizon: const Duration(days: 30),
      courseLeadTime: const Duration(minutes: 15),
      examLeadTime: const Duration(days: 1),
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.scheduledAt, DateTime(2026, 9, 29, 9));
  });
}
