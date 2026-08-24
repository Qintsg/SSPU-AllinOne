/*
 * 应用壳与校园网状态回归测试
 * @Project : SSPU-AllinOne
 * @File : widget_test_shell.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'widget_test.dart';

/// 注册应用壳、导航、安全区和校园网状态测试。
///
/// :returns: 无返回值。
void _registerShellTests() {
  testWidgets('手机竖屏显示底部导航栏', (WidgetTester tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _configureMobileView(tester);

    try {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final service = _buildCampusNetworkStatusService();
      await tester.pumpWidget(
        YhApp(home: AppShell(campusNetworkStatusService: service)),
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
      await tester.pump(YhTheme.light.motion.slow);

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
      await _resetMobileView(tester);
    }
  });

  testWidgets('应用壳可在测试中使用指定主目的地首帧', (tester) async {
    await _configureMobileView(tester);
    try {
      await tester.pumpWidget(
        const YhApp(
          home: AppShell(
            initialDestinationIndex: 2,
            destinationOverrides: {'课表': Text('脱敏课表首帧')},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('脱敏课表首帧'), findsOneWidget);
      expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);
      expect(find.text('主页'), findsOneWidget);
      expect(find.text('课表'), findsOneWidget);
    } finally {
      await _resetMobileView(tester);
    }
  });

  testWidgets('移动端安全区不遮挡页面标题且底部导航贴合手势区', (WidgetTester tester) async {
    await _expectMobileSafeAreaLayout(tester, TargetPlatform.android);
    await _expectMobileSafeAreaLayout(tester, TargetPlatform.iOS);
  });

  testWidgets('移动端输入法弹出时外层底部导航不重复让位', (WidgetTester tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _configureMobileView(tester, bottomPadding: 24);

    try {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final service = _buildCampusNetworkStatusService();
      await tester.pumpWidget(
        YhApp(home: AppShell(campusNetworkStatusService: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNavigation = find.byKey(
        const Key('mobile-bottom-navigation'),
      );
      expect(bottomNavigation, findsOneWidget);
      expect(tester.getBottomLeft(bottomNavigation).dy, 844);

      await _configureMobileView(tester, bottomPadding: 24, keyboardInset: 320);
      await tester.pump();

      expect(tester.getBottomLeft(bottomNavigation).dy, 844);

      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _resetMobileView(tester);
    }
  });

  testWidgets('移动端安全区保护清源页面标题区域', (tester) async {
    await _configureMobileView(tester, topPadding: 44, bottomPadding: 34);

    try {
      await tester.pumpWidget(
        const YhApp(
          home: YhPageScaffold(
            appBar: YhAppBar(title: '测试页面'),
            body: Text('测试内容'),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getTopLeft(find.text('测试页面')).dy, greaterThanOrEqualTo(44));
      expect(tester.getTopLeft(find.text('测试页面')).dy, lessThanOrEqualTo(84));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _resetMobileView(tester);
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
        YhApp(
          home: AppShell(
            campusNetworkStatusService: service,
            destinationOverrides: {
              '主页': HomePage(
                campusNetworkStatusService: service,
                campusCardAutoRefreshEnabledOverride: false,
                dashboardDisplayStateOverride:
                    HomeDashboardDisplayState.content,
              ),
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await pumpUntilFound(tester, find.text('VPN 可用'));

      // 校园网徽标由可注入服务驱动，避免组件测试依赖真实校园网环境。
      expect(
        find.byKey(const Key('campus-network-status-home')),
        findsOneWidget,
      );
      expect(find.text('VPN 可用'), findsOneWidget);
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

  testWidgets('清源导航按断点自动切换扩展轨紧凑轨和底栏', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    final service = _buildCampusNetworkStatusService();
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        YhApp(home: AppShell(campusNetworkStatusService: service)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    try {
      await pumpAt(const Size(1280, 800));
      expect(find.byType(qingyuan.YhNavRail), findsOneWidget);
      expect(tester.getSize(find.byType(qingyuan.YhNavRail)).width, 220);
      expect(find.byKey(const Key('mobile-bottom-navigation')), findsNothing);

      await pumpAt(const Size(900, 800));
      expect(find.byType(qingyuan.YhNavRail), findsOneWidget);
      expect(tester.getSize(find.byType(qingyuan.YhNavRail)).width, 80);
      expect(find.byKey(const Key('mobile-bottom-navigation')), findsNothing);

      await pumpAt(const Size(700, 800));
      expect(find.byType(qingyuan.YhNavRail), findsNothing);
      expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);

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
        qingyuan.YhApp(
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
      icon: qingyuan.YhIcons.networkVpn,
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
      icon: qingyuan.YhIcons.networkOff,
      tooltip: '当前处于非校园网络环境，访问校内服务需要连接校园网或打开VPN',
    );
    await _expectTitleBarStatus(
      tester,
      vpnReachable: false,
      campusReachable: false,
      label: '未知网络环境',
      icon: qingyuan.YhIcons.networkUnknown,
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
        qingyuan.YhApp(
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
          matching: find.byIcon(qingyuan.YhIcons.networkVpn),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: indicator, matching: find.text('检测中')),
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

  testWidgets('macOS 桌面标题栏使用原生红绿灯窗口按钮', (tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _windowManagerChannel,
      (call) async {
        calls.add(call.method);
        if (call.method == 'isMaximized') return false;
        return null;
      },
    );

    try {
      await tester.pumpWidget(
        const qingyuan.YhApp(home: DesktopWindowFrame(child: Text('桌面内容'))),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('最小化'), findsNothing);
      expect(find.bySemanticsLabel('最大化'), findsNothing);
      expect(find.bySemanticsLabel('关闭'), findsNothing);
      expect(find.text('工大聚合'), findsOneWidget);
      expect(tester.getTopLeft(find.text('工大聚合')).dx, greaterThan(80));
      expect(calls, contains('isMaximized'));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _windowManagerChannel,
        null,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('非 macOS 桌面标题栏使用清源窗口按钮', (tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _windowManagerChannel,
      (call) async {
        if (call.method == 'isMaximized') return false;
        return null;
      },
    );

    try {
      await tester.pumpWidget(
        const qingyuan.YhApp(home: DesktopWindowFrame(child: Text('桌面内容'))),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('最小化'), findsOneWidget);
      expect(find.bySemanticsLabel('最大化'), findsOneWidget);
      expect(find.bySemanticsLabel('关闭'), findsOneWidget);
      expect(find.text('工大聚合'), findsOneWidget);
      expect(tester.getTopLeft(find.text('工大聚合')).dx, lessThan(80));
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _windowManagerChannel,
        null,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
      qingyuan.YhApp(
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
    expect(tester.getSize(indicator), const Size(144, 32));
    if (usesCustomWifiIcon) {
      expect(
        find.descendant(of: indicator, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: indicator,
          matching: find.byIcon(qingyuan.YhIcons.globe),
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
        return widget is qingyuan.YhTooltip && widget.message == tooltip;
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
