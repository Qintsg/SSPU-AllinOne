/*
 * 数据与隐私危险确认响应式与取消语义测试
 * @Project : SSPU-AllinOne
 * @File : settings_data_privacy_confirmation_dialogs_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/widgets/settings_data_privacy_confirmation_dialogs.dart';

/// 验证三种数据危险确认的范围、响应式布局与取消行为。
void main() {
  final cases = <(SettingsDataPrivacyConfirmationKind, String, String, String)>[
    (
      SettingsDataPrivacyConfirmationKind.clearCampusCache,
      '清除校园缓存？',
      '账户凭据、主题、通知、首页设置和关注列表。',
      '清除校园缓存',
    ),
    (
      SettingsDataPrivacyConfirmationKind.disconnectAccounts,
      '断开账户连接？',
      '主题、通知、首页设置、关注列表和信息中心缓存。',
      '断开连接',
    ),
    (
      SettingsDataPrivacyConfirmationKind.clearAllData,
      '清除全部本地数据？',
      '系统账户、设备生物识别信息和校园服务器上的数据。',
      '清除本地数据',
    ),
  ];

  for (final (kind, title, retainedText, actionLabel) in cases) {
    testWidgets('$title 在 360 首屏完整呈现范围且遮罩不可取消', (tester) async {
      await _setCompactViewport(tester);
      bool? result;
      await tester.pumpWidget(
        YhApp(
          home: Builder(
            builder: (context) => YhButton(
              label: '打开确认',
              onTap: () async {
                result = await showSettingsDataPrivacyConfirmation(
                  context,
                  kind: kind,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开确认'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      expect(find.text('将删除'), findsOneWidget);
      expect(find.text(retainedText), findsOneWidget);
      expect(find.text(actionLabel), findsOneWidget);
      final dialog = find.byKey(const Key('yh-dialog-surface'));
      _expectSafeInset(tester, dialog);

      final scroll = find.descendant(
        of: dialog,
        matching: find.byType(SingleChildScrollView),
      );
      expect(scroll, findsOneWidget);
      final scrollable = find.descendant(
        of: scroll,
        matching: find.byType(Scrollable),
      );
      expect(
        tester
            .state<ScrollableState>(scrollable.first)
            .position
            .maxScrollExtent,
        0,
      );

      for (final label in ['取消', actionLabel]) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byType(YhButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(result, isNull);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);
      expect(result, isFalse);
    });
  }

  testWidgets('系统返回取消危险确认，主行动只在显式点击后返回 true', (tester) async {
    await _setCompactViewport(tester);
    bool? result;
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开确认',
            onTap: () async {
              result = await showSettingsDataPrivacyConfirmation(
                context,
                kind: SettingsDataPrivacyConfirmationKind.clearAllData,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开确认'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('打开确认'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除本地数据'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('取消项获得初始焦点，Escape 取消后焦点归还触发按钮', (tester) async {
    await _setCompactViewport(tester);
    bool? result;
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开确认',
            onTap: () async {
              result = await showSettingsDataPrivacyConfirmation(
                context,
                kind: SettingsDataPrivacyConfirmationKind.clearCampusCache,
              );
            },
          ),
        ),
      ),
    );

    final trigger = _focusableButton(tester, '打开确认');
    trigger.focusNode?.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(_focusableButton(tester, '取消').focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('清除校园缓存？'), findsNothing);
    expect(result, isFalse);
    expect(trigger.focusNode?.hasFocus, isTrue);
  });
}

/// 查找指定语义按钮的键盘焦点代理。
///
/// :param tester: 当前 Widget 测试器。
/// :param label: 按钮语义标签。
/// :returns: 按钮对应的焦点代理。
FocusableActionDetector _focusableButton(WidgetTester tester, String label) {
  return tester.widget<FocusableActionDetector>(
    find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.byType(FocusableActionDetector),
    ),
  );
}

/// 将测试视口固定为清源 compact 验收尺寸。
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

/// 断言模态框没有贴边或越过 compact 视口。
///
/// :param tester: 当前 Widget 测试器。
/// :param finder: YhDialog 表面查找器。
/// :returns: 无返回值。
void _expectSafeInset(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(16));
  expect(rect.top, greaterThanOrEqualTo(16));
  expect(rect.right, lessThanOrEqualTo(344));
  expect(rect.bottom, lessThanOrEqualTo(784));
}
