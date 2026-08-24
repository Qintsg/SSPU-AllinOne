/*
 * 清源全局反馈组件测试
 * @Project : SSPU-AllinOne
 * @File : qingyuan_feedback_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

/// 注册全局反馈定位与生命周期测试。
///
/// :returns: 无返回值。
void main() {
  testWidgets('全局反馈在减少动态模式下按时直接移除', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            disableAnimations: true,
          ),
          child: YhPageScaffold(
            body: Builder(
              builder: (context) => YhButton(
                label: '显示反馈',
                onTap: () => showYhFeedback(context, message: '设置已保存'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示反馈'));
    await tester.pump();
    expect(find.byKey(const Key('app-feedback-toast')), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byKey(const Key('app-feedback-toast')), findsNothing);
  });

  testWidgets('全局反馈完整避开页面顶部行动', (tester) async {
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
          data: const MediaQueryData(size: viewport),
          child: YhPageScaffold(
            body: Stack(
              children: [
                PositionedDirectional(
                  top: 40,
                  end: 48,
                  child: Builder(
                    builder: (context) => YhButton(
                      key: const Key('page-header-action'),
                      label: '刷新教务数据',
                      onTap: () => showYhFeedback(context, message: '部分来源刷新失败'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('page-header-action')));
    await tester.pump();

    final actionRect = tester.getRect(
      find.byKey(const Key('page-header-action')),
    );
    final feedbackRect = tester.getRect(
      find.byKey(const Key('app-feedback-toast')),
    );
    expect(feedbackRect.top, greaterThanOrEqualTo(actionRect.bottom));
    expect(find.bySemanticsLabel('关闭反馈'), findsNothing);
  });
}
