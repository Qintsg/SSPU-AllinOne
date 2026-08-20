/*
 * 清源组件工作台响应式、滚动与命中区域测试
 * @Project : SSPU-AllinOne
 * @File : qingyuan_component_workbench_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

import 'visual/qingyuan_component_visual_panels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [360.0, 768.0, 1200.0]) {
    testWidgets('${width.toInt()}px 使用冻结工作台列数且无溢出', (tester) async {
      await _pumpWorkbench(tester, width: width);

      final first = tester.getRect(
        find.byKey(const ValueKey('component-group-按钮与行动')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('component-group-选择与开关')),
      );
      final third = tester.getRect(
        find.byKey(const ValueKey('component-group-连续进度')),
      );

      if (width == 360) {
        expect(second.left, closeTo(first.left, 0.1));
        expect(third.left, closeTo(first.left, 0.1));
        expect(first.top, lessThan(second.top));
        expect(second.top, lessThan(third.top));
      } else if (width == 768) {
        expect(second.top, closeTo(first.top, 0.1));
        expect(third.top, greaterThan(first.top));
      } else {
        expect(second.top, closeTo(first.top, 0.1));
        expect(third.top, closeTo(first.top, 0.1));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('360px 最后一组组件可滚动到达且主要行动保持 48dp', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpWorkbench(tester, width: 360);

    final lastGroup = find.byKey(const ValueKey('component-group-连续进度'));
    await tester.ensureVisible(lastGroup);
    await tester.pump();

    expect(lastGroup, findsOneWidget);
    final action = find.bySemanticsLabel('主要操作');
    expect(action, findsOneWidget);
    final actionSize = tester.getSize(action);
    expect(actionSize.width, greaterThanOrEqualTo(48));
    expect(actionSize.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> _pumpWorkbench(
  WidgetTester tester, {
  required double width,
}) async {
  const height = 900.0;
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    YhApp(
      themeMode: YhThemeMode.light,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(1200, height),
          devicePixelRatio: 1,
          disableAnimations: true,
        ).copyWith(size: Size(width, height)),
        child: SizedBox.expand(child: componentActionsPanel()),
      ),
    ),
  );
  await tester.pump();
}
