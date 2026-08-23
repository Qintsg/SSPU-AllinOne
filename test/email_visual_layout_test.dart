/*
 * 邮箱视觉布局回归测试 — 校验桌面列表与正文比例
 * @Project : SSPU-AllinOne
 * @File : email_visual_layout_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-23
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/email_page.dart';

import 'support/qingyuan_visual_fixtures.dart';

/// 注册邮箱视觉布局回归测试。
///
/// :returns: 无返回值。
void main() {
  testWidgets('1200x900 桌面邮件列表使用 320px 参考宽度', (tester) async {
    const viewport = Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(size: viewport, devicePixelRatio: 1),
          child: EmailPage(
            emailService: QingyuanVisualEmailClient(
              cachedResult: qingyuanEmailContentResult,
            ),
            emailAutoRefreshEnabledOverride: false,
            emailAutoRefreshIntervalOverride: 30,
            nowOverride: qingyuanVisualNow,
          ),
        ),
      ),
    );
    final desktopLayout = find.byKey(const Key('email-desktop-client-layout'));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (desktopLayout.evaluate().isNotEmpty) break;
    }

    final list = find.byKey(const Key('email-mailbox-list-pane'));
    final theme = tester.element(list).yhTheme;
    expect(tester.getSize(list).width, closeTo(theme.layout.popoverWidth, 0.5));
    expect(tester.takeException(), isNull);
  });
}
