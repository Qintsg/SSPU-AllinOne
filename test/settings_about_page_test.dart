/* 清源关于任务页与设置摘要行为测试。 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/settings_about_page.dart';

void main() {
  testWidgets('真实关于任务页先显示加载再呈现三项构建信息', (tester) async {
    final pending = Completer<SettingsAboutSnapshot>();
    await tester.pumpWidget(
      YhApp(home: SettingsAboutPage(loader: () => pending.future)),
    );
    await tester.pump();

    expect(find.text('关于工大聚合'), findsOneWidget);
    expect(find.textContaining('正在读取本机应用构建信息'), findsOneWidget);
    expect(find.text('处理中'), findsNWidgets(3));

    pending.complete(
      const SettingsAboutSnapshot(version: '2.1.0', buildNumber: '42'),
    );
    await tester.pumpAndSettle();

    expect(find.text('版本 2.1.0+42'), findsOneWidget);
    expect(find.text('清源 0.4.0'), findsOneWidget);
    expect(find.text('Flutter 3.44.0'), findsOneWidget);
  });

  testWidgets('版本读取失败保留更新和许可入口并可重试恢复', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      YhApp(
        home: SettingsAboutPage(
          loader: () async {
            calls += 1;
            if (calls == 1) throw StateError('metadata unavailable');
            return const SettingsAboutSnapshot(version: '1.2.3');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('无法读取当前应用版本'), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('版本 1.2.3'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('检查更新、法律与许可使用明确独立入口', (tester) async {
    var updateCalls = 0;
    var legalCalls = 0;
    var licenseCalls = 0;
    await tester.pumpWidget(
      YhApp(
        home: SettingsAboutPage(
          previewState: SettingsAboutState.content,
          onCheckUpdate: () => updateCalls += 1,
          onOpenLegal: () => legalCalls += 1,
          onOpenLicenses: () => licenseCalls += 1,
        ),
      ),
    );

    await tester.tap(find.text('检查更新'));
    expect(updateCalls, 1);
    await tester.tap(find.text('许可清单'));
    await tester.pump();
    expect(licenseCalls, 1);

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看法律与隐私'));
    expect(legalCalls, 1);
  });

  testWidgets('外部确认限制焦点且 Escape 取消后归还更多操作', (tester) async {
    var launchCalls = 0;
    await tester.pumpWidget(
      YhApp(
        home: SettingsAboutPage(
          loader: () async => const SettingsAboutSnapshot(version: '1.0.0'),
          launchUrlOverride: (_) async {
            launchCalls += 1;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开 GitHub 仓库'));
    await tester.pumpAndSettle();

    FocusableActionDetector detectorFor(String label) =>
        tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.bySemanticsLabel(label),
            matching: find.byType(FocusableActionDetector),
          ),
        );

    expect(detectorFor('取消').focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(detectorFor('继续打开').focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(launchCalls, 0);
    expect(find.textContaining('已取消打开 GitHub'), findsOneWidget);
    expect(detectorFor('更多操作').focusNode?.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('系统浏览器打开失败显示恢复方向', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: SettingsAboutPage(
          loader: () async => const SettingsAboutSnapshot(version: '1.0.0'),
          launchUrlOverride: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开 GitHub 仓库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();

    expect(find.textContaining('系统浏览器未能打开 GitHub'), findsOneWidget);
    expect(find.text('关于工大聚合'), findsOneWidget);
  });

  testWidgets('外部打开进行中锁定更新与其它导航操作', (tester) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '进入关于',
            onTap: () => Navigator.of(context).push(
              YhPageRoute<void>(
                builder: (_) => SettingsAboutPage(
                  loader: () async =>
                      const SettingsAboutSnapshot(version: '1.0.0'),
                  launchUrlOverride: (_) => pending.future,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('进入关于'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开 GitHub 仓库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pump();

    final update = tester.widget<YhButton>(
      find.widgetWithText(YhButton, '检查更新'),
    );
    expect(update.onTap, isNull);

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<YhButton>(find.widgetWithText(YhButton, '查看开源许可')).onTap,
      isNull,
    );
    Navigator.of(tester.element(find.text('来源信息'))).pop();
    await tester.pumpAndSettle();

    final ledgerActions = <YhButton>[
      tester.widget(find.widgetWithText(YhButton, '版本详情')),
      tester.widget(find.widgetWithText(YhButton, '设计说明')),
      tester.widget(find.widgetWithText(YhButton, '许可清单')),
    ];
    expect(ledgerActions, isNotEmpty);
    expect(ledgerActions.every((action) => action.onTap == null), isTrue);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pump();
    expect(find.byType(SettingsAboutPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(SettingsAboutPage), findsOneWidget);

    pending.complete(false);
    await tester.pumpAndSettle();
  });

  testWidgets('设置分区只保留关于摘要和统一详情入口', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      YhApp(home: SettingsAboutSummary(onOpenDetails: () => opened = true)),
    );

    expect(find.text('使用/参考的开源项目'), findsNothing);
    await tester.tap(find.text('打开关于工大聚合'));
    expect(opened, isTrue);
  });

  testWidgets('许可入口进入单一职责任务页且窄屏不依赖横向表格', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const YhApp(
        home: SettingsAboutPage(previewState: SettingsAboutState.content),
      ),
    );

    await tester.tap(find.text('许可清单'));
    await tester.pumpAndSettle();

    expect(find.byType(OpenSourceLicensesPage), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);
    expect(find.text('著作人'), findsNothing);
    expect(find.text('GitHub 仓库'), findsNothing);
    expect(find.byType(Table), findsNothing);
    expect(find.bySemanticsLabel('打开 Flutter'), findsOneWidget);
  });

  testWidgets('许可外链取消后保留页面与阅读位置', (tester) async {
    var launchCalls = 0;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(
        home: OpenSourceLicensesPage(
          launchUrlOverride: (_) async {
            launchCalls += 1;
            return true;
          },
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('打开 MiSans'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final initialOffset = scrollable.position.pixels;
    expect(initialOffset, greaterThan(0));

    final restoredLink = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.bySemanticsLabel('打开 MiSans'),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    restoredLink.focusNode?.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(launchCalls, 0);
    expect(find.text('已取消打开 MiSans'), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);
    expect(scrollable.position.pixels, initialOffset);
    expect(restoredLink.focusNode?.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('许可外链失败给出恢复方向且不丢失清单', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: OpenSourceLicensesPage(launchUrlOverride: (_) async => false),
      ),
    );

    await tester.tap(find.bySemanticsLabel('打开 Flutter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();

    expect(find.textContaining('系统浏览器未能打开 Flutter'), findsOneWidget);
    expect(find.text('fluentui_system_icons'), findsOneWidget);
  });

  testWidgets('许可外链打开期间锁定返回与其它项目', (tester) async {
    final pending = Completer<bool>();
    var launchCalls = 0;
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '进入许可',
            onTap: () => Navigator.of(context).push(
              YhPageRoute<void>(
                builder: (_) => OpenSourceLicensesPage(
                  launchUrlOverride: (_) {
                    launchCalls += 1;
                    return pending.future;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('进入许可'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('打开 Flutter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();

    expect(find.textContaining('已锁定其它外部链接'), findsOneWidget);
    expect(
      tester.widget<YhButton>(find.widgetWithText(YhButton, '返回关于')).onTap,
      isNull,
    );
    await tester.tap(find.bySemanticsLabel('打开 fluentui_system_icons'));
    await tester.pump();
    expect(launchCalls, 1);
    expect(find.text('继续打开'), findsNothing);

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pump();
    expect(find.byType(OpenSourceLicensesPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(OpenSourceLicensesPage), findsOneWidget);

    pending.complete(true);
    await tester.pumpAndSettle();
  });
}
