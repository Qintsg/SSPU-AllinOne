/*
 * 设置页三档响应式导航测试
 * @Project : SSPU-AllinOne
 * @File : settings_responsive_navigation_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'dart:ui' show Tristate;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/settings_page.dart';
import 'package:sspu_allinone/services/storage_service.dart';

/// 在指定视口加载确定性的设置页并等待常规分区就绪。
Future<void> _pumpSettings(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    YhApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          disableAnimations: true,
        ),
        child: const SettingsPage(initializedForTesting: true),
      ),
    ),
  );
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('首页显示').evaluate().isNotEmpty) return;
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .toList();
  throw TestFailure(
    '设置页未完成加载；exception=${tester.takeException()} texts=$texts',
  );
}

void main() {
  const localAuthChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.local_auth_windows.LocalAuthApi.isDeviceSupported',
    StandardMessageCodec(),
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          localAuthChannel,
          (_) async => <Object?>[false],
        );
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(localAuthChannel, null);
  });

  testWidgets('compact 设置使用可恢复焦点的底部分区抽屉', (tester) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpSettings(tester, const Size(360, 800));

    final trigger = find.byKey(const Key('settings-narrow-section-trigger'));
    expect(trigger, findsOneWidget);
    expect(
      find.byKey(const Key('settings-course-reminder-lead-select')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-exam-reminder-lead-select')),
      findsOneWidget,
    );
    expect(tester.getSize(trigger).height, greaterThanOrEqualTo(48));

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    final drawer = find.byType(YhBottomDrawer);
    expect(drawer, findsOneWidget);
    expect(
      find.descendant(of: drawer, matching: find.text('设置分区')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: drawer, matching: find.text('安全')));
    await tester.pumpAndSettle();
    expect(drawer, findsNothing);
    expect(tester.getSemantics(trigger).label, contains('安全'));
    expect(
      tester.getSemantics(trigger).flagsCollection.isFocused,
      Tristate.isTrue,
    );
  });

  testWidgets('768 使用分区抽屉、900 使用页签、expanded 使用左侧导航', (tester) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpSettings(tester, const Size(768, 900));
    expect(
      find.byKey(const Key('settings-narrow-section-trigger')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings-medium-tabs')), findsNothing);

    await _pumpSettings(tester, const Size(900, 900));
    expect(find.byKey(const Key('settings-medium-tabs')), findsOneWidget);
    expect(find.text('系统设置'), findsNothing);

    await _pumpSettings(tester, const Size(1200, 900));
    expect(find.byKey(const Key('settings-medium-tabs')), findsNothing);
    expect(find.text('系统设置'), findsOneWidget);
  });

  testWidgets('安全分区定位使用真实页面结构并在读取失败时保留任务', (tester) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);

    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            devicePixelRatio: 1,
            disableAnimations: true,
          ),
          child: SettingsPage(
            initializedForTesting: true,
            landingRequest: SettingsLandingRequest(
              SettingsLandingSection.security,
            ),
            securityControlsEnabledForTesting: true,
            credentialsStatusLoaderForTesting: () async =>
                throw StateError('测试安全存储不可用'),
          ),
        ),
      ),
    );
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('重试').evaluate().isNotEmpty) break;
    }

    expect(find.text('密码保护'), findsOneWidget);
    expect(find.text('系统快速验证'), findsOneWidget);
    expect(find.text('保存教务凭据'), findsOneWidget);
    expect(find.text('打开数据与隐私'), findsOneWidget);
    expect(find.textContaining('无法读取本机凭据状态'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const Key('settings-narrow-section-trigger')),
          )
          .label,
      contains('安全'),
    );
  });
}
