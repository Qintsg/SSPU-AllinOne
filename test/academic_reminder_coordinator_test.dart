import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/services/academic_reminder_coordinator.dart';
import 'package:sspu_allinone/services/academic_reminder_planner.dart';
import 'package:sspu_allinone/services/notification_service.dart';

void main() {
  test('教务模块停止获取时立即清空提醒且不读取缓存', () async {
    var cacheReadCount = 0;
    final delivery = _FakeReminderDelivery();
    final coordinator = AcademicReminderCoordinator(
      delivery: delivery,
      isNotificationEnabled: () async => true,
      isCourseReminderEnabled: () async => true,
      isExamReminderEnabled: () async => true,
      isAcademicFetchEnabled: () async => false,
      loadCourseTable: () async {
        cacheReadCount += 1;
        return null;
      },
      loadExams: () async {
        cacheReadCount += 1;
        return null;
      },
      loadTermContext: () async => throw StateError('should not load'),
      isInDndPeriodAt: (_) async => false,
    );

    final result = await coordinator.sync();

    expect(result.status, AcademicReminderSyncStatus.moduleDisabled);
    expect(cacheReadCount, 0);
    expect(delivery.replacements.single, isEmpty);
  });

  test('启用时从本地缓存计划提醒并跳过勿扰时段', () async {
    final delivery = _FakeReminderDelivery();
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
    final coordinator = AcademicReminderCoordinator(
      delivery: delivery,
      isNotificationEnabled: () async => true,
      isCourseReminderEnabled: () async => true,
      isExamReminderEnabled: () async => false,
      getCourseLeadMinutes: () async => 15,
      isAcademicFetchEnabled: () async => true,
      loadCourseTable: () async => AcademicCourseTableSnapshot(
        entries: const [
          AcademicCourseTableEntry(
            courseName: '早课',
            weekday: DateTime.monday,
            startUnit: 1,
            endUnit: 2,
            timeText: '周一 第1-2节',
            rawText: '早课',
            weekDescription: '1周',
          ),
          AcademicCourseTableEntry(
            courseName: '晚课',
            weekday: DateTime.monday,
            startUnit: 11,
            endUnit: 12,
            timeText: '周一 第11-12节',
            rawText: '晚课',
            weekDescription: '1周',
          ),
        ],
        fetchedAt: DateTime(2026, 9, 20),
        sourceUri: Uri.parse('https://jx.sspu.edu.cn/course-table'),
      ),
      loadExams: () async => null,
      loadTermContext: () async => AcademicTermContext(
        term: term.choice,
        source: AcademicTermContextSource.automatic,
        dateStatus: AcademicTermDateStatus.teaching,
        resolvedAt: DateTime(2026, 9, 20, 12),
        isTeachingWeek: true,
        definition: term,
      ),
      isInDndPeriodAt: (time) async => time.hour >= 17,
      now: () => DateTime(2026, 9, 20, 12),
    );

    final result = await coordinator.sync();

    expect(result.status, AcademicReminderSyncStatus.scheduled);
    expect(result.scheduledCount, 1);
    expect(delivery.replacements.single.single.title, '即将上课：早课');
  });

  test('系统通知权限被拒绝时清空计划且不读取缓存', () async {
    var cacheReadCount = 0;
    final delivery = _FakeReminderDelivery(
      permission: NotificationPermissionStatus.denied,
    );
    final coordinator = AcademicReminderCoordinator(
      delivery: delivery,
      isNotificationEnabled: () async => true,
      isCourseReminderEnabled: () async => true,
      isExamReminderEnabled: () async => true,
      isAcademicFetchEnabled: () async => true,
      loadCourseTable: () async {
        cacheReadCount++;
        return null;
      },
      loadExams: () async {
        cacheReadCount++;
        return null;
      },
      loadTermContext: () async => throw StateError('should not load'),
      isInDndPeriodAt: (_) async => false,
    );

    final result = await coordinator.sync();

    expect(result.status, AcademicReminderSyncStatus.permissionDenied);
    expect(cacheReadCount, 0);
    expect(delivery.replacements.single, isEmpty);
  });
}

class _FakeReminderDelivery implements AcademicReminderDelivery {
  _FakeReminderDelivery({
    this.permission = NotificationPermissionStatus.unknown,
  });

  final NotificationPermissionStatus permission;
  final List<List<AcademicReminderRequest>> replacements = [];

  @override
  bool get supportsScheduling => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async => permission;

  @override
  Future<void> replaceAcademicReminders(
    List<AcademicReminderRequest> reminders,
  ) async {
    replacements.add(List.of(reminders));
  }
}
