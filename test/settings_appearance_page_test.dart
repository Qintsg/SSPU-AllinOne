/* 清源外观设置任务页测试。 */

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/settings_appearance_page.dart';
import 'package:sspu_allinone/widgets/settings_appearance_section.dart';

void main() {
  testWidgets('外观任务页保留来源并即时切换主题', (tester) async {
    YhThemeMode? changedMode;
    var applied = false;

    await tester.pumpWidget(
      YhApp(
        home: SettingsAppearancePage(
          themeMode: YhThemeMode.system,
          onChanged: (mode) => changedMode = mode,
          onApply: () => applied = true,
        ),
      ),
    );

    expect(find.text('设置'), findsWidgets);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('本机外观设置'), findsWidgets);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('亮色'), findsOneWidget);
    expect(find.text('暗色'), findsOneWidget);

    await tester.tap(find.text('暗色'));
    await tester.pump();
    expect(changedMode, YhThemeMode.dark);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('暗色'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.text('应用主题'));
    await tester.pump();
    expect(applied, isTrue);

    await tester.tap(find.text('跟随系统'));
    await tester.pump();
    final systemSegment = find.byWidgetPredicate(
      (widget) => widget is YhPressable && widget.semanticLabel == '跟随系统',
    );
    tester.widget<YhPressable>(systemSegment).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(changedMode, YhThemeMode.light);

    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    expect(find.text('来源信息'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
  });

  testWidgets('设置摘要提供完整外观任务页入口', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      YhApp(
        home: SettingsAppearanceSection(
          themeMode: YhThemeMode.system,
          onOpenDetails: () => opened = true,
        ),
      ),
    );

    expect(find.text('当前：跟随系统'), findsOneWidget);
    expect(find.byType(YhSegmented<YhThemeMode>), findsNothing);
    await tester.tap(find.text('打开外观设置'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('次级任务页在宽屏保持 1180dp 内容上限', (tester) async {
    const bodyKey = Key('task-page-body');
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: YhTaskPage(
          title: '外观',
          kicker: '设置',
          summary: '跟随系统、亮色和暗色即时生效。',
          source: '本机外观设置',
          sourceSymbol: '设',
          primaryActionLabel: '应用主题',
          onPrimaryAction: () {},
          body: const SizedBox(key: bodyKey),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(bodyKey)).width,
      lessThanOrEqualTo(YhTheme.light.layout.pageContentWidth),
    );
  });

  testWidgets('宽屏外观选择线按内容收束且没有冗余卡片', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      YhApp(
        home: SettingsAppearancePage(
          themeMode: YhThemeMode.system,
          onChanged: (_) {},
          onApply: () {},
        ),
      ),
    );

    final choice = find.byKey(const Key('appearance-theme-choice'));
    expect(choice, findsOneWidget);
    expect(tester.getSize(choice).width, lessThan(300));
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
    expect(find.byType(YhCard), findsNothing);
  });

  testWidgets('设置目的地本地导航栈接收根宿主的最新主题', (tester) async {
    await tester.pumpWidget(const _ThemeSettingsHost());
    expect(find.text('当前主题：system'), findsOneWidget);

    await tester.tap(find.text('切换暗色'));
    await tester.pump();

    expect(find.text('当前主题：dark'), findsOneWidget);
  });
}

class _ThemeSettingsHost extends StatefulWidget {
  const _ThemeSettingsHost();

  @override
  State<_ThemeSettingsHost> createState() => _ThemeSettingsHostState();
}

class _ThemeSettingsHostState extends State<_ThemeSettingsHost> {
  YhThemeMode _mode = YhThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return YhApp(
      themeMode: _mode,
      home: AppShell(
        initialDestinationIndex: 6,
        destinationOverrides: {
          '设置': _ThemeProbe(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
        },
        themeMode: _mode,
        onThemeModeChanged: (mode) => setState(() => _mode = mode),
      ),
    );
  }
}

class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe({required this.mode, required this.onChanged});

  final YhThemeMode mode;
  final ValueChanged<YhThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('当前主题：${mode.name}'),
        YhButton(label: '切换暗色', onTap: () => onChanged(YhThemeMode.dark)),
      ],
    );
  }
}
