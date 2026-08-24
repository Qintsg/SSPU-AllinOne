/*
 * 安全设置分区测试 — 校验教务凭据展示状态与密码回访隐藏行为
 * @Project : SSPU-AllinOne
 * @File : settings_security_section_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-24
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_login_validation.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_oa_session_prewarm_service.dart';
import 'package:sspu_allinone/services/academic_login_validation_service.dart';
import 'package:sspu_allinone/services/email_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/widgets/settings_security_section.dart';

part 'settings_security_section_tests.dart';
part 'settings_security_section_fakes.dart';

/// 等待目标组件出现，覆盖安全存储异步加载后的首帧。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 注册安全设置分区测试。
///
/// :returns: 无返回值。
void main() {
  _registerSecuritySectionTests();
}
