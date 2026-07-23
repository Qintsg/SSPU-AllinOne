/*
 * 清源基础层测试 — 校验主题契约与统一交互行为
 * @Project : SSPU-AllinOne
 * @File : qingyuan_foundations_test.dart
 * @Author : Qintsg
 * @Date : 2026-07-18
 */

import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

void main() {
  testWidgets('清源主题由纯 WidgetsApp 宿主提供并支持亮暗模式', (tester) async {
    late YhTheme actual;

    await tester.pumpWidget(
      YhApp(
        themeMode: YhThemeMode.light,
        home: Builder(
          builder: (context) {
            actual = context.yhTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(actual.color.brandStrong, const Color(0xFF478384));
    expect(actual.spacing.m, 16);
    expect(actual.typography.body.fontSize, 15);
    expect(actual.motion.fast, const Duration(milliseconds: 120));

    await tester.pumpWidget(
      YhApp(
        themeMode: YhThemeMode.dark,
        home: Builder(
          builder: (context) {
            actual = context.yhTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(actual.color.background, const Color(0xFF14171A));
  });

  testWidgets('清源宿主包装器继承已解析主题并保留动态标题', (tester) async {
    late YhTheme wrapperTheme;

    await tester.pumpWidget(
      YhApp(
        themeMode: YhThemeMode.dark,
        onGenerateTitle: (_) => '清源动态标题',
        builder: (context, child) {
          wrapperTheme = context.yhTheme;
          return KeyedSubtree(
            key: const Key('app-wrapper'),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SizedBox.shrink(),
      ),
    );

    expect(wrapperTheme, same(YhTheme.dark));
    expect(find.byKey(const Key('app-wrapper')), findsOneWidget);
    final widgetsApp = tester.widget<WidgetsApp>(find.byType(WidgetsApp));
    expect(
      widgetsApp.onGenerateTitle!(
        tester.element(find.byKey(const Key('app-wrapper'))),
      ),
      '清源动态标题',
    );
  });

  test('清源亮暗主题覆盖完整基础契约', () {
    expect(YhTheme.light.color.background, const Color(0xFFF7F6F5));
    expect(YhTheme.dark.color.background, const Color(0xFF14171A));
    expect(YhTheme.light.color.serviceAcademic, const Color(0xFF3D7EA6));
    expect(YhTheme.dark.color.danger, const Color(0xFFE5564B));
    expect(YhTheme.light.spacing.xl2, 48);
    expect(YhTheme.light.radius.input, 12);
    expect(YhTheme.light.typography.display.fontSize, 36);
    expect(YhTheme.light.typography.hero.fontSize, 48);
    expect(YhTheme.light.responsive.panelPaddingViewportPercent, 4);
    expect(YhTheme.light.responsive.heroViewportPercent, 5);
    expect(YhTheme.light.motion.slow, const Duration(milliseconds: 320));
    expect(YhTheme.light.motion.pressedScale, 0.98);
    expect(
      YhTheme.light.motion.effective(
        YhTheme.light.motion.slow,
        disableAnimations: true,
      ),
      Duration.zero,
    );
    expect(YhTheme.light.breakpoint.medium, 768);
    expect(YhTheme.light.control.minimumTarget, 48);
    expect(YhTheme.light.focus.ringWidth, 2);
    expect(YhTheme.dark.elevation.e3.single.blurRadius, 28);
    expect(YhIcons.home, isNotNull);
  });

  testWidgets('清源统一交互支持键盘激活与禁用语义', (tester) async {
    var activations = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      YhApp(
        home: Column(
          children: [
            YhPressable(
              semanticLabel: '可执行操作',
              onPressed: () => activations += 1,
              child: const Text('执行'),
            ),
            const YhPressable(
              semanticLabel: '禁用操作',
              onPressed: null,
              child: Text('禁用'),
            ),
          ],
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final pressableBox = tester.getSize(
      find.descendant(
        of: find.byType(YhPressable).first,
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(pressableBox.width, greaterThanOrEqualTo(48));
    expect(pressableBox.height, greaterThanOrEqualTo(48));
    final focusedDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(YhPressable).first,
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .foregroundDecoration
            as BoxDecoration;
    expect(focusedDecoration.border?.top.width, 2);
    expect(focusedDecoration.border?.top.color, const Color(0xFF478384));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);

    final disabledSemantics = tester.getSemantics(find.text('禁用'));
    expect(disabledSemantics.flagsCollection.isButton, isTrue);
    expect(disabledSemantics.flagsCollection.isEnabled, Tristate.isFalse);
    semantics.dispose();
  });

  testWidgets('清源按钮通过点击和键盘触发并暴露禁用语义', (tester) async {
    var activations = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      YhApp(
        home: Column(
          children: [
            YhButton(label: '保存更改', onTap: () => activations += 1),
            const YhButton(label: '不可用', disabled: true),
          ],
        ),
      ),
    );

    await tester.tap(find.text('保存更改'));
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 2);
    expect(tester.getSize(find.byType(YhButton).first).height, 48);
    final primarySurface = find
        .descendant(
          of: find.byType(YhButton).first,
          matching: find.byKey(const ValueKey('yh-button-surface')),
        )
        .first;
    expect(tester.getSize(primarySurface).height, 48);

    final disabled = tester.getSemantics(find.text('不可用'));
    expect(disabled.flagsCollection.isButton, isTrue);
    expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    semantics.dispose();
  });

  testWidgets('清源路由与确认对话框返回明确结果', (tester) async {
    bool? result;

    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开确认',
            onTap: () async {
              result = await YhDialog.confirm(
                context,
                title: '删除该课程？',
                message: '此操作不可撤销。',
                confirmText: '删除',
                danger: true,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开确认'));
    await tester.pumpAndSettle();
    expect(find.text('删除该课程？'), findsOneWidget);
    expect(find.text('此操作不可撤销。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('高风险确认可显式允许点击遮罩取消', (tester) async {
    bool? result;
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '清除数据',
            onTap: () async {
              result = await YhDialog.confirm(
                context,
                title: '确认清除',
                message: '将清除本地数据。',
                danger: true,
                barrierDismissible: true,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('清除数据'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text('确认清除'), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('清源工具提示在鼠标悬停后通过 Overlay 展示', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: Center(
          child: YhTooltip(message: '重新检测校园网', child: Text('网络状态')),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('网络状态')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('重新检测校园网'), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(find.text('重新检测校园网'), findsNothing);
    await mouse.removePointer();
  });
}
