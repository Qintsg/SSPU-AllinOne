/* 清源选择与状态控件测试。 */

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

void main() {
  testWidgets('清源开关即时切换并暴露选中与禁用语义', (tester) async {
    var value = false;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      YhApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              YhSwitch(
                value: value,
                semanticLabel: '自动刷新',
                onChanged: (next) => setState(() => value = next),
              ),
              const YhSwitch(
                value: false,
                semanticLabel: '禁用开关',
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('自动刷新'));
    await tester.pump();
    expect(value, isTrue);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('自动刷新'))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('禁用开关'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    semantics.dispose();
  });

  testWidgets('清源筹码展示选中态并提供独立删除操作', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      YhApp(
        home: Wrap(
          children: [
            const YhChip(label: '教务', selected: true, onTap: _noop),
            YhChip(label: '高数', onDeleted: () => deleted = true),
          ],
        ),
      ),
    );

    expect(find.byIcon(YhIcons.check), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('删除 高数'));
    expect(deleted, isTrue);
  });

  testWidgets('清源分页只展示首尾和当前邻页并可跳转', (tester) async {
    var selected = 5;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      YhApp(
        home: StatefulBuilder(
          builder: (context, setState) => YhPagination(
            page: selected,
            pageCount: 12,
            onChanged: (page) => setState(() => selected = page),
          ),
        ),
      ),
    );

    expect(find.text('…'), findsNWidgets(2));
    expect(find.text('2'), findsNothing);
    await tester.tap(find.bySemanticsLabel('第 6 页'));
    await tester.pump();
    expect(selected, 6);
    semantics.dispose();
  });

  testWidgets('清源分页在紧凑宽度自动降级且不产生布局溢出', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: Center(
          child: SizedBox(
            width: 312,
            child: YhPagination(page: 3, pageCount: 8, onChanged: (_) {}),
          ),
        ),
      ),
    );

    expect(find.text('第 3 / 8 页'), findsOneWidget);
    expect(find.text('…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('清源选择器支持指针选择与方向键确认', (tester) async {
    String? selected;
    await tester.pumpWidget(
      YhApp(
        home: Center(
          child: SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, setState) => YhSelect<String>(
                label: '来源',
                value: selected,
                options: const [
                  YhSelectOption(value: 'official', label: '学校官网'),
                  YhSelectOption(value: 'wechat', label: '微信公众号'),
                ],
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('请选择'));
    await tester.pump();
    await tester.tap(find.text('学校官网').last);
    await tester.pump();
    expect(selected, 'official');

    await tester.tap(find.text('学校官网').first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 'wechat');
  });

  testWidgets('清源进度分别呈现百分比与未知加载语义', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const YhApp(
        home: Column(
          children: [
            YhProgress(value: 0.64, semanticLabel: '下载进度'),
            YhProgress(value: null, semanticLabel: '正在同步'),
          ],
        ),
      ),
    );

    expect(find.text('64%'), findsOneWidget);
    expect(find.text('加载中'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('下载进度')).value, '64%');
    expect(tester.getSemantics(find.bySemanticsLabel('正在同步')).value, '加载中');
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('清源披露面板支持键盘展开与状态语义', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const YhApp(
        home: YhDisclosure(
          title: '注册方式',
          leadingIcon: YhIcons.info,
          content: Text('说明内容'),
        ),
      ),
    );

    expect(find.text('说明内容'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('说明内容'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('收起注册方式'))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
    semantics.dispose();
  });
}

void _noop() {}
