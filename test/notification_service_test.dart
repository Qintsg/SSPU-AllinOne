import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/academic_reminder_planner.dart';
import 'package:sspu_allinone/services/notification_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('重新调度时取消旧教务提醒并持久化新 ID', () async {
    await StorageService.setStringList(
      StorageKeys.academicReminderNotificationIds,
      ['11', '12'],
    );
    final adapter = _FakeNotificationAdapter();
    final service = NotificationService(
      adapter: adapter,
      isAvailableResolver: () => true,
      supportsSchedulingResolver: () => true,
    );
    final reminders = [
      AcademicReminderRequest(
        id: 21,
        kind: AcademicReminderKind.course,
        scheduledAt: DateTime(2026, 9, 21, 7, 45),
        title: '即将上课：高等数学',
        body: '08:00 · 教学楼 101',
      ),
    ];

    await service.replaceAcademicReminders(reminders);

    expect(adapter.initializeCount, 1);
    expect(adapter.cancelledIds, [11, 12]);
    expect(adapter.scheduled.map((reminder) => reminder.id), [21]);
    expect(
      await StorageService.getStringList(
        StorageKeys.academicReminderNotificationIds,
      ),
      ['21'],
    );
  });

  test('平台不支持调度时仍清理旧计划且不登记新 ID', () async {
    await StorageService.setStringList(
      StorageKeys.academicReminderNotificationIds,
      ['31'],
    );
    final adapter = _FakeNotificationAdapter();
    final service = NotificationService(
      adapter: adapter,
      isAvailableResolver: () => true,
      supportsSchedulingResolver: () => false,
    );

    await service.replaceAcademicReminders(const []);

    expect(adapter.cancelledIds, [31]);
    expect(adapter.scheduled, isEmpty);
    expect(
      await StorageService.getStringList(
        StorageKeys.academicReminderNotificationIds,
      ),
      isEmpty,
    );
  });

  test('查询平台通知权限并在插件失败时降级为未知', () async {
    final adapter = _FakeNotificationAdapter()
      ..permissionStatusValue = NotificationPermissionStatus.denied;
    final service = NotificationService(
      adapter: adapter,
      isAvailableResolver: () => true,
    );

    expect(
      await service.permissionStatus(),
      NotificationPermissionStatus.denied,
    );
    adapter.permissionStatusError = StateError('插件不可用');
    expect(
      await service.permissionStatus(),
      NotificationPermissionStatus.unknown,
    );
  });

  test('校园提醒按上海墙上时间构造，不受输入 DateTime 时区标记影响', () {
    final scheduled = campusScheduledDate(DateTime.utc(2026, 9, 21, 7, 45));

    expect(scheduled.location.name, 'Asia/Shanghai');
    expect(scheduled.year, 2026);
    expect(scheduled.month, 9);
    expect(scheduled.day, 21);
    expect(scheduled.hour, 7);
    expect(scheduled.minute, 45);
    expect(scheduled.timeZoneOffset, const Duration(hours: 8));
  });

  test('绝对时刻会转换为上海校历使用的墙上时间', () {
    final wallClock = campusWallClockNow(DateTime.utc(2026, 9, 20, 16, 30));

    expect(wallClock, DateTime(2026, 9, 21, 0, 30));
  });
}

class _FakeNotificationAdapter implements SystemNotificationAdapter {
  int initializeCount = 0;
  NotificationPermissionStatus permissionStatusValue =
      NotificationPermissionStatus.unknown;
  Object? permissionStatusError;
  final List<int> cancelledIds = [];
  final List<AcademicReminderRequest> scheduled = [];

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    final error = permissionStatusError;
    if (error != null) throw error;
    return permissionStatusValue;
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> schedule(AcademicReminderRequest reminder) async {
    scheduled.add(reminder);
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    String? body,
  }) async {}
}
