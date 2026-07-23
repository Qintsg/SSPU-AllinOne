/* 清源全局宿主表面行为测试。 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/lock_page.dart';
import 'package:sspu_allinone/services/system_auth_service.dart';
import 'package:sspu_allinone/widgets/app_startup_status.dart';
import 'package:sspu_allinone/widgets/app_close_confirmation_dialog.dart';
import 'package:sspu_allinone/widgets/app_more_destinations.dart';

void main() {
  testWidgets('启动状态明确区分加载与错误', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      const YhApp(home: AppStartupStatus(progressLabel: '正在初始化应用')),
    );

    expect(find.text('正在初始化应用'), findsOneWidget);
    expect(find.byType(YhProgress), findsOneWidget);

    await tester.pumpWidget(
      YhApp(
        home: AppStartupStatus(
          errorMessage: '启动初始化失败：本地存储不可用',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('启动初始化失败：本地存储不可用'), findsOneWidget);
    expect(find.byType(YhProgress), findsNothing);
    await tester.tap(find.text('重试初始化'));
    expect(retried, isTrue);
  });

  testWidgets('关闭确认表面保留记住选择和两条明确动作', (tester) async {
    bool? minimizedWithRemember;
    bool? exitedWithRemember;
    await tester.pumpWidget(
      YhApp(
        home: AppCloseConfirmationDialog(
          onMinimize: (remember) async => minimizedWithRemember = remember,
          onExit: (remember) async => exitedWithRemember = remember,
        ),
      ),
    );

    expect(find.text('关闭应用'), findsOneWidget);
    expect(find.text('最小化到托盘'), findsOneWidget);
    expect(find.text('退出应用'), findsOneWidget);

    await tester.tap(find.byType(YhCheckbox));
    await tester.pump();
    await tester.tap(find.text('最小化到托盘'));
    await tester.pump();

    expect(minimizedWithRemember, isTrue);
    expect(exitedWithRemember, isNull);
  });

  testWidgets('更多目的地内容展示低频入口并返回选择', (tester) async {
    String? selected;
    await tester.pumpWidget(
      YhApp(
        home: YhBottomDrawer(
          title: '更多',
          child: AppMoreDestinationsContent(
            items: [
              AppMoreDestination(
                label: '邮箱',
                icon: YhIcons.mail,
                onSelected: () => selected = '邮箱',
              ),
              AppMoreDestination(
                label: '设置',
                icon: YhIcons.settings,
                selected: true,
                onSelected: () => selected = '设置',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('邮箱'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('app-more-divider-0'))).height,
      YhTheme.light.layout.divider,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('邮箱'));
    expect(selected, '邮箱');
  });

  testWidgets('锁屏通过认证 adapter 呈现验证中与错误状态', (tester) async {
    final verification = Completer<bool>();
    await tester.pumpWidget(
      YhApp(
        home: LockPage(
          onUnlocked: () {},
          authentication: _FakeLockAuthentication(verification.future),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(YhTextField), 'wrong-password');
    await tester.tap(find.text('解锁'));
    await tester.pump();

    expect(find.text('正在验证…'), findsOneWidget);

    verification.complete(false);
    await tester.pump();
    await tester.pump();
    expect(find.text('密码错误，请重试'), findsOneWidget);
  });
}

class _FakeLockAuthentication implements LockAuthenticationAdapter {
  const _FakeLockAuthentication(this.verification);

  final Future<bool> verification;

  @override
  Future<bool> verifyPassword(String password) => verification;

  @override
  Future<bool> isQuickAuthEnabled() async => false;

  @override
  Future<bool> isSystemAuthAvailable() async => false;

  @override
  Future<SystemAuthResult> authenticate(String localizedReason) async =>
      SystemAuthResult.unavailable;
}
