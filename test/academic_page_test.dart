/*
 * 教务中心页面测试 — 校验体育部课外活动考勤汇总与明细展示
 * @Project : SSPU-AllinOne
 * @File : academic_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'dart:async';

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/academic_calendar_service.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

part 'academic_page_test_support.dart';
part 'academic_page_test_overview.dart';
part 'academic_page_test_life.dart';
part 'academic_page_test_layout.dart';
part 'academic_page_test_evidence.dart';
part 'academic_page_test_terms.dart';

const _completeAcademicCredentials = AcademicCredentialsStatus(
  oaAccount: '20260001',
  emailAccount: '20260001@sspu.edu.cn',
  hasOaPassword: true,
  hasSportsQueryPassword: true,
  hasEmailPassword: true,
);

const _partialAcademicCredentials = AcademicCredentialsStatus(
  oaAccount: '20260001',
  emailAccount: '20260001@sspu.edu.cn',
  hasOaPassword: true,
  hasSportsQueryPassword: false,
  hasEmailPassword: true,
);

/// 等待异步卡片加载完成。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 推进页面动画和 Fluent 点击态短计时器，避免组件卸载后残留 timer。
Future<void> disposeAcademicPage(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> pumpAcademicPage(
  WidgetTester tester, {
  required AcademicEamsClient academicEamsService,
  required SportsAttendanceClient sportsAttendanceService,
  required StudentReportClient studentReportService,
  AcademicTermService? academicTermService,
  bool academicEamsAutoRefreshEnabledOverride = false,
  bool academicEamsFetchEnabledOverride = true,
  int academicEamsAutoRefreshIntervalOverride = 30,
  bool sportsAttendanceAutoRefreshEnabledOverride = false,
  bool sportsAttendanceFetchEnabledOverride = true,
  int sportsAttendanceAutoRefreshIntervalOverride = 30,
  bool studentReportAutoRefreshEnabledOverride = false,
  bool studentReportFetchEnabledOverride = true,
  int studentReportAutoRefreshIntervalOverride = 30,
  VoidCallback? onOpenAccountConnections,
  VoidCallback? onAdjustAcademicTerm,
  AcademicCredentialsStatus credentialsStatusOverride =
      _completeAcademicCredentials,
}) async {
  await tester.pumpWidget(
    YhApp(
      home: AcademicPage(
        academicEamsService: academicEamsService,
        academicTermService: academicTermService,
        sportsAttendanceService: sportsAttendanceService,
        studentReportService: studentReportService,
        academicEamsAutoRefreshEnabledOverride:
            academicEamsAutoRefreshEnabledOverride,
        academicEamsFetchEnabledOverride: academicEamsFetchEnabledOverride,
        academicEamsAutoRefreshIntervalOverride:
            academicEamsAutoRefreshIntervalOverride,
        sportsAttendanceAutoRefreshEnabledOverride:
            sportsAttendanceAutoRefreshEnabledOverride,
        sportsAttendanceFetchEnabledOverride:
            sportsAttendanceFetchEnabledOverride,
        sportsAttendanceAutoRefreshIntervalOverride:
            sportsAttendanceAutoRefreshIntervalOverride,
        studentReportAutoRefreshEnabledOverride:
            studentReportAutoRefreshEnabledOverride,
        studentReportFetchEnabledOverride: studentReportFetchEnabledOverride,
        studentReportAutoRefreshIntervalOverride:
            studentReportAutoRefreshIntervalOverride,
        onOpenAccountConnections: onOpenAccountConnections,
        onAdjustAcademicTerm: onAdjustAcademicTerm,
        credentialsStatusOverride: credentialsStatusOverride,
      ),
    ),
  );
}

/// 注册教务中心全部回归测试。
///
/// :returns: 无返回值。
void main() {
  _registerAcademicOverviewTests();
  _registerAcademicLifeTests();
  _registerAcademicLayoutTests();
  _registerAcademicEvidenceTests();
  _registerAcademicTermsTests();
}
