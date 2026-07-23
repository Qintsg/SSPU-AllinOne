/* 设置视觉状态组件行为测试。 */

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/widgets/settings_appearance_section.dart';
import 'package:sspu_allinone/widgets/settings_security_section.dart';
import 'package:sspu_allinone/widgets/settings_wechat_auth_status_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('主题模式只接受清源三态并可持久化', () async {
    expect(await StorageService.getThemeMode(), 'system');
    await StorageService.setThemeMode('dark');
    expect(await StorageService.getThemeMode(), 'dark');
    await StorageService.setThemeMode('unknown');
    expect(await StorageService.getThemeMode(), 'dark');
  });

  testWidgets('外观设置返回选择的主题模式', (tester) async {
    YhThemeMode? selected;
    await tester.pumpWidget(
      YhApp(
        home: SettingsAppearanceSection(
          themeMode: YhThemeMode.system,
          onChanged: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('暗色'));
    expect(selected, YhThemeMode.dark);
  });

  testWidgets('数据清理忙碌态禁用危险动作且错误态提供恢复文案', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacySection(
          state: SettingsDataPrivacyState.loading,
          onClearMessageCache: () {},
          onClearAllData: () {},
        ),
      ),
    );

    expect(find.text('正在清理本地数据，请保持应用打开。'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('清除本地数据'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacySection(
          state: SettingsDataPrivacyState.error,
          errorMessage: '部分缓存未能清理，请重试。',
          onClearMessageCache: () {},
          onClearAllData: () {},
        ),
      ),
    );
    expect(find.text('部分缓存未能清理，请重试。'), findsOneWidget);
    expect(find.text('已清除项目'), findsOneWidget);
    expect(find.text('未清除项目'), findsOneWidget);
    expect(find.text('清除本地数据'), findsOneWidget);
  });

  testWidgets('微信认证错误态保留扫码与重新校验路径', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthStatusCard(
          state: SettingsWechatAuthDisplayState.error,
          configPath: 'wxmp_config.json',
          statusMessage: '认证已过期，请重新扫码登录。',
          onLogin: () {},
          onEdit: () {},
          onValidate: () {},
        ),
      ),
    );

    expect(find.text('认证已过期，请重新扫码登录。'), findsOneWidget);
    expect(find.byType(YhStatusPill), findsOneWidget);
    expect(find.byType(YhChip), findsNothing);
    expect(find.text('扫码登录'), findsOneWidget);
    expect(find.text('重新加载配置并校验'), findsOneWidget);
  });
}
