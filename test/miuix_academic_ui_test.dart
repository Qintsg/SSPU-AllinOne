/*
 * Miuix 移动导航和教务任务页的组件测试
 * @Project : SSPU-AllinOne
 * @File : miuix_academic_ui_test.dart
 * @Author : Codex
 * @Date : 2026-11-19
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

/// 验证生产控件的触控、无障碍和约束行为。
void main() {
  testWidgets('320 宽的大字体底栏可切换页面并保持更多为独立操作', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    const items = [
      YhNavigationItem(icon: YhIcons.home, label: '主页'),
      YhNavigationItem(icon: YhIcons.academic, label: '教务'),
      YhNavigationItem(icon: YhIcons.calendar, label: '课表'),
      YhNavigationItem(icon: YhIcons.info, label: '信息'),
      YhNavigationItem(icon: YhIcons.more, label: '更多'),
    ];
    var index = 0;
    await tester.pumpWidget(
      YhApp(
        home: StatefulBuilder(
          builder: (context, setState) => YhMiuixFloatingNavigation(
            items: items,
            selectedIndex: index,
            actionIndex: items.length - 1,
            onSelected: (selection) {
              if (selection == items.length - 1) {
                YhBottomDrawer.show<void>(
                  context,
                  title: '更多操作',
                  builder: (context) => YhMiuixButton(
                    label: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                );
              } else {
                setState(() => index = selection);
              }
            },
            child: YhPageScaffold(
              body: ListView(
                children: [
                  Text('当前页面：${items[index].label}'),
                  const SizedBox(height: 640),
                  const Text('正文末尾'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = find.byKey(const Key('mobile-bottom-navigation'));
    expect(tester.getBottomLeft(bar).dy, 720 - 34 - YhTheme.light.spacing.s);
    await tester.tap(find.text('教务'));
    await tester.pumpAndSettle();
    expect(find.text('当前页面：教务'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('教务')),
      matchesSemantics(
        label: '教务',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
        isFocusable: true,
        isInMutuallyExclusiveGroup: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text('更多'));
    await tester.pumpAndSettle();
    expect(find.text('更多操作'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('当前页面：教务'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('正文末尾'), 160);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('正文末尾')).dy,
      lessThan(tester.getTopLeft(bar).dy),
    );

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(bar).dy, 844 - 34 - YhTheme.light.spacing.s);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(bar, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('教务任务标题和新版教务入口能在窄屏换行', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    var refreshCount = 0;
    var openCount = 0;
    await tester.pumpWidget(
      YhApp(
        themeMode: YhThemeMode.dark,
        home: YhTaskPage(
          useMiuix: true,
          title: '培养方案完成情况',
          kicker: '培养方案',
          summary: '核对已修学分与待完成课程',
          source: '本专科教务',
          sourceSymbol: '学',
          primaryActionLabel: '刷新方案',
          onPrimaryAction: () => refreshCount++,
          sourceAction: YhTaskPageAction(
            label: '在新版教务查看',
            onTap: () => openCount++,
          ),
          body: const Text('暂无可展示的方案'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('刷新方案'));
    await tester.pumpAndSettle();
    expect(refreshCount, 1);
    expect(find.text('在新版教务查看'), findsOneWidget);
    expect(find.text('暂无可展示的方案'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.text('刷新方案').hitTestable(), findsOneWidget);
    await tester.tap(find.text('在新版教务查看'));
    await tester.pumpAndSettle();
    expect(openCount, 1);
    expect(tester.takeException(), isNull);
  });
}
