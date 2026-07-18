/*
 * 清源基础层测试 — 校验主题契约与统一交互行为
 * @Project : SSPU-AllinOne
 * @File : qingyuan_foundations_test.dart
 * @Author : Qintsg
 * @Date : 2026-07-18
 */

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/theme/app_theme.dart';

void main() {
  testWidgets('清源主题可从迁移期 Fluent 宿主读取', (tester) async {
    late YhTheme actual;
    final hostTheme = AppTheme.build(Brightness.light);
    expect(hostTheme.extension<YhTheme>(), same(YhTheme.light));
    expect(
      AppTheme.build(Brightness.dark).extension<YhTheme>(),
      same(YhTheme.dark),
    );

    await tester.pumpWidget(
      FluentApp(
        theme: hostTheme,
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
  });

  test('清源亮暗主题覆盖完整基础契约', () {
    expect(YhTheme.light.color.background, const Color(0xFFF7F6F5));
    expect(YhTheme.dark.color.background, const Color(0xFF14171A));
    expect(YhTheme.light.color.serviceAcademic, const Color(0xFF3D7EA6));
    expect(YhTheme.dark.color.danger, const Color(0xFFE5564B));
    expect(YhTheme.light.spacing.xl2, 48);
    expect(YhTheme.light.radius.input, 12);
    expect(YhTheme.light.typography.display.fontSize, 36);
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
      FluentApp(
        theme: FluentThemeData(extensions: [YhTheme.light]),
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
                .decoration
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
}
