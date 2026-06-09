/*
 * Fluent 交互无障碍测试 — 校验键盘选择与导航激活
 * @Project : SSPU-AllinOne
 * @File : fluent_accessibility_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/widgets/settings_widgets.dart';

void main() {
  Widget buildSettingsNavHarness({
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
  }) {
    return FluentApp(
      home: ScaffoldPage(
        content: StatefulBuilder(
          builder: (context, setState) {
            void selectIndex(int index) {
              setState(() => selectedIndex = index);
              onSelected?.call(index);
            }

            return Column(
              children: [
                buildSettingsNavItem(
                  context: context,
                  index: 0,
                  selectedIndex: selectedIndex,
                  icon: FluentIcons.settings,
                  label: '常规设置',
                  onTap: () => selectIndex(0),
                ),
                buildSettingsNavItem(
                  context: context,
                  index: 1,
                  selectedIndex: selectedIndex,
                  icon: FluentIcons.sync,
                  label: '自动刷新设置',
                  onTap: () => selectIndex(1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  BoxDecoration navItemDecoration(WidgetTester tester, String label) {
    final finder = find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    );
    return tester.widget<AnimatedContainer>(finder.first).decoration!
        as BoxDecoration;
  }

  BoxDecoration navItemIndicatorDecoration(WidgetTester tester, String label) {
    final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
    final indicator = find.descendant(
      of: row.first,
      matching: find.byType(AnimatedContainer),
    );
    return tester.widget<AnimatedContainer>(indicator.first).decoration!
        as BoxDecoration;
  }

  Icon navItemIcon(WidgetTester tester, String label, IconData icon) {
    final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
    return tester.widget<Icon>(
      find.descendant(of: row.first, matching: find.byIcon(icon)).first,
    );
  }

  ResourceDictionary navResources(WidgetTester tester, String label) {
    return FluentTheme.of(tester.element(find.text(label))).resources;
  }

  testWidgets('FluentSelect 支持键盘打开、移动并选择选项', (tester) async {
    var selectedValue = 0;

    await tester.pumpWidget(
      FluentApp(
        home: ScaffoldPage(
          content: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: FluentSelect<int>(
                  value: selectedValue,
                  items: const [
                    FluentSelectItem(value: 0, child: Text('一')),
                    FluentSelectItem(value: 1, child: Text('二')),
                    FluentSelectItem(value: 2, child: Text('三')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedValue = value);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('三'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selectedValue, 1);
    expect(find.text('三'), findsNothing);
  });

  testWidgets('设置侧栏导航项支持键盘聚焦并激活', (tester) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      buildSettingsNavHarness(onSelected: (index) => selectedIndex = index),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });

  testWidgets('设置侧栏导航项 hover 移出后恢复默认背景', (tester) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });

    await tester.pumpWidget(buildSettingsNavHarness());

    final resources = navResources(tester, '常规设置');
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);

    expect(
      navItemDecoration(tester, '自动刷新设置').color,
      resources.subtleFillColorTransparent,
    );

    await pointer.moveTo(tester.getCenter(find.text('自动刷新设置')));
    await tester.pump();
    expect(
      navItemDecoration(tester, '自动刷新设置').color,
      resources.subtleFillColorSecondary,
    );

    await pointer.moveTo(tester.getCenter(find.text('常规设置')));
    await tester.pump();
    expect(
      navItemDecoration(tester, '自动刷新设置').color,
      resources.subtleFillColorTransparent,
    );
  });

  testWidgets('设置侧栏导航项 selected hover 不覆盖选中身份', (tester) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });

    await tester.pumpWidget(buildSettingsNavHarness());

    final colors = tester.element(find.text('常规设置')).fluentColors;
    final resources = navResources(tester, '常规设置');
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await pointer.moveTo(tester.getCenter(find.text('常规设置')));
    await tester.pump();

    expect(
      navItemDecoration(tester, '常规设置').color,
      resources.subtleFillColorTertiary,
    );
    expect(
      navItemIndicatorDecoration(tester, '常规设置').color,
      colors.brandBackground,
    );
    expect(
      navItemIcon(tester, '常规设置', FluentIcons.settings).color,
      colors.brandForeground1,
    );
    expect(
      tester.widget<Text>(find.text('常规设置')).style?.color,
      colors.brandForeground1,
    );
  });

  testWidgets('设置侧栏导航项键盘焦点只显示焦点边框', (tester) async {
    await tester.pumpWidget(buildSettingsNavHarness());

    final colors = tester.element(find.text('自动刷新设置')).fluentColors;
    final resources = navResources(tester, '自动刷新设置');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final decoration = navItemDecoration(tester, '自动刷新设置');
    expect(decoration.color, resources.subtleFillColorTransparent);
    expect(decoration.border?.top.color, colors.brandStroke1);
  });

  testWidgets('设置侧栏导航项快速划过时旧项不残留 hover 背景', (tester) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });

    await tester.pumpWidget(buildSettingsNavHarness());

    final resources = navResources(tester, '常规设置');
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await pointer.moveTo(tester.getCenter(find.text('自动刷新设置')));
    await tester.pump();
    await pointer.moveTo(tester.getCenter(find.text('常规设置')));
    await tester.pump();
    await pointer.moveTo(tester.getCenter(find.text('自动刷新设置')));
    await tester.pump();

    expect(
      navItemDecoration(tester, '常规设置').color,
      resources.subtleFillColorSecondary,
    );
    expect(
      navItemDecoration(tester, '自动刷新设置').color,
      resources.subtleFillColorSecondary,
    );
  });

  testWidgets('FluentSurface 和 FluentCard 支持键盘激活', (tester) async {
    var activatedSurface = false;
    var activatedCard = false;

    await tester.pumpWidget(
      FluentApp(
        home: ScaffoldPage(
          content: Column(
            children: [
              FluentSurface(
                onPressed: () => activatedSurface = true,
                child: const Text('可交互表面'),
              ),
              FluentCard(
                onPressed: () => activatedCard = true,
                child: const Text('可交互卡片'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activatedSurface, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 200));
    expect(activatedCard, isTrue);
  });
}
