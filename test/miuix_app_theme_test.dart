/*
 * 全应用 Miuix 主题与外观偏好测试
 * @Project : SSPU-AllinOne
 * @File : miuix_app_theme_test.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/settings_appearance_page.dart';
import 'package:sspu_allinone/services/storage_service.dart';

/// 验证实际外观控件、全局主题更新与本地持久化。
void main() {
  testWidgets(
    '外观页的 Monet 开关立即更新主题并保留当前路线',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      var monet = false;
      var themeMode = YhThemeMode.light;
      var saves = 0;
      final navigation = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => YhApp(
            navigatorKey: navigation,
            themeMode: themeMode,
            monetEnabled: monet,
            onMonetChanged: (value) async {
              saves++;
              setState(() => monet = value);
            },
            home: YhPageScaffold(
              body: Center(
                child: YhButton(
                  label: '打开外观',
                  onTap: () => navigation.currentState!.push(
                    YhPageRoute<void>(
                      builder: (context) => SettingsAppearancePage(
                        themeMode: themeMode,
                        onChanged: (mode) => setState(() => themeMode = mode),
                        onApply: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开外观'));
      await tester.pumpAndSettle();
      final appearance = find.byType(SettingsAppearancePage);
      final initialRouteState = tester.state(appearance);
      final initialColors = tester.element(appearance).yhTheme.color;
      final toggle = find.byKey(const Key('appearance-monet-switch'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      final dynamicColors = tester.element(appearance).yhTheme.color;
      expect(dynamicColors.brandStrong, isNot(initialColors.brandStrong));
      expect(dynamicColors.background, isNot(initialColors.background));
      expect(tester.widget<YhSwitch>(toggle).value, isTrue);
      expect(tester.state(appearance), same(initialRouteState));
      expect(saves, 1);

      await tester.tap(find.text('暗色'));
      await tester.pumpAndSettle();
      expect(
        tester.element(appearance).yhTheme.color.background.computeLuminance(),
        lessThan(0.5),
      );
      expect(tester.widget<YhSwitch>(toggle).value, isTrue);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(320, 720);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(toggle.hitTestable(), findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<YhSwitch>(toggle).value, isFalse);
      expect(
        tester.element(appearance).yhTheme.color.background,
        YhTheme.dark.color.background,
      );
      expect(saves, 2);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('打开外观'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.windows}),
  );

  test('动态色偏好与明暗模式分别保存在实际配置文件', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sspu-miuix-theme-',
    );
    final file = File('${directory.path}/app_state.json');
    try {
      StorageService.debugSetStateFilePathForTesting(file.path);
      expect(
        await StorageService.getBool(StorageKeys.monetThemeEnabled),
        isFalse,
      );
      await StorageService.setThemeMode('dark');
      await StorageService.setBool(StorageKeys.monetThemeEnabled, true);

      StorageService.debugSetStateFilePathForTesting(file.path);
      expect(
        await StorageService.getBool(StorageKeys.monetThemeEnabled),
        isTrue,
      );
      expect(await StorageService.getThemeMode(), 'dark');
    } finally {
      StorageService.debugSetStateFilePathForTesting(null);
      if (await file.exists()) await file.delete();
      await directory.delete();
    }
  });
}
