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
      const YhApp(home: AppStartupStatus(progressLabel: '读取本地设置')),
    );

    expect(find.text('读取本地设置'), findsOneWidget);
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
    await tester.tap(find.text('重试启动'));
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

    expect(find.text('关闭工大聚合？'), findsOneWidget);
    expect(find.text('桌面窗口'), findsOneWidget);
    expect(find.text('最小化到托盘'), findsOneWidget);
    expect(find.text('退出应用'), findsOneWidget);

    await tester.tap(find.byType(YhCheckbox));
    await tester.pump();
    await tester.tap(find.text('最小化到托盘'));
    await tester.pump();

    expect(minimizedWithRemember, isTrue);
    expect(exitedWithRemember, isNull);
  });

  testWidgets('窄屏关闭操作按整行纵向排列，降低误触风险', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      YhApp(
        home: AppCloseConfirmationDialog(
          onCancel: () {},
          onMinimize: (_) async {},
          onExit: (_) async {},
        ),
      ),
    );

    for (final label in const ['取消', '最小化到托盘', '退出应用']) {
      expect(tester.getSize(find.text(label)).height, greaterThan(0));
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(YhButton),
      );
      expect(tester.getSize(button).width, greaterThanOrEqualTo(280));
    }
  });

  testWidgets('关键操作弹窗拦截系统返回并保留显式取消路径', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开关键弹窗',
            onTap: () {
              YhDialog.show<void>(
                context,
                barrierDismissible: false,
                canPop: false,
                builder: (dialogContext) => YhDialog(
                  title: '关键操作',
                  content: const Text('完成前保留当前上下文。'),
                  actions: [
                    YhButton(
                      label: '显式取消',
                      onTap: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开关键弹窗'));
    await tester.pumpAndSettle();
    expect(find.text('关键操作'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('关键操作'), findsOneWidget);

    await tester.tap(find.text('显式取消'));
    await tester.pumpAndSettle();
    expect(find.text('关键操作'), findsNothing);
  });

  testWidgets('关闭确认可取消且异步操作互斥并可恢复', (tester) async {
    final exitAttempt = Completer<void>();
    var cancelled = 0;
    var minimizeCount = 0;
    var exitCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: AppCloseConfirmationDialog(
          onCancel: () => cancelled++,
          onMinimize: (_) async => minimizeCount++,
          onExit: (_) {
            exitCount++;
            return exitAttempt.future;
          },
        ),
      ),
    );

    expect(find.text('取消'), findsOneWidget);
    await tester.tap(find.text('退出应用'));
    await tester.pump();

    expect(exitCount, 1);
    expect(find.text('正在处理…'), findsOneWidget);
    await tester.tap(find.text('最小化到托盘'), warnIfMissed: false);
    await tester.tap(find.text('取消'), warnIfMissed: false);
    await tester.pump();
    expect(minimizeCount, 0);
    expect(cancelled, 0);

    exitAttempt.completeError(StateError('window unavailable'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('未能完成窗口操作'), findsOneWidget);
    await tester.tap(find.text('取消'));
    expect(cancelled, 1);
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
    expect(
      tester.getSize(find.widgetWithText(YhButton, '正在验证…')).width,
      greaterThanOrEqualTo(300),
    );

    verification.complete(false);
    await tester.pump();
    await tester.pump();
    expect(find.text('密码错误，请重试'), findsOneWidget);
  });

  testWidgets('系统认证与密码验证互斥且失败后恢复密码路径', (tester) async {
    final systemResult = Completer<SystemAuthResult>();
    final authentication = _CoordinatedLockAuthentication(systemResult.future);
    await tester.pumpWidget(
      YhApp(
        home: LockPage(onUnlocked: () {}, authentication: authentication),
      ),
    );
    for (
      var attempt = 0;
      attempt < 10 && authentication.systemAuthCount == 0;
      attempt++
    ) {
      await tester.pump();
    }
    await tester.pump();

    expect(authentication.systemAuthCount, 1);
    expect(find.text('等待系统认证'), findsOneWidget);
    expect(
      tester.widget<YhTextField>(find.byType(YhTextField)).enabled,
      isFalse,
    );
    await tester.enterText(find.byType(YhTextField), 'local-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(authentication.passwordVerificationCount, 0);

    systemResult.complete(SystemAuthResult.failed);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('系统认证未通过或已取消'), findsOneWidget);
    expect(
      tester.widget<YhTextField>(find.byType(YhTextField)).enabled,
      isTrue,
    );
    await tester.enterText(find.byType(YhTextField), 'local-password');
    final passwordField = tester.widget<YhTextField>(find.byType(YhTextField));
    expect(passwordField.controller?.text, 'local-password');
    final unlockButton = find.widgetWithText(YhButton, '解锁');
    expect(tester.widget<YhButton>(unlockButton).onTap, isNotNull);
    await tester.tap(unlockButton);
    await tester.pump();
    expect(authentication.passwordVerificationCount, 1);
  });

  testWidgets('密码验证异常会解除操作锁并恢复输入路径', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: LockPage(
          onUnlocked: () {},
          authentication: const _ThrowingLockAuthentication(),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(YhTextField), 'local-password');
    await tester.tap(find.text('解锁'));
    await tester.pump();
    await tester.pump();

    expect(find.text('暂时无法验证密码，请稍后重试'), findsOneWidget);
    expect(
      tester.widget<YhTextField>(find.byType(YhTextField)).enabled,
      isTrue,
    );
    expect(
      tester.widget<YhButton>(find.widgetWithText(YhButton, '解锁')).onTap,
      isNotNull,
    );
  });

  testWidgets('系统认证异常会降级到本地密码并恢复焦点', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: LockPage(
          onUnlocked: () {},
          authentication: const _ThrowingSystemAuthentication(),
        ),
      ),
    );
    for (
      var attempt = 0;
      attempt < 10 && find.text('系统认证暂不可用，请输入密码解锁').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('系统认证暂不可用，请输入密码解锁'), findsOneWidget);
    expect(
      tester.widget<YhTextField>(find.byType(YhTextField)).enabled,
      isTrue,
    );
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('系统认证能力探测异常不会阻断本地密码', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: LockPage(
          onUnlocked: () {},
          authentication: const _ThrowingAvailabilityAuthentication(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('系统认证设置暂不可用，请输入密码解锁'), findsOneWidget);
    expect(
      tester.widget<YhTextField>(find.byType(YhTextField)).enabled,
      isTrue,
    );
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

class _CoordinatedLockAuthentication implements LockAuthenticationAdapter {
  _CoordinatedLockAuthentication(this.systemResult);

  final Future<SystemAuthResult> systemResult;
  int systemAuthCount = 0;
  int passwordVerificationCount = 0;

  @override
  Future<SystemAuthResult> authenticate(String localizedReason) {
    systemAuthCount++;
    return systemResult;
  }

  @override
  Future<bool> isQuickAuthEnabled() async => true;

  @override
  Future<bool> isSystemAuthAvailable() async => true;

  @override
  Future<bool> verifyPassword(String password) async {
    passwordVerificationCount++;
    return true;
  }
}

class _ThrowingLockAuthentication implements LockAuthenticationAdapter {
  const _ThrowingLockAuthentication();

  @override
  Future<SystemAuthResult> authenticate(String localizedReason) async =>
      SystemAuthResult.unavailable;

  @override
  Future<bool> isQuickAuthEnabled() async => false;

  @override
  Future<bool> isSystemAuthAvailable() async => false;

  @override
  Future<bool> verifyPassword(String password) async =>
      throw StateError('secure storage unavailable');
}

class _ThrowingSystemAuthentication implements LockAuthenticationAdapter {
  const _ThrowingSystemAuthentication();

  @override
  Future<SystemAuthResult> authenticate(String localizedReason) async =>
      throw StateError('platform auth unavailable');

  @override
  Future<bool> isQuickAuthEnabled() async => true;

  @override
  Future<bool> isSystemAuthAvailable() async => true;

  @override
  Future<bool> verifyPassword(String password) async => true;
}

class _ThrowingAvailabilityAuthentication implements LockAuthenticationAdapter {
  const _ThrowingAvailabilityAuthentication();

  @override
  Future<SystemAuthResult> authenticate(String localizedReason) async =>
      SystemAuthResult.unavailable;

  @override
  Future<bool> isQuickAuthEnabled() async => true;

  @override
  Future<bool> isSystemAuthAvailable() async =>
      throw StateError('platform capability unavailable');

  @override
  Future<bool> verifyPassword(String password) async => true;
}
