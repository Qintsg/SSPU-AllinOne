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
}
