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
  testWidgets('未关注公众号使用开关触发自动关注', (tester) async {
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
    expect(find.byType(FluentSwitch), findsWidgets);

    final firstSwitch = find.byType(FluentSwitch).first;
    tester.widget<FluentSwitch>(firstSwitch).onChanged?.call(true);
    await tester.pump();

    expect(toggledAccount?.name, sspuWechatAccounts.first.name);
    expect(toggledValue, isTrue);
  });

  testWidgets('未认证时矩阵开关不可操作', (tester) async {
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
              onToggleAccount: (_, _) async => toggled = true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('关注'), findsNothing);
    final firstSwitch = tester.widget<FluentSwitch>(
      find.byType(FluentSwitch).first,
    );

    expect(firstSwitch.onChanged, isNull);
    expect(toggled, isFalse);
  });
}
