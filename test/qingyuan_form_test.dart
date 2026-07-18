/* 清源输入与持续反馈测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

void main() {
  testWidgets('文本框保持标签可见并提交输入内容', (tester) async {
    final controller = TextEditingController();
    String? submitted;

    await tester.pumpWidget(
      YhApp(
        home: YhTextField(
          label: '密码',
          hint: '输入密码以解锁',
          controller: controller,
          obscure: true,
          prefixIcon: YhIcons.lock,
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );

    expect(find.text('密码'), findsOneWidget);
    expect(find.text('输入密码以解锁'), findsOneWidget);
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(controller.text, 'secret');
    expect(submitted, 'secret');
  });

  testWidgets('错误横幅与输入错误都通过语义暴露', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const YhApp(
        home: Column(
          children: [
            YhTextField(label: '学号', errorText: '学号不能为空'),
            YhBanner(text: '密码错误，请重试', kind: YhBannerKind.danger),
          ],
        ),
      ),
    );

    expect(find.text('学号不能为空'), findsOneWidget);
    expect(find.text('密码错误，请重试'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('密码错误，请重试')).flagsCollection.isLiveRegion,
      isTrue,
    );
    semantics.dispose();
  });
}
