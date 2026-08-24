/*
 * 校园数据自动刷新偏好测试 — 校验业务来源共享刷新时长
 * @Project : SSPU-AllinOne
 * @File : data_auto_refresh_preferences_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-23
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';
import 'package:sspu_allinone/services/data_auto_refresh_preferences.dart';
import 'package:sspu_allinone/services/email_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';

/// 注册校园数据共享刷新偏好测试。
///
/// :returns: 无返回值。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  test('任一校园数据来源修改自动刷新时长后所有来源共享新值', () async {
    await AcademicEamsService.instance.setAutoRefreshIntervalMinutes(60);

    expect(
      await AcademicEamsService.instance.getAutoRefreshIntervalMinutes(),
      60,
    );
    expect(
      await SportsAttendanceService.instance.getAutoRefreshIntervalMinutes(),
      60,
    );
    expect(
      await StudentReportService.instance.getAutoRefreshIntervalMinutes(),
      60,
    );
    expect(
      await CampusCardService.instance.getAutoRefreshIntervalMinutes(),
      60,
    );
    expect(await EmailService.instance.getAutoRefreshIntervalMinutes(), 60);
  });

  test('修改共享时长时通知已经挂载的页面重载定时器', () async {
    final changed = DataAutoRefreshPreferences.instance.changes.first;

    await DataAutoRefreshPreferences.instance.setIntervalMinutes(60);

    expect(await changed, 60);
  });

  test('旧版来源时长冲突时迁移最保守的最长间隔', () async {
    await StorageService.setInt(
      StorageKeys.academicEamsAutoRefreshIntervalMinutes,
      15,
    );
    await StorageService.setInt(
      StorageKeys.emailAutoRefreshIntervalMinutes,
      60,
    );

    expect(await DataAutoRefreshPreferences.instance.getIntervalMinutes(), 60);
  });
}
