/* 清源响应式应用壳测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

void main() {
  const items = <YhNavigationItem>[
    YhNavigationItem(icon: YhIcons.home, label: '主页'),
    YhNavigationItem(icon: YhIcons.academic, label: '教务'),
    YhNavigationItem(icon: YhIcons.calendar, label: '课表'),
  ];

  testWidgets('compact 使用底部导航并切换目的地', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var index = 0;

    await tester.pumpWidget(
      YhApp(
        home: StatefulBuilder(
          builder: (context, setState) => YhResponsiveShell(
            items: items,
            index: index,
            onChanged: (value) => setState(() => index = value),
            child: Text('页面 $index'),
          ),
        ),
      ),
    );

    expect(find.byType(YhBottomNav), findsOneWidget);
    expect(find.byType(YhNavRail), findsNothing);
    await tester.tap(find.text('教务'));
    await tester.pump();
    expect(find.text('页面 1'), findsOneWidget);
  });

  testWidgets('medium 及以上使用导航轨且不重复显示底栏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const YhApp(
        home: YhResponsiveShell(
          items: items,
          index: 0,
          onChanged: _noop,
          child: Text('主页内容'),
        ),
      ),
    );

    expect(find.byType(YhNavRail), findsOneWidget);
    expect(find.byType(YhBottomNav), findsNothing);
    expect(find.text('主页内容'), findsOneWidget);
  });

  testWidgets('页面框架提供固定高度顶栏和安全内容区', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: YhPageScaffold(
          appBar: YhAppBar(title: '课程表'),
          body: Text('课程内容'),
        ),
      ),
    );

    expect(tester.getSize(find.byType(YhAppBar)).height, 56);
    expect(find.text('课程表'), findsOneWidget);
    expect(find.text('课程内容'), findsOneWidget);
  });
}

void _noop(int value) {}
