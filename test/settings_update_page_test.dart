/* 清源应用更新任务页与设置摘要测试。 */

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
}

class _PageUpdateService extends AppUpdateService {
  _PageUpdateService({this.failCurrentVersion = false});

  final bool failCurrentVersion;
  int checkCalls = 0;

  @override
  Future<String> loadCurrentVersion() async {
    if (failCurrentVersion) throw StateError('version unavailable');
    return '1.0.0';
  }

  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) async {
    checkCalls += 1;
    return AppUpdateCheckResult(
      status: AppUpdateStatus.upToDate,
      currentVersion: '1.0.0',
      channel: channel,
      release: null,
      recommendedAsset: null,
      message: '当前已是正式版最新版本。',
    );
  }
}
