/*
 * 微信矩阵卡片测试 — 校验公众号开关与自动关注入口
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_matrix_card_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/models/sspu_wechat_accounts.dart';
import 'package:sspu_allinone/theme/app_theme.dart';
import 'package:sspu_allinone/widgets/settings_wechat_matrix_card.dart';

void main() {
  testWidgets('未关注公众号使用胶囊按钮触发自动关注', (tester) async {
    SspuWechatAccount? toggledAccount;
    bool? toggledValue;

    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsWechatMatrixCard(
              authenticated: true,
              batchFollowing: false,
              batchProgress: '',
              mpNotificationEnabled: const {},
              followedMps: const [],
              followingAccountId: '',
              onBatchFollow: () {},
              onEnableAll: () async {},
              onDisableAll: () async {},
              onToggleAccount: (account, enabled) async {
                toggledAccount = account;
                toggledValue = enabled;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('关注'), findsNothing);
    expect(find.byType(FluentSwitch), findsNothing);

    await tester.tap(
      find.byKey(
        Key('wechat-matrix-toggle-${sspuWechatAccounts.first.wxAccount}'),
      ),
    );
    await tester.pump();

    expect(toggledAccount?.name, sspuWechatAccounts.first.name);
    expect(toggledValue, isTrue);

    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('未认证时矩阵胶囊按钮不可操作', (tester) async {
    var toggled = false;

    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsWechatMatrixCard(
              authenticated: false,
              batchFollowing: false,
              batchProgress: '',
              mpNotificationEnabled: const {},
              followedMps: const [],
              followingAccountId: '',
              onBatchFollow: () {},
              onEnableAll: () async {},
              onDisableAll: () async {},
              onToggleAccount: (_, _) async => toggled = true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('关注'), findsNothing);
    expect(find.byType(FluentSwitch), findsNothing);

    await tester.tap(
      find.byKey(
        Key('wechat-matrix-toggle-${sspuWechatAccounts.first.wxAccount}'),
      ),
    );
    await tester.pump();

    expect(toggled, isFalse);
  });

  testWidgets('已关注胶囊下方显示公众号 ID', (tester) async {
    final account = sspuWechatAccounts.firstWhere(
      (account) => account.wxAccount != account.name,
    );

    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsWechatMatrixCard(
              authenticated: true,
              batchFollowing: false,
              batchProgress: '',
              mpNotificationEnabled: const {'fakeid-1': true},
              followedMps: [
                {
                  'fakeid': 'fakeid-1',
                  'name': account.name,
                  'alias': 'sspu-official-id',
                  'recommended_wx_account': account.wxAccount,
                },
              ],
              followingAccountId: '',
              onBatchFollow: () {},
              onEnableAll: () async {},
              onDisableAll: () async {},
              onToggleAccount: (_, _) async {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('sspu-official-id'), findsOneWidget);
    expect(find.text(account.wxAccount), findsNothing);
  });

  testWidgets('长公众号名称胶囊文本自然换行不省略', (tester) async {
    final account = sspuWechatAccounts.firstWhere(
      (account) => account.name.length >= 12,
    );

    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(420, 800));

    try {
      await tester.pumpWidget(
        FluentApp(
          theme: AppTheme.build(Brightness.light),
          home: ScaffoldPage(
            content: SingleChildScrollView(
              child: SettingsWechatMatrixCard(
                authenticated: true,
                batchFollowing: false,
                batchProgress: '',
                mpNotificationEnabled: const {'fakeid-long': true},
                followedMps: [
                  {
                    'fakeid': 'fakeid-long',
                    'name': account.name,
                    'alias': 'long-public-account-id',
                    'recommended_wx_account': account.wxAccount,
                  },
                ],
                followingAccountId: '',
                onBatchFollow: () {},
                onEnableAll: () async {},
                onDisableAll: () async {},
                onToggleAccount: (_, _) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final title = tester.widget<Text>(find.text(account.name).first);
      final subtitle = tester.widget<Text>(
        find.text('long-public-account-id').first,
      );

      expect(title.overflow, TextOverflow.visible);
      expect(subtitle.overflow, TextOverflow.visible);
      expect(find.textContaining('...'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 150));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('矩阵卡片提供全部开启和全部关闭入口', (tester) async {
    var enabledAll = false;
    var disabledAll = false;

    await tester.pumpWidget(
      FluentApp(
        theme: AppTheme.build(Brightness.light),
        home: ScaffoldPage(
          content: SingleChildScrollView(
            child: SettingsWechatMatrixCard(
              authenticated: true,
              batchFollowing: false,
              batchProgress: '',
              mpNotificationEnabled: const {},
              followedMps: const [],
              followingAccountId: '',
              onBatchFollow: () {},
              onEnableAll: () async => enabledAll = true,
              onDisableAll: () async => disabledAll = true,
              onToggleAccount: (_, _) async {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('全部开启'), findsOneWidget);
    expect(find.text('全部关闭'), findsOneWidget);

    await tester.tap(find.text('全部开启'));
    await tester.pump();
    await tester.tap(find.text('全部关闭'));
    await tester.pump();

    expect(enabledAll, isTrue);
    expect(disabledAll, isTrue);
    await tester.pump(const Duration(milliseconds: 150));
  });
}
