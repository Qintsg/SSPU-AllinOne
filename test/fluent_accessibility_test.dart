/*
 * 清源交互无障碍测试 — 校验键盘选择与导航激活
 * @Project : SSPU-AllinOne
 * @File : fluent_accessibility_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart' as qingyuan;
import 'package:sspu_allinone/widgets/settings_widgets.dart';

void main() {
  Widget buildSettingsNavHarness({
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
  }) {
    return qingyuan.YhApp(
      home: StatefulBuilder(
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
                icon: qingyuan.YhIcons.settings,
                label: '常规设置',
                onTap: () => selectIndex(0),
              ),
              buildSettingsNavItem(
                context: context,
                index: 1,
                selectedIndex: selectedIndex,
                icon: qingyuan.YhIcons.sync,
                label: '自动刷新设置',
                onTap: () => selectIndex(1),
              ),
            ],
          );
        },
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

  qingyuan.YhTheme navTheme(WidgetTester tester, String label) {
    return qingyuan.YhThemeScope.of(tester.element(find.text(label)));
  }

  testWidgets('YhSelect 支持键盘打开、移动并选择选项', (tester) async {
    var selectedValue = 0;

    await tester.pumpWidget(
      qingyuan.YhApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: qingyuan.YhSelect<int>(
                label: '数字',
                showLabel: false,
                value: selectedValue,
                options: const [
                  qingyuan.YhSelectOption(value: 0, label: '一'),
                  qingyuan.YhSelectOption(value: 1, label: '二'),
                  qingyuan.YhSelectOption(value: 2, label: '三'),
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
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('三'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selectedValue, 1);
    expect(find.text('三'), findsNothing);
  });

  testWidgets('YhSelect 支持点按弹层选项', (tester) async {
    var selectedValue = 0;

    await tester.pumpWidget(
      qingyuan.YhApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: qingyuan.YhSelect<int>(
                label: '数字',
                showLabel: false,
                value: selectedValue,
                options: const [
                  qingyuan.YhSelectOption(value: 0, label: '一'),
                  qingyuan.YhSelectOption(value: 1, label: '二'),
                  qingyuan.YhSelectOption(
                    key: ValueKey('yh-select-option-2'),
                    value: 2,
                    label: '三',
                  ),
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
    );

    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('yh-select-option-2')));
    await tester.pumpAndSettle();

    expect(selectedValue, 2);
    expect(find.text('三'), findsOneWidget);
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

    final theme = navTheme(tester, '常规设置');
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);

    expect(navItemDecoration(tester, '自动刷新设置').color, const Color(0x00000000));

    await pointer.moveTo(tester.getCenter(find.text('自动刷新设置')));
    await tester.pump();
    expect(navItemDecoration(tester, '自动刷新设置').color, theme.color.sunken);

    await pointer.moveTo(tester.getCenter(find.text('常规设置')));
    await tester.pump();
    expect(navItemDecoration(tester, '自动刷新设置').color, const Color(0x00000000));
  });

  testWidgets('设置侧栏导航项 selected hover 不覆盖选中身份', (tester) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });

    await tester.pumpWidget(buildSettingsNavHarness());

    final theme = navTheme(tester, '常规设置');
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await pointer.moveTo(tester.getCenter(find.text('常规设置')));
    await tester.pump();

    expect(
      navItemDecoration(tester, '常规设置').color,
      theme.color.brand.withValues(alpha: 0.20),
    );
    expect(
      navItemIndicatorDecoration(tester, '常规设置').color,
      theme.color.brandStrong,
    );
    expect(
      navItemIcon(tester, '常规设置', qingyuan.YhIcons.settings).color,
      theme.color.brandInk,
    );
    expect(
      tester.widget<Text>(find.text('常规设置')).style?.color,
      theme.color.brandInk,
    );
  });

  testWidgets('设置侧栏导航项键盘焦点只显示焦点边框', (tester) async {
    await tester.pumpWidget(buildSettingsNavHarness());

    final semantics = tester.ensureSemantics();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      tester
          .getSemantics(find.bySemanticsLabel('自动刷新设置'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('设置侧栏导航项快速划过时旧项不残留 hover 背景', (tester) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });

    await tester.pumpWidget(buildSettingsNavHarness());

    final theme = navTheme(tester, '常规设置');
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await pointer.moveTo(tester.getCenter(find.text('自动刷新设置')));
    await tester.pump();
    await pointer.moveTo(tester.getCenter(find.text('常规设置')));
    await tester.pump();
    await pointer.moveTo(tester.getCenter(find.text('自动刷新设置')));
    await tester.pump();

    expect(navItemDecoration(tester, '常规设置').color, theme.color.brandTint);
    expect(navItemDecoration(tester, '自动刷新设置').color, theme.color.sunken);
  });

  testWidgets('YhCard 支持键盘激活', (tester) async {
    var activatedSurface = false;
    var activatedCard = false;

    await tester.pumpWidget(
      qingyuan.YhApp(
        home: Column(
          children: [
            qingyuan.YhCard(
              onTap: () => activatedSurface = true,
              child: const Text('可交互表面'),
            ),
            qingyuan.YhCard(
              onTap: () => activatedCard = true,
              child: const Text('可交互卡片'),
            ),
          ],
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
