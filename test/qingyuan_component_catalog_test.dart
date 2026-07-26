/* 清源 44 组件目录回归 — 补充扩展组件的交互、语义与主题覆盖。 */

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

void main() {
  testWidgets('清源操作组件支持选择、键盘和 48dp 触控目标', (tester) async {
    var checked = false;
    var radio = 'a';
    var segment = 'a';
    var slider = 0.2;
    var step = 0;
    var fabTaps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      YhApp(
        home: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 700,
            child: Column(
              children: [
                YhFab(
                  icon: YhIcons.add,
                  semanticLabel: '新建',
                  onTap: () => fabTaps += 1,
                ),
                YhSegmented<String>(
                  options: const [
                    YhSegmentedOption(value: 'a', label: '甲'),
                    YhSegmentedOption(value: 'b', label: '乙'),
                  ],
                  value: segment,
                  onChanged: (value) => setState(() => segment = value),
                ),
                YhCheckbox(
                  label: '同意',
                  value: checked,
                  onChanged: (value) =>
                      setState(() => checked = value ?? false),
                ),
                YhRadio<String>(
                  label: '选项乙',
                  value: 'b',
                  groupValue: radio,
                  onChanged: (value) => setState(() => radio = value),
                ),
                YhSlider(
                  label: '透明度',
                  value: slider,
                  onChanged: (value) => setState(() => slider = value),
                ),
                YhStepper(
                  steps: const ['开始', '确认', '完成'],
                  currentStep: step,
                  onStepSelected: (value) => setState(() => step = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('乙'));
    await tester.tap(find.text('同意'));
    await tester.tap(find.text('选项乙'));
    await tester.tap(find.text('确认'));
    await tester.tap(find.byType(YhFab));
    await tester.pump();

    expect(segment, 'b');
    expect(checked, isTrue);
    expect(radio, 'b');
    expect(step, 1);
    expect(fabTaps, 1);
    expect(tester.getSize(find.byType(YhFab)).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(find.text('同意')).flagsCollection.isToggled,
      Tristate.isTrue,
    );

    final oldSlider = slider;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(slider, greaterThanOrEqualTo(oldSlider));
    semantics.dispose();
  });

  testWidgets('清源输入扩展覆盖错误、日期动作与 OTP 完成状态', (tester) async {
    final otp = TextEditingController();
    var completed = '';
    var dateTaps = 0;
    addTearDown(otp.dispose);

    await tester.pumpWidget(
      YhApp(
        home: Column(
          children: [
            const YhSearch(hint: '搜索课程'),
            const YhTextarea(label: '说明', errorText: '请补充说明'),
            YhDatePicker(
              label: '开始日期',
              errorText: '请选择日期',
              onTap: () => dateTaps += 1,
            ),
            YhOtp(
              controller: otp,
              length: 6,
              onCompleted: (value) => completed = value,
            ),
          ],
        ),
      ),
    );

    expect(find.text('请补充说明'), findsOneWidget);
    expect(find.text('请选择日期'), findsOneWidget);
    await tester.tap(find.text('选择日期'));
    expect(dateTaps, 1);
    await tester.enterText(find.byType(EditableText).last, '1234567');
    await tester.pump();
    expect(otp.text, '123456');
    expect(completed, '123456');
  });

  testWidgets('清源输入框在减少动态时立即提交焦点边框', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: YhTextField(label: '主题'),
        ),
      ),
    );

    final animated = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(YhTextField),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(animated.duration, Duration.zero);
  });

  testWidgets('清源多行输入将正文和提示统一置于顶部', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: YhTextField(label: '正文', hint: '输入邮件正文', maxLines: 4),
      ),
    );

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(YhTextField),
        matching: find.byType(Stack),
      ),
    );
    final animated = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(YhTextField),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final theme = tester.element(find.byType(YhTextField)).yhTheme;
    final padding = animated.padding!.resolve(TextDirection.ltr);
    expect(stack.alignment, Alignment.topLeft);
    expect(padding.top, theme.spacing.s);
    expect(padding.bottom, theme.spacing.s);
  });

  testWidgets('清源无弱化禁用输入保持前景与禁用语义', (tester) async {
    final controller = TextEditingController(text: '课程安排确认');
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      YhApp(
        home: YhTextField(
          label: '主题',
          controller: controller,
          enabled: false,
          showDisabledAppearance: false,
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(YhTextField),
        matching: find.byType(Opacity),
      ),
    );
    expect(editable.readOnly, isTrue);
    expect(opacity.opacity, 1);
    expect(
      tester.getSemantics(find.byType(YhTextField)).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .widget<ExcludeFocus>(
            find.descendant(
              of: find.byType(YhTextField),
              matching: find.byType(ExcludeFocus),
            ),
          )
          .excluding,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('清源禁用输入仅弱化控件容器', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: YhTextField(label: '学号', helper: '10 位数字', enabled: false),
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(YhTextField),
        matching: find.byType(Opacity),
      ),
    );
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final theme = tester.element(find.byType(YhTextField)).yhTheme;
    expect(opacity.opacity, 0.45);
    expect(opacity.child, isA<ExcludeFocus>());
    expect(editable.style.color, theme.color.foreground);
  });

  testWidgets('清源页签在窄宽度横向滚动并露出当前项', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: YhTabs<int>(
              tabs: [
                YhTab(value: 1, label: '周一'),
                YhTab(value: 2, label: '周二'),
                YhTab(value: 3, label: '周三'),
                YhTab(value: 4, label: '周四'),
                YhTab(value: 5, label: '周五'),
                YhTab(value: 6, label: '周六 · 今天'),
                YhTab(value: 7, label: '周日'),
              ],
              value: 6,
              onChanged: null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final selected = tester.getRect(find.text('周六 · 今天'));
    expect(selected.left, greaterThanOrEqualTo(0));
    expect(selected.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('清源页签横向露出当前项时不滚动外层纵向页面', (tester) async {
    final outerController = ScrollController();
    addTearDown(outerController.dispose);
    await tester.pumpWidget(
      YhApp(
        home: SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: outerController,
            child: Column(
              children: [
                const SizedBox(height: 300),
                SizedBox(
                  width: 320,
                  child: YhTabs<int>(
                    tabs: const [
                      YhTab(value: 1, label: '周一'),
                      YhTab(value: 2, label: '周二'),
                      YhTab(value: 3, label: '周三'),
                      YhTab(value: 4, label: '周四'),
                      YhTab(value: 5, label: '周五'),
                      YhTab(value: 6, label: '周六 · 今天'),
                    ],
                    value: 6,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(outerController.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('清源页签响应左右方向键并更新当前项', (tester) async {
    var value = 1;
    await tester.pumpWidget(
      YhApp(
        home: StatefulBuilder(
          builder: (context, setState) => YhTabs<int>(
            tabs: const [
              YhTab(value: 1, label: '甲'),
              YhTab(value: 2, label: '乙'),
              YhTab(value: 3, label: '丙'),
            ],
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 2);
  });

  testWidgets('清源状态药丸与课程块遵守紧凑视觉和状态语义', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const YhApp(
        home: Column(
          children: [
            YhStatusPill(label: '正常', kind: YhStatusKind.success),
            YhCourseBlock(
              name: '软件工程实践',
              time: '实训中心 405',
              ongoing: true,
              conflict: true,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byType(YhStatusPill)).height,
      lessThanOrEqualTo(20),
    );
    final courseSemantics = tester.getSemantics(find.byType(YhCourseBlock));
    expect(courseSemantics.label, contains('进行中'));
    expect(courseSemantics.label, contains('时间冲突'));
    semantics.dispose();
  });

  testWidgets('清源 neutral 状态药丸保留几何但不绘制状态底色', (tester) async {
    await tester.pumpWidget(const YhApp(home: YhStatusPill(label: '09:30 同步')));

    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(YhStatusPill),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration as BoxDecoration)
        .toList(growable: false);
    expect(decorations, hasLength(2));
    expect(decorations.every((decoration) => decoration.color?.a == 0), isTrue);
  });

  testWidgets('清源快捷入口区分外部打开与独立收藏语义', (tester) async {
    var opens = 0;
    var favorites = 0;
    await tester.pumpWidget(
      YhApp(
        home: YhQuickLink(
          icon: YhIcons.academic,
          label: '超星学习通',
          subtitle: '课程学习与作业',
          color: YhTheme.light.color.serviceAcademic,
          onTap: () => opens += 1,
          onToggleFavorite: () => favorites += 1,
        ),
      ),
    );

    expect(find.bySemanticsLabel('超星学习通，外部链接，将打开外部应用'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('标记为常用入口'));
    await tester.pump();
    expect(favorites, 1);
    expect(opens, 0);
  });

  testWidgets('清源环形活动指示只暴露加载语义而不伪造百分比', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const YhApp(home: YhRing.activity(label: '正在整理首页数据')),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('正在整理首页数据'));
    expect(node.value, '加载中');
    expect(find.textContaining('%'), findsNothing);
    semantics.dispose();
  });

  testWidgets('清源容器、数据与校园域组件在亮暗主题完整渲染', (tester) async {
    for (final mode in [YhThemeMode.light, YhThemeMode.dark]) {
      await tester.pumpWidget(
        YhApp(
          themeMode: mode,
          home: SingleChildScrollView(
            child: Column(
              children: [
                const YhTile(child: Text('磁贴')),
                const YhListItem(title: '列表项', subtitle: '说明'),
                const YhAccordion(title: '折叠面板', content: Text('内容')),
                const YhToast(message: '保存成功'),
                const YhSkeleton(),
                const YhTabs<String>(
                  tabs: [
                    YhTab(value: 'a', label: '页签甲'),
                    YhTab(value: 'b', label: '页签乙'),
                  ],
                  value: 'a',
                  onChanged: null,
                ),
                const YhBadge(label: '3'),
                const YhStatusPill(label: '正常', kind: YhStatusKind.success),
                const YhAvatar(semanticLabel: '张同学', initials: '张'),
                const YhMetricCard(label: '平均绩点', value: '3.82'),
                const YhRing(value: 0.82),
                const YhFeedItem(title: '校园资讯', summary: '摘要', source: '学校官网'),
                const YhSourceBadge(label: '教务处'),
                const YhTodayCard(
                  title: '今天',
                  subtitle: '7 月 19 日',
                  child: Text('两节课程'),
                ),
                const YhCourseBlock(name: '高等数学', time: '08:00'),
                const YhAiMessage(
                  message: '正在查询',
                  role: YhMessageRole.assistant,
                  pending: true,
                ),
                const YhBalanceModule(label: '校园卡余额', balance: '¥ 88.00'),
                const YhAttendanceItem(
                  title: '体育签到',
                  detail: '操场',
                  status: '已签到',
                  kind: YhStatusKind.success,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('校园卡余额'), findsOneWidget);
      expect(find.text('已签到'), findsOneWidget);
      expect(find.byType(YhSkeleton), findsOneWidget);
    }
  });

  testWidgets('清源列表行包含完整语义、选中态、按压反馈和单行截断', (tester) async {
    final semantics = tester.ensureSemantics();
    const longTitle = '这是一条需要在有限宽度内保持单行显示的校园通知标题';
    await tester.pumpWidget(
      const YhApp(
        home: SizedBox(
          width: 180,
          child: YhListItem(
            title: longTitle,
            subtitle: '教务处 · 今天',
            selected: true,
            onTap: _noop,
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel('$longTitle，教务处 · 今天'),
    );
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    final title = tester.widget<Text>(find.text(longTitle));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);

    final coloredBox = find.descendant(
      of: find.byType(YhListItem),
      matching: find.byType(ColoredBox),
    );
    final restColor = tester.widget<ColoredBox>(coloredBox).color;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(YhListItem)),
    );
    await tester.pump();
    expect(tester.widget<ColoredBox>(coloredBox).color, isNot(restColor));
    await gesture.up();
    semantics.dispose();
  });
}

void _noop() {}
