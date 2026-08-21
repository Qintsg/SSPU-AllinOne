/*
 * 清源任务型模态框响应式与错误恢复测试
 * @Project : SSPU-AllinOne
 * @File : modal_task_dialogs_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/widgets/password_dialogs.dart';
import 'package:sspu_allinone/widgets/settings_wechat_config_dialog.dart';

/// 验证任务型模态框的安全边距、焦点和原位错误恢复。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  testWidgets('密码模态在 360 视口保留安全边距并保留错误输入', (tester) async {
    await _setCompactViewport(tester);
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开密码模态',
            onTap: () => showSetPasswordDialog(context),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开密码模态'));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const Key('yh-dialog-surface'));
    _expectSafeInset(tester, dialog);

    final fields = find.byType(EditableText);
    expect(
      tester.widget<EditableText>(fields.first).focusNode.hasFocus,
      isTrue,
    );
    await tester.enterText(fields.at(0), 'qingyuan-demo');
    await tester.enterText(fields.at(1), 'qingyuan');
    await tester.tap(find.text('设置密码'));
    await tester.pumpAndSettle();

    expect(find.text('两次输入的密码不一致'), findsOneWidget);
    expect(
      tester.widget<EditableText>(fields.at(0)).controller.text,
      'qingyuan-demo',
    );
    expect(
      tester.widget<EditableText>(fields.at(1)).controller.text,
      'qingyuan',
    );
    _expectSafeInset(tester, dialog);
  });

  testWidgets('微信配置数值错误完整露出且不清空其他字段', (tester) async {
    await _setCompactViewport(tester);
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开配置模态',
            onTap: () => showSettingsWechatConfigDialog(
              context: context,
              initialConfig: WxmpConfig.defaults(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开配置模态'));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const Key('yh-dialog-surface'));
    _expectSafeInset(tester, dialog);

    final fields = find.byType(EditableText);
    final fieldControls = find.byType(YhTextField);
    final originalUserAgent = tester
        .widget<EditableText>(fields.at(3))
        .controller
        .text;
    final originalRequestDelay = tester
        .widget<EditableText>(fields.at(5))
        .controller
        .text;
    final requestCountRect = tester.getRect(fieldControls.at(4));
    final requestDelayRect = tester.getRect(fieldControls.at(5));
    expect(requestCountRect.top, requestDelayRect.top);
    expect(requestCountRect.right, lessThanOrEqualTo(requestDelayRect.left));
    expect(requestCountRect.height, greaterThanOrEqualTo(48));
    expect(requestDelayRect.height, greaterThanOrEqualTo(48));
    await tester.enterText(fields.at(4), '0');
    await tester.tap(find.text('保存配置'));
    await tester.pumpAndSettle();

    final error = find.text('范围为 1-20');
    expect(error, findsOneWidget);
    expect(
      tester.widget<EditableText>(fields.at(3)).controller.text,
      originalUserAgent,
    );
    expect(tester.widget<EditableText>(fields.at(4)).controller.text, '0');
    expect(
      tester.widget<EditableText>(fields.at(5)).controller.text,
      originalRequestDelay,
    );
    expect(
      tester.getBottomLeft(error).dy,
      lessThan(tester.getTopLeft(find.text('取消')).dy),
    );
    _expectSafeInset(tester, dialog);
  });
}

/// 将测试视口固定为清源 compact 验收尺寸。
///
/// :param tester: 当前 Widget 测试器。
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
/// :param finder: YhDialog 查找器。
void _expectSafeInset(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(16));
  expect(rect.top, greaterThanOrEqualTo(16));
  expect(rect.right, lessThanOrEqualTo(344));
  expect(rect.bottom, lessThanOrEqualTo(784));
}
