/*
 * 基础冒烟测试与移动端导航回归测试
 * @Project : SSPU-AllinOne
 * @File : widget_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-18
 */

import 'dart:io';

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/controllers/settings_wechat_controller.dart';
import 'package:sspu_allinone/models/channel_config.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/widgets/app_feedback.dart';
import 'package:sspu_allinone/widgets/campus_network_status_indicator.dart';
import 'package:sspu_allinone/widgets/channel_list_section.dart';
import 'package:sspu_allinone/widgets/settings_auto_refresh_section.dart';
import 'package:sspu_allinone/widgets/settings_general_section.dart';
import 'package:sspu_allinone/widgets/settings_wechat_config_dialog.dart';
import 'package:sspu_allinone/widgets/settings_wechat_section.dart';

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

void main() {
  Future<void> configureMobileView(
    WidgetTester tester, {
    double topPadding = 0,
    double bottomPadding = 0,
    double keyboardInset = 0,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(
      top: topPadding,
      bottom: bottomPadding,
    );
    tester.view.viewPadding = FakeViewPadding(
      top: topPadding,
      bottom: bottomPadding,
    );
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    await tester.binding.setSurfaceSize(const Size(390, 844));
  }

  Future<void> resetMobileView(WidgetTester tester) async {
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    tester.view.resetViewInsets();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('手机竖屏显示底部导航栏', (WidgetTester tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await configureMobileView(tester);

    try {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final service = _buildCampusNetworkStatusService();
      await tester.pumpWidget(
        FluentApp(home: AppShell(campusNetworkStatusService: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNavigation = find.byKey(
        const Key('mobile-bottom-navigation'),
      );
      expect(bottomNavigation, findsOneWidget);
      expect(
        find.descendant(of: bottomNavigation, matching: find.text('主页')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNavigation, matching: find.text('教务')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNavigation, matching: find.text('课表')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNavigation, matching: find.text('信息')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bottomNavigation, matching: find.text('更多')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: bottomNavigation,
                matching: find.bySemanticsLabel('主页'),
              )
              .first,
        ),
        matchesSemantics(
          label: '主页',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.text('更多'));
      await tester.pumpAndSettle();

      expect(find.text('更多'), findsWidgets);
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('邮箱'), findsAtLeastNWidgets(1));
      expect(find.text('跳转'), findsOneWidget);
      expect(find.text('关于'), findsNothing);

      // 首页使用 flutter_animate，补一段时间让一次性动画定时器自然完成。
      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetMobileView(tester);
    }
  });

  Future<void> expectMobileSafeAreaLayout(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = platform;
    final topPadding = platform == TargetPlatform.iOS ? 59.0 : 24.0;
    final bottomPadding = platform == TargetPlatform.iOS ? 34.0 : 24.0;
    await configureMobileView(
      tester,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );

    try {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final service = _buildCampusNetworkStatusService();
      await tester.pumpWidget(
        FluentApp(home: AppShell(campusNetworkStatusService: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final pageTitle = find
          .descendant(
            of: find.byType(FluentPageHeader),
            matching: find.text('主页'),
          )
          .first;
      final titleTop = tester.getTopLeft(pageTitle).dy;
      expect(titleTop, greaterThanOrEqualTo(topPadding));
      expect(titleTop, lessThanOrEqualTo(topPadding + 40));

      final bottomNavigation = find.byKey(
        const Key('mobile-bottom-navigation'),
      );
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
      await pumpUntilFound(
        tester,
        find.byKey(const Key('info-mobile-controls')),
      );
      final infoControlsTop = tester
          .getTopLeft(find.byKey(const Key('info-mobile-controls')))
          .dy;
      expect(infoControlsTop, greaterThanOrEqualTo(topPadding));
      expect(infoControlsTop, lessThanOrEqualTo(topPadding + 40));

      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetMobileView(tester);
    }
  }

  testWidgets('移动端安全区不遮挡页面标题且底部导航贴合手势区', (WidgetTester tester) async {
    await expectMobileSafeAreaLayout(tester, TargetPlatform.android);
    await expectMobileSafeAreaLayout(tester, TargetPlatform.iOS);
  });

  testWidgets('移动端输入法弹出时外层底部导航不重复让位', (WidgetTester tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await configureMobileView(tester, bottomPadding: 24);

    try {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final service = _buildCampusNetworkStatusService();
      await tester.pumpWidget(
        FluentApp(home: AppShell(campusNetworkStatusService: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNavigation = find.byKey(
        const Key('mobile-bottom-navigation'),
      );
      expect(bottomNavigation, findsOneWidget);
      expect(tester.getBottomLeft(bottomNavigation).dy, 844);

      await configureMobileView(tester, bottomPadding: 24, keyboardInset: 320);
      await tester.pump();

      expect(tester.getBottomLeft(bottomNavigation).dy, 844);

      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetMobileView(tester);
    }
  });

  testWidgets('移动端安全区保护 FluentPage 标题区域', (tester) async {
    await configureMobileView(tester, topPadding: 44, bottomPadding: 34);

    try {
      await tester.pumpWidget(
        const FluentApp(
          home: FluentPage.scrollable(
            header: FluentPageHeader(title: Text('测试页面')),
            children: [Text('测试内容')],
          ),
        ),
      );
      await tester.pump();

      expect(tester.getTopLeft(find.text('测试页面')).dy, greaterThanOrEqualTo(44));
      expect(tester.getTopLeft(find.text('测试页面')).dy, lessThanOrEqualTo(84));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetMobileView(tester);
    }
  });

  testWidgets('桌面首页右上角显示校园网状态小徽标', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    final service = _buildCampusNetworkStatusService();
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(
        FluentApp(home: AppShell(campusNetworkStatusService: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await pumpUntilFound(tester, find.text('VPN'));

      // 校园网徽标由可注入服务驱动，避免组件测试依赖真实校园网环境。
      expect(
        find.byKey(const Key('campus-network-status-home')),
        findsOneWidget,
      );
      expect(find.text('VPN'), findsOneWidget);
      expect(
        find.byKey(const Key('campus-network-status-pane-item')),
        findsNothing,
      );

      // 首页入场动画会保留短计时器，测试结束前推进时间以清理动画状态。
      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('多个校园网状态入口共享同一次检测结果', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    var probeCount = 0;
    final service = CampusNetworkStatusService(
      probe: (uri, timeout) async {
        probeCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return CampusNetworkProbeResult(
          reachable: true,
          statusCode: 200,
          detail: '已访问 ${uri.host}，HTTP 200',
        );
      },
    );

    try {
      await tester.pumpWidget(
        FluentApp(
          home: Row(
            children: [
              CampusNetworkStatusIndicator(
                service: service,
                indicatorKey: const Key('campus-network-status-first'),
              ),
              CampusNetworkStatusIndicator(
                service: service,
                indicatorKey: const Key('campus-network-status-second'),
              ),
            ],
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('VPN 环境'));

      expect(
        find.byKey(const Key('campus-network-status-first')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('campus-network-status-second')),
        findsOneWidget,
      );
      expect(find.text('VPN 环境'), findsNWidgets(2));
      expect(probeCount, 2);
    } finally {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('桌面标题栏网络状态按固定尺寸展示指定文案和图标', (tester) async {
    await _expectTitleBarStatus(
      tester,
      vpnReachable: true,
      campusReachable: true,
      label: 'VPN网络环境',
      icon: FluentIcons.networkVpn,
      tooltip: '当前处于VPN网络环境下，部分校园内部服务可能无法访问',
    );
    await _expectTitleBarStatus(
      tester,
      vpnReachable: false,
      campusReachable: true,
      label: '校园网环境',
      icon: null,
      tooltip: '当前处于校园非VPN网络环境下',
      usesCustomWifiIcon: true,
    );
    await _expectTitleBarStatus(
      tester,
      vpnReachable: true,
      campusReachable: false,
      label: '校外网络环境',
      icon: FluentIcons.networkOff,
      tooltip: '当前处于非校园网络环境，访问校内服务需要连接校园网或打开VPN',
    );
    await _expectTitleBarStatus(
      tester,
      vpnReachable: false,
      campusReachable: false,
      label: '未知网络环境',
      icon: FluentIcons.networkUnknown,
      tooltip: '当前网络环境未知，可能是由于当前设备没有连接到网络、校园网内部错误、设备内部错误或网络波动等问题',
    );
  });

  testWidgets('桌面标题栏网络状态点击后重新探查', (tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    var probeCount = 0;
    final service = _buildCampusNetworkStatusService(
      onProbe: (_) => probeCount++,
      probeDelay: const Duration(milliseconds: 100),
    );

    try {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: CampusNetworkStatusIndicator(
              service: service,
              variant: CampusNetworkStatusIndicatorVariant.titleBar,
              indicatorKey: const Key('campus-network-status-titlebar-test'),
            ),
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('VPN网络环境'));
      expect(find.text('VPN网络环境'), findsOneWidget);
      expect(probeCount, 2);

      await tester.tap(
        find.byKey(const Key('campus-network-status-titlebar-test')),
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(probeCount, 4);
      final indicator = find.byKey(
        const Key('campus-network-status-titlebar-test'),
      );
      expect(
        find.descendant(
          of: indicator,
          matching: find.byIcon(FluentIcons.networkVpn),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: indicator,
          matching: find.byType(FluentProgressRing),
        ),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 120));
    } finally {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('自动刷新设置分区显示校园网检测和快捷入口', (WidgetTester tester) async {
    var selectedShortcut = 0;
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      FluentApp(
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsAutoRefreshSection(
              campusNetworkDetectionIntervalMinutes: 15,
              sportsAttendanceAutoRefreshEnabled: true,
              sportsAttendanceAutoRefreshIntervalMinutes: 30,
              campusCardAutoRefreshEnabled: true,
              campusCardAutoRefreshIntervalMinutes: 60,
              emailAutoRefreshEnabled: true,
              emailAutoRefreshIntervalMinutes: 30,
              studentReportAutoRefreshEnabled: true,
              studentReportAutoRefreshIntervalMinutes: 30,
              academicEamsAutoRefreshEnabled: true,
              academicEamsAutoRefreshIntervalMinutes: 30,
              onCampusNetworkDetectionIntervalChanged: (_) async {},
              onSportsAttendanceAutoRefreshChanged: (_) async {},
              onSportsAttendanceAutoRefreshIntervalChanged: (_) async {},
              onCampusCardAutoRefreshChanged: (_) async {},
              onCampusCardAutoRefreshIntervalChanged: (_) async {},
              onEmailAutoRefreshChanged: (_) async {},
              onEmailAutoRefreshIntervalChanged: (_) async {},
              onStudentReportAutoRefreshChanged: (_) async {},
              onStudentReportAutoRefreshIntervalChanged: (_) async {},
              onAcademicEamsAutoRefreshChanged: (_) async {},
              onAcademicEamsAutoRefreshIntervalChanged: (_) async {},
              onOpenDepartmentRefreshSettings: () => selectedShortcut = 3,
              onOpenTeachingRefreshSettings: () => selectedShortcut = 4,
              onOpenWechatRefreshSettings: () => selectedShortcut = 5,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('校园网 / VPN 状态检测'), findsOneWidget);
    expect(find.text('体育查询自动刷新'), findsOneWidget);
    expect(find.text('校园卡余额自动刷新'), findsOneWidget);
    expect(find.text('学校邮箱自动刷新'), findsOneWidget);
    expect(find.text('第二课堂学分自动刷新'), findsOneWidget);
    expect(find.text('本专科教务自动刷新'), findsOneWidget);
    expect(find.text('15 分钟'), findsOneWidget);
    expect(find.text('30 分钟'), findsNWidgets(4));
    expect(find.text('1 小时'), findsOneWidget);
    expect(find.text('职能部门'), findsOneWidget);
    expect(find.text('教学单位'), findsOneWidget);
    expect(find.text('微信推文'), findsOneWidget);

    await tester.tap(find.text('前往设置').first);
    await tester.pump(const Duration(milliseconds: 150));
    expect(selectedShortcut, 3);
  });

  testWidgets('常规设置分区显示首页业务卡片开关', (WidgetTester tester) async {
    var studentVisible = true;
    var campusCardVisible = true;
    var todayCoursesVisible = true;
    var sportsVisible = true;
    var studentReportVisible = true;
    var messagesVisible = true;
    var emailVisible = true;
    var quickLinksVisible = true;
    await tester.pumpWidget(
      FluentApp(
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsGeneralSection(
              closeBehavior: 'ask',
              notificationEnabled: true,
              dndEnabled: false,
              homeStudentProfileCardVisible: true,
              homeCampusCardBalanceCardVisible: true,
              homeTodayCoursesTileVisible: true,
              homeSportsAttendanceTileVisible: true,
              homeStudentReportTileVisible: true,
              homeMessagesTileVisible: true,
              homeEmailTileVisible: true,
              homeQuickLinksTileVisible: true,
              dndStartHour: 22,
              dndStartMinute: 0,
              dndEndHour: 7,
              dndEndMinute: 0,
              onCloseBehaviorChanged: (_) {},
              onNotificationChanged: (_) {},
              onDndChanged: (_) {},
              onHomeStudentProfileCardVisibleChanged: (value) =>
                  studentVisible = value,
              onHomeCampusCardBalanceCardVisibleChanged: (value) =>
                  campusCardVisible = value,
              onHomeTodayCoursesTileVisibleChanged: (value) =>
                  todayCoursesVisible = value,
              onHomeSportsAttendanceTileVisibleChanged: (value) =>
                  sportsVisible = value,
              onHomeStudentReportTileVisibleChanged: (value) =>
                  studentReportVisible = value,
              onHomeMessagesTileVisibleChanged: (value) =>
                  messagesVisible = value,
              onHomeEmailTileVisibleChanged: (value) => emailVisible = value,
              onHomeQuickLinksTileVisibleChanged: (value) =>
                  quickLinksVisible = value,
              onDndStartChanged: (_, _) async {},
              onDndEndChanged: (_, _) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('首页显示'), findsOneWidget);
    expect(find.text('显示学籍信息卡片'), findsOneWidget);
    expect(find.text('显示校园卡余额卡片'), findsOneWidget);
    expect(find.text('显示今日课程磁贴'), findsOneWidget);
    expect(find.text('显示体育考勤磁贴'), findsOneWidget);
    expect(find.text('显示第二课堂磁贴'), findsOneWidget);
    expect(find.text('显示最新消息磁贴'), findsOneWidget);
    expect(find.text('显示邮箱摘要磁贴'), findsOneWidget);
    expect(find.text('显示快速跳转磁贴'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('settings-home-student-profile-card-switch')),
    );
    await tester.pump();
    expect(studentVisible, isFalse);
    await tester.tap(find.byKey(const Key('settings-home-campus-card-switch')));
    await tester.pump();
    expect(campusCardVisible, isFalse);
    await tester.tap(
      find.byKey(const Key('settings-home-today-courses-switch')),
    );
    await tester.pump();
    expect(todayCoursesVisible, isFalse);
    await tester.tap(
      find.byKey(const Key('settings-home-sports-attendance-switch')),
    );
    await tester.pump();
    expect(sportsVisible, isFalse);
    await tester.tap(
      find.byKey(const Key('settings-home-student-report-switch')),
    );
    await tester.pump();
    expect(studentReportVisible, isFalse);
    await tester.tap(find.byKey(const Key('settings-home-messages-switch')));
    await tester.pump();
    expect(messagesVisible, isFalse);
    await tester.tap(find.byKey(const Key('settings-home-email-switch')));
    await tester.pump();
    expect(emailVisible, isFalse);
    await tester.ensureVisible(
      find.byKey(const Key('settings-home-quick-links-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-home-quick-links-switch')));
    await tester.pump();
    expect(quickLinksVisible, isFalse);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('页面反馈连续显示时替换上一条紧凑浮层', (WidgetTester tester) async {
    await tester.pumpWidget(
      FluentApp(
        home: ScaffoldPage(
          content: Builder(
            builder: (context) => Button(
              onPressed: () {
                showAppFeedback(context, message: '第一条反馈');
                showAppFeedback(context, message: '第二条反馈');
              },
              child: const Text('显示反馈'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示反馈'));
    await tester.pump();

    expect(find.text('第一条反馈'), findsNothing);
    expect(find.text('第二条反馈'), findsOneWidget);
    final toast = find.byKey(const Key('app-feedback-toast'));
    expect(toast, findsOneWidget);
    expect(tester.getTopLeft(toast).dy, lessThan(120));
    expect(tester.getBottomLeft(toast).dy, lessThan(260));
    expect(find.byType(FluentInfoBar), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(toast, findsNothing);
  });

  testWidgets('WebView 遇到无效链接时显示错误页', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FluentApp(
        home: WebViewPage(
          url: 'https://wywh.sspu.edu.cnjavascript:void(0);',
          initialTitle: '无效链接',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 历史缓存中的非法 URL 不应继续传给 WebView 构造器。
    expect(find.text('链接无效，无法打开'), findsOneWidget);
    expect(find.text('返回'), findsOneWidget);
  });

  testWidgets('设置页窄屏使用顶部下拉切换分区', (WidgetTester tester) async {
    await configureMobileView(tester);

    try {
      await tester.pumpWidget(
        const FluentApp(home: _SettingsNavigationLayoutHarness()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 仅覆盖响应式导航结构，避免完整设置页服务初始化拖慢组件测试。
      expect(find.text('常规'), findsOneWidget);
      expect(find.text('系统设置'), findsNothing);
      expect(
        find.byKey(const Key('settings-narrow-tab-combo')),
        findsOneWidget,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetMobileView(tester);
    }
  });

  testWidgets('职能部门和教学单位设置使用总览与轻量频道卡布局', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);

    Future<void> pumpChannelSection({
      required double width,
      required String title,
      required List<ChannelConfig> channels,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: SingleChildScrollView(
              child: ChannelListSection(title: title, channels: channels),
            ),
          ),
        ),
      );
      await pumpUntilFound(tester, find.text(title));
      await tester.pump(const Duration(milliseconds: 100));
    }

    try {
      await pumpChannelSection(
        width: 1280,
        title: '职能部门',
        channels: departmentChannels,
      );
      expect(find.text('统一管理学校官网消息来源，启用后会在信息中心筛选和刷新中生效。'), findsOneWidget);
      expect(find.text('共 24 个渠道'), findsOneWidget);
      expect(find.text('已接入 24 个'), findsOneWidget);
      expect(find.text('刷新设置'), findsOneWidget);
      expect(find.text('手动刷新'), findsOneWidget);
      expect(find.text('自动抓取'), findsOneWidget);
      expect(find.text('公开信息'), findsOneWidget);
      expect(find.text('已接入'), findsWidgets);
      expect(find.text('显示中'), findsWidgets);
      expect(tester.takeException(), isNull);

      await pumpChannelSection(
        width: 390,
        title: '教学单位',
        channels: teachingChannels,
      );
      expect(find.text('教学单位'), findsOneWidget);
      expect(find.text('共 20 个渠道'), findsOneWidget);
      expect(find.text('计算机与信息工程学院'), findsOneWidget);
      expect(find.text('内容分类'), findsWidgets);
      expect(find.text('3 项'), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('微信推文设置显示精简刷新卡片和认证操作', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final configDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'settings_page_wechat_actions_${DateTime.now().microsecondsSinceEpoch}',
    );
    StorageService.debugSetStateFilePathForTesting(
      '${configDirectory.path}${Platform.pathSeparator}app_state.json',
    );
    await tester.runAsync(StorageService.init);
    WxmpConfigService.instance.debugSetConfigPathForTesting(
      '${configDirectory.path}${Platform.pathSeparator}wxmp_config.toml',
    );
    final controller = SettingsWechatController();
    await tester.runAsync(controller.load);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: SingleChildScrollView(
              child: SettingsWechatSection(controller: controller),
            ),
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('编辑配置文件'));

      expect(find.text('编辑配置文件'), findsOneWidget);
      expect(find.text('重新加载配置并校验'), findsOneWidget);
      expect(find.text('清除认证'), findsOneWidget);
      expect(find.text('打开配置文件所在文件夹'), findsNothing);
      expect(find.text('外部打开'), findsNothing);
      expect(find.text('校验有效性'), findsNothing);
      expect(find.text('使用 Visual Studio Code 打开配置文件'), findsNothing);
      expect(find.text('刷新设置'), findsOneWidget);
      expect(find.text('全部开启'), findsOneWidget);
      expect(find.text('全部关闭'), findsOneWidget);
      expect(find.textContaining('矩阵开关'), findsNothing);
      expect(find.text('微信矩阵'), findsOneWidget);
      expect(find.text('SSPU 微信矩阵'), findsNothing);
      expect(find.text('微信公众平台注册方式'), findsNothing);
      expect(find.textContaining('若频率过快'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      WxmpConfigService.instance.debugSetConfigPathForTesting(null);
      StorageService.debugSetStateFilePathForTesting(null);
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      await tester.runAsync(() => deleteDirectoryWithRetry(configDirectory));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('微信推文配置编辑器使用自适应字段表单', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));

    try {
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: Center(
              child: FluentButton(
                onPressed: () {
                  showSettingsWechatConfigDialog(
                    context: tester.element(find.text('打开编辑器')),
                    initialConfig: WxmpConfig.defaults(),
                  );
                },
                child: const Text('打开编辑器'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开编辑器'));
      await pumpUntilFound(tester, find.text('cookie'));

      expect(find.text('cookie'), findsOneWidget);
      expect(find.text('token'), findsOneWidget);
      expect(find.text('app_id'), findsOneWidget);
      expect(find.text('user_agent'), findsOneWidget);
      expect(find.text('per_request_article_count'), findsOneWidget);
      expect(find.text('request_delay_ms'), findsOneWidget);
      expect(find.textContaining('保存后会立即重新加载配置'), findsNothing);

      final dialogBox = tester.renderObject<RenderBox>(
        find.byType(FluentDialog),
      );
      expect(dialogBox.size.width <= 390, isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('微信推文配置编辑器宽屏使用双列布局', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: Center(
              child: FluentButton(
                onPressed: () {
                  showSettingsWechatConfigDialog(
                    context: tester.element(find.text('打开编辑器')),
                    initialConfig: WxmpConfig.defaults(),
                  );
                },
                child: const Text('打开编辑器'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开编辑器'));
      await pumpUntilFound(tester, find.text('cookie'));

      final contentBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('wechat-config-dialog-content')),
      );
      expect(contentBox.size.width >= 760, isTrue);
      expect(contentBox.size.width <= 920, isTrue);

      final cookieTop = tester.getTopLeft(find.text('cookie')).dy;
      final tokenTop = tester.getTopLeft(find.text('token')).dy;
      expect((cookieTop - tokenTop).abs() < 1, isTrue);

      final appIdTop = tester.getTopLeft(find.text('app_id')).dy;
      final userAgentTop = tester.getTopLeft(find.text('user_agent')).dy;
      expect(userAgentTop < appIdTop, isTrue);

      final cancelLeft = tester.getTopLeft(find.text('取消')).dx;
      final contentLeft = tester
          .getTopLeft(find.byKey(const Key('wechat-config-dialog-content')))
          .dx;
      expect(cancelLeft > contentLeft + contentBox.size.width / 2, isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });
}

Future<void> _expectTitleBarStatus(
  WidgetTester tester, {
  required bool vpnReachable,
  required bool campusReachable,
  required String label,
  required IconData? icon,
  required String tooltip,
  bool usesCustomWifiIcon = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  StorageService.debugUseSharedPreferencesStorageForTesting(true);
  final service = _buildCampusNetworkStatusService(
    vpnReachable: vpnReachable,
    campusReachable: campusReachable,
  );

  try {
    await tester.pumpWidget(
      FluentApp(
        home: Center(
          child: CampusNetworkStatusIndicator(
            service: service,
            variant: CampusNetworkStatusIndicatorVariant.titleBar,
            indicatorKey: const Key('campus-network-status-titlebar-test'),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text(label));
    expect(find.text(label), findsOneWidget);

    final indicator = find.byKey(
      const Key('campus-network-status-titlebar-test'),
    );
    expect(indicator, findsOneWidget);
    expect(tester.getSize(indicator), const Size(142, 30));
    expect(
      find.descendant(of: indicator, matching: find.byType(DecoratedBox)),
      findsNothing,
    );
    if (usesCustomWifiIcon) {
      expect(
        find.descendant(of: indicator, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: indicator,
          matching: find.byIcon(FluentIcons.networkWifi),
        ),
        findsNothing,
      );
    } else {
      expect(
        find.descendant(of: indicator, matching: find.byIcon(icon!)),
        findsOneWidget,
      );
    }
    expect(
      find.byWidgetPredicate((widget) {
        return widget is Tooltip && widget.message == tooltip;
      }),
      findsOneWidget,
    );
  } finally {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

CampusNetworkStatusService _buildCampusNetworkStatusService({
  bool vpnReachable = true,
  bool campusReachable = true,
  void Function(Uri uri)? onProbe,
  Duration probeDelay = Duration.zero,
}) {
  return CampusNetworkStatusService(
    probe: (uri, timeout) async {
      onProbe?.call(uri);
      if (probeDelay > Duration.zero) {
        await Future<void>.delayed(probeDelay);
      }
      final reachable =
          uri.host == CampusNetworkStatusService.defaultVpnProbeUri.host
          ? vpnReachable
          : campusReachable;
      return CampusNetworkProbeResult(
        reachable: reachable,
        statusCode: reachable ? 200 : null,
        detail: reachable ? '已访问 ${uri.host}，HTTP 200' : '访问 ${uri.host} 超时',
      );
    },
  );
}

class _SettingsNavigationLayoutHarness extends StatelessWidget {
  const _SettingsNavigationLayoutHarness();

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          return isNarrow
              ? const _NarrowSettingsNavigation()
              : const _WideSettingsNavigation();
        },
      ),
    );
  }
}

class _NarrowSettingsNavigation extends StatelessWidget {
  const _NarrowSettingsNavigation();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(FluentIcons.globalNavButton, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: FluentSelect<int>(
            key: const Key('settings-narrow-tab-combo'),
            value: 0,
            isExpanded: true,
            items: const [
              FluentSelectItem(value: 0, child: Text('常规')),
              FluentSelectItem(value: 1, child: Text('学期')),
              FluentSelectItem(value: 2, child: Text('自动刷新')),
              FluentSelectItem(value: 3, child: Text('安全')),
              FluentSelectItem(value: 4, child: Text('职能部门')),
              FluentSelectItem(value: 5, child: Text('教学单位')),
              FluentSelectItem(value: 6, child: Text('微信推文')),
              FluentSelectItem(value: 7, child: Text('关于')),
            ],
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}

class _WideSettingsNavigation extends StatelessWidget {
  const _WideSettingsNavigation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [Text('系统设置'), SizedBox(height: 8), Text('常规')],
    );
  }
}
