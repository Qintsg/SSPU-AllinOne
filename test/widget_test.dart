/*
 * 基础冒烟测试与移动端导航回归测试
 * @Project : SSPU-AllinOne
 * @File : widget_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:io';

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart' as qingyuan;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/controllers/settings_wechat_controller.dart';
import 'package:sspu_allinone/models/channel_config.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/widgets/campus_network_status_indicator.dart';
import 'package:sspu_allinone/widgets/channel_list_section.dart';
import 'package:sspu_allinone/widgets/desktop_window_frame.dart';
import 'package:sspu_allinone/widgets/settings_auto_refresh_section.dart';
import 'package:sspu_allinone/widgets/settings_general_section.dart';
import 'package:sspu_allinone/widgets/settings_wechat_config_dialog.dart';
import 'package:sspu_allinone/widgets/settings_wechat_section.dart';

part 'widget_test_shell.dart';
part 'widget_test_settings.dart';

/// 等待目标组件出现，避免页面异步加载尚未完成时提前断言。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// Windows 下文件句柄释放可能略晚于组件卸载，清理临时目录时做短重试。
Future<void> deleteDirectoryWithRetry(Directory directory) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    if (!await directory.exists()) return;
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }
}

Future<void> _configureMobileView(
  WidgetTester tester, {
  double topPadding = 0,
  double bottomPadding = 0,
  double keyboardInset = 0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(top: topPadding, bottom: bottomPadding);
  tester.view.viewPadding = FakeViewPadding(
    top: topPadding,
    bottom: bottomPadding,
  );
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
  await tester.binding.setSurfaceSize(const Size(390, 844));
}

Future<void> _resetMobileView(WidgetTester tester) async {
  tester.view.resetPadding();
  tester.view.resetViewPadding();
  tester.view.resetViewInsets();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.binding.setSurfaceSize(null);
}

Future<void> _expectMobileSafeAreaLayout(
  WidgetTester tester,
  TargetPlatform platform,
) async {
  final previousTargetPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = platform;
  final topPadding = platform == TargetPlatform.iOS ? 59.0 : 24.0;
  final bottomPadding = platform == TargetPlatform.iOS ? 34.0 : 24.0;
  await _configureMobileView(
    tester,
    topPadding: topPadding,
    bottomPadding: bottomPadding,
  );

  try {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    final service = _buildCampusNetworkStatusService();
    await tester.pumpWidget(
      YhApp(home: AppShell(campusNetworkStatusService: service)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final pageTitle = find.byKey(const Key('home-page-heading'));
    final titleTop = tester.getTopLeft(pageTitle).dy;
    expect(titleTop, greaterThanOrEqualTo(topPadding));
    expect(titleTop, lessThanOrEqualTo(topPadding + 40));

    final bottomNavigation = find.byKey(const Key('mobile-bottom-navigation'));
    expect(bottomNavigation, findsOneWidget);
    expect(tester.getBottomLeft(bottomNavigation).dy, 844);

    final selectedHomeLabel = find
        .descendant(of: bottomNavigation, matching: find.text('主页'))
        .first;
    expect(
      tester.getBottomLeft(selectedHomeLabel).dy,
      lessThanOrEqualTo(844 - bottomPadding),
    );

    await tester.tap(
      find.descendant(of: bottomNavigation, matching: find.text('信息')).first,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await pumpUntilFound(tester, find.byKey(const Key('info-mobile-controls')));
    final infoTitle = find.text('校园资讯');
    final infoTitleTop = tester.getTopLeft(infoTitle).dy;
    expect(infoTitleTop, greaterThanOrEqualTo(topPadding));
    expect(infoTitleTop, lessThanOrEqualTo(topPadding + 64));
    final infoBody = find.byKey(const ValueKey('info-state-empty'));
    await pumpUntilFound(tester, infoBody);
    expect(
      tester.getTopLeft(infoBody).dy,
      greaterThan(tester.getBottomLeft(infoTitle).dy),
    );

    await tester.pump(const Duration(milliseconds: 300));
  } finally {
    debugDefaultTargetPlatformOverride = previousTargetPlatform;
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _resetMobileView(tester);
  }
}

Future<void> _expectSettingsSelectPopupAvoidsStatusBar(
  WidgetTester tester,
  TargetPlatform platform,
) async {
  final previousTargetPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = platform;
  final topPadding = platform == TargetPlatform.iOS ? 59.0 : 24.0;
  await _configureMobileView(tester, topPadding: topPadding);

  try {
    await tester.pumpWidget(
      const qingyuan.YhApp(
        home: qingyuan.YhPageScaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: _NarrowSettingsNavigation(selectedValue: 6),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-narrow-tab-combo')));
    await tester.pumpAndSettle();

    final firstOption = find.text('常规');
    expect(firstOption, findsOneWidget);
    expect(tester.getTopLeft(firstOption).dy, greaterThanOrEqualTo(topPadding));
  } finally {
    debugDefaultTargetPlatformOverride = previousTargetPlatform;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _resetMobileView(tester);
  }
}

const _windowManagerChannel = MethodChannel('window_manager');

/// 注册应用壳、导航、安全区和校园网状态回归测试。
///
/// :returns: 无返回值。
void main() {
  _registerShellTests();
  _registerSettingsTests();
}
