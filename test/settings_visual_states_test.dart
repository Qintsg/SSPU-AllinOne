/* 设置视觉状态组件行为测试。 */

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/pages/settings_appearance_page.dart';
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
        home: SettingsAppearancePage(
          themeMode: YhThemeMode.system,
          onChanged: (value) => selected = value,
          onApply: () {},
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
          onClearCampusCache: () {},
          onDisconnectAccounts: () {},
        ),
      ),
    );

    expect(find.text('正在从本机存储恢复数据；已有页面框架与输入保持可用。'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('处理中：清除校园缓存'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    await tester.pumpWidget(
      YhApp(
        home: SettingsDataPrivacySection(
          state: SettingsDataPrivacyState.error,
          errorMessage: '部分缓存未能清理，请重试。',
          onClearCampusCache: () {},
          onDisconnectAccounts: () {},
        ),
      ),
    );
    expect(find.text('部分缓存未能清理，请重试。'), findsOneWidget);
    expect(find.text('已完成：清除校园缓存'), findsOneWidget);
    expect(find.text('未完成：断开账户连接'), findsOneWidget);
    expect(find.text('查看隐私说明'), findsOneWidget);
    expect(find.text('查看'), findsNWidgets(2));
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('微信认证错误态保留已完成结果与安全重试路径', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsWechatAuthStatusCard(
          state: SettingsWechatAuthDisplayState.error,
          statusMessage: '认证已过期，请重新扫码登录。',
          onLogin: () {},
          onValidate: () {},
        ),
      ),
    );

    expect(find.text('认证已过期，请重新扫码登录。'), findsOneWidget);
    expect(find.byType(YhChip), findsNothing);
    expect(find.text('已完成：生成登录二维码'), findsOneWidget);
    expect(find.text('未完成：等待手机确认'), findsOneWidget);
    expect(find.text('重新认证'), findsNWidgets(2));
    expect(find.text('重新校验'), findsOneWidget);
  });
}
