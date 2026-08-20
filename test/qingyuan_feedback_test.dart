/*
 * 清源全局反馈组件测试
 * @Project : SSPU-AllinOne
 * @File : qingyuan_feedback_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

/// 验证全局反馈在减少动态模式下不延迟移除。
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
}

