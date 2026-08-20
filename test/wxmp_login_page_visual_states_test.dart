/*
 * 微信公众号扫码登录八态响应式与操作协同测试
 * @Project : SSPU-AllinOne
 * @File : wxmp_login_page_visual_states_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/wxmp_login_page.dart';

/// 验证扫码登录所有冻结状态都通过同一生产页面结构呈现。
void main() {
  testWidgets('八态在 compact 视口保持工具栏与恢复语义', (tester) async {
    await _setCompactViewport(tester);

    for (final state in WxmpLoginPreviewState.values) {
      await tester.pumpWidget(
        YhApp(
          home: WxmpLoginPage(
            previewState: state,
            launchUrlOverride: (_) async => false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('webview-compact-toolbar')), findsOneWidget);
      expect(
        find.text(state == WxmpLoginPreviewState.content ? '登录已完成' : '公众号平台登录'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      switch (state) {
        case WxmpLoginPreviewState.loading:
          expect(find.text('正在打开微信登录页'), findsOneWidget);
        case WxmpLoginPreviewState.initial:
          expect(find.textContaining('请使用拥有公众号的微信账号扫码登录'), findsOneWidget);
        case WxmpLoginPreviewState.content:
          expect(find.textContaining('登录成功，连接信息已保存在本机'), findsOneWidget);
        case WxmpLoginPreviewState.error:
          expect(find.text('无法打开微信登录页'), findsOneWidget);
          expect(find.text('重新打开登录页'), findsOneWidget);
        case WxmpLoginPreviewState.partialError:
          expect(find.textContaining('候选认证校验失败，已恢复原连接'), findsOneWidget);
        case WxmpLoginPreviewState.operationLocked:
          expect(find.textContaining('正在保存并校验认证信息'), findsOneWidget);
        case WxmpLoginPreviewState.externalConfirmation:
          await tester.tap(find.bySemanticsLabel('在系统浏览器打开微信登录页'));
          await tester.pumpAndSettle();
          expect(find.text('在系统浏览器打开微信登录页'), findsOneWidget);
          await tester.binding.handlePopRoute();
        case WxmpLoginPreviewState.externalError:
          expect(find.textContaining('系统浏览器未能打开微信登录页'), findsOneWidget);
      }
    }
  });

  testWidgets('操作锁定时返回、刷新和外部打开均不可重复触发', (tester) async {
    await _setCompactViewport(tester);
    await tester.pumpWidget(
      const YhApp(
        home: WxmpLoginPage(
          previewState: WxmpLoginPreviewState.operationLocked,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toolbar = find.byKey(const Key('webview-compact-toolbar'));
    final buttons = find.descendant(
      of: toolbar,
      matching: find.byType(YhIconButton),
    );
    expect(tester.widget<YhIconButton>(buttons.at(0)).onTap, isNull);
    expect(tester.widget<YhIconButton>(buttons.at(1)).onTap, isNull);
    expect(tester.widget<YhIconButton>(buttons.at(2)).onTap, isNull);
  });

  testWidgets('公众号登录外部确认支持取消初焦、键盘循环、Escape 与焦点归还', (tester) async {
    await _setCompactViewport(tester);
    await tester.pumpWidget(
      const YhApp(
        home: WxmpLoginPage(
          previewState: WxmpLoginPreviewState.externalConfirmation,
        ),
      ),
    );
    await tester.pump();

    final trigger = _focusableBySemanticLabel(tester, '在系统浏览器打开微信登录页');
    trigger.focusNode?.requestFocus();
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('在系统浏览器打开微信登录页'));
    await tester.pumpAndSettle();

    final cancel = _focusableByText(tester, '取消');
    final confirm = _focusableByText(tester, '继续打开');
    expect(cancel.focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(confirm.focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(cancel.focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('在系统浏览器打开微信登录页'), findsNothing);
    expect(trigger.focusNode?.hasFocus, isTrue);
  });
}

/// 查找指定语义标签对应的可聚焦清源按钮。
///
/// :param tester: 当前 Widget 测试器。
/// :param label: 按钮语义标签。
/// :returns: 对应的焦点代理。
FocusableActionDetector _focusableBySemanticLabel(
  WidgetTester tester,
  String label,
) {
  return tester.widget<FocusableActionDetector>(
    find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.byType(FocusableActionDetector),
    ),
  );
}

/// 查找指定文本对应的可聚焦清源按钮。
///
/// :param tester: 当前 Widget 测试器。
/// :param label: 按钮文本。
/// :returns: 对应的焦点代理。
FocusableActionDetector _focusableByText(WidgetTester tester, String label) {
  return tester.widget<FocusableActionDetector>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(FocusableActionDetector),
    ),
  );
}

/// 固定清源 compact 视觉验收尺寸。
///
/// :param tester: 当前 Widget 测试器。
/// :returns: 视口完成设置时结束。
Future<void> _setCompactViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() async {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
    await tester.binding.setSurfaceSize(null);
  });
}
