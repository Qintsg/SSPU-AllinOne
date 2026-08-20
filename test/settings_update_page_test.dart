/*
 * 清源应用更新任务页与设置摘要测试
 * @Project : SSPU-AllinOne
 * @File : settings_update_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/settings_update_page.dart';
import 'package:sspu_allinone/services/app_update_service.dart';
import 'package:sspu_allinone/widgets/settings_update_section.dart';

void main() {
  testWidgets('应用更新使用真实任务页框架并保留手动联网边界', (tester) async {
    final service = _PageUpdateService();
    await tester.pumpWidget(
      YhApp(home: SettingsUpdatePage(updateService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('应用更新'), findsOneWidget);
    expect(find.text('GitHub Releases'), findsWidgets);
    expect(find.text('当前版本 1.0.0'), findsOneWidget);
    expect(find.text('更新通道 stable'), findsOneWidget);
    expect(find.text('自动检查已关闭'), findsOneWidget);
    expect(service.checkCalls, 0);

    await tester.tap(find.bySemanticsLabel('检查更新'));
    await tester.pumpAndSettle();

    expect(service.checkCalls, 1);
    expect(find.text('当前已是正式版最新版本。'), findsOneWidget);
  });

  testWidgets('360 宽度的初始态直接展示可操作账本', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(home: SettingsUpdatePage(updateService: _PageUpdateService())),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前版本 1.0.0'), findsOneWidget);
    expect(find.text('更新通道 stable'), findsOneWidget);
    expect(find.text('自动检查已关闭'), findsOneWidget);
    expect(find.text('尚未读取应用更新'), findsNothing);
  });

  testWidgets('常规设置只保留应用更新摘要与独立页入口', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      YhApp(home: SettingsUpdateSummary(onOpenDetails: () => opened = true)),
    );

    expect(find.text('更新与版本'), findsOneWidget);
    expect(find.text('正式版'), findsNothing);
    await tester.tap(find.text('打开应用更新'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('本地版本读取失败后可用手动检查结果恢复', (tester) async {
    final service = _PageUpdateService(failCurrentVersion: true);
    await tester.pumpWidget(
      YhApp(home: SettingsUpdatePage(updateService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('无法读取当前应用版本'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('检查更新'));
    await tester.pumpAndSettle();

    expect(find.text('当前版本 1.0.0'), findsOneWidget);
    expect(find.textContaining('无法读取当前应用版本'), findsNothing);
  });

  testWidgets('更新服务换代会释放旧检查且旧结果不得回写', (tester) async {
    final oldService = _DelayedPageUpdateService(currentVersion: '1.0.0');
    await tester.pumpWidget(
      YhApp(home: SettingsUpdatePage(updateService: oldService)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('检查更新'));
    await tester.pump();
    expect(find.text('检查中'), findsOneWidget);

    final currentService = _PageUpdateService(currentVersion: '2.0.0');
    await tester.pumpWidget(
      YhApp(home: SettingsUpdatePage(updateService: currentService)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('检查中'), findsNothing);
    expect(find.text('当前版本 2.0.0'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('检查更新'));
    await tester.pump();
    await tester.pump();
    expect(find.text('当前服务检查结果'), findsOneWidget);

    oldService.completeCheck(message: '旧服务检查结果');
    await tester.pump();
    await tester.pump();

    expect(find.text('当前服务检查结果'), findsOneWidget);
    expect(find.text('旧服务检查结果'), findsNothing);
  });
}

class _PageUpdateService extends AppUpdateService {
  _PageUpdateService({
    this.failCurrentVersion = false,
    this.currentVersion = '1.0.0',
  });

  final bool failCurrentVersion;
  final String currentVersion;
  int checkCalls = 0;

  @override
  Future<String> loadCurrentVersion() async {
    if (failCurrentVersion) throw StateError('version unavailable');
    return currentVersion;
  }

  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) async {
    checkCalls += 1;
    return AppUpdateCheckResult(
      status: AppUpdateStatus.upToDate,
      currentVersion: currentVersion,
      channel: channel,
      release: null,
      recommendedAsset: null,
      message: currentVersion == '1.0.0' ? '当前已是正式版最新版本。' : '当前服务检查结果',
    );
  }
}

class _DelayedPageUpdateService extends AppUpdateService {
  _DelayedPageUpdateService({required this.currentVersion});

  final String currentVersion;
  final Completer<AppUpdateCheckResult> _checkCompleter = Completer();

  /// 返回测试固定的当前版本。
  ///
  /// :returns: 当前版本字符串。
  @override
  Future<String> loadCurrentVersion() async => currentVersion;

  /// 返回可由测试控制完成时机的检查结果。
  ///
  /// :param channel: 本次检查使用的更新通道。
  /// :returns: 延迟完成的版本检查结果。
  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) => _checkCompleter.future;

  /// 完成尚未返回的版本检查。
  ///
  /// :param message: 测试结果中展示的消息。
  /// :returns: None。
  void completeCheck({required String message}) {
    _checkCompleter.complete(
      AppUpdateCheckResult(
        status: AppUpdateStatus.upToDate,
        currentVersion: currentVersion,
        channel: AppUpdateChannel.stable,
        release: null,
        recommendedAsset: null,
        message: message,
      ),
    );
  }
}
