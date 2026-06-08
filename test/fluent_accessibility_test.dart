/*
 * Fluent 交互无障碍测试 — 校验键盘选择与导航激活
 * @Project : SSPU-AllinOne
 * @File : fluent_accessibility_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/widgets/settings_widgets.dart';

void main() {
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
      FluentApp(
        home: ScaffoldPage(
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  buildSettingsNavItem(
                    context: context,
                    index: 0,
                    selectedIndex: selectedIndex,
                    icon: FluentIcons.settings,
                    label: '常规设置',
                    onTap: () => setState(() => selectedIndex = 0),
                  ),
                  buildSettingsNavItem(
                    context: context,
                    index: 1,
                    selectedIndex: selectedIndex,
                    icon: FluentIcons.sync,
                    label: '自动刷新设置',
                    onTap: () => setState(() => selectedIndex = 1),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
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
