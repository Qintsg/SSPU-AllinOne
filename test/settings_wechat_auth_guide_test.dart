/* 微信公众平台认证指南的清源交互测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/widgets/settings_wechat_auth_guide.dart';

void main() {
  testWidgets('认证指南按需展开并可打开官网', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      YhApp(
        home: SingleChildScrollView(
          child: SettingsWechatAuthGuide(
            onOpenOfficialSite: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('适用人群'), findsNothing);
    await tester.tap(find.bySemanticsLabel('展开微信公众平台注册方式'));
    await tester.pumpAndSettle();
    expect(find.text('适用人群'), findsOneWidget);

    await tester.ensureVisible(find.text('打开微信公众平台官网'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开微信公众平台官网'));
    expect(opened, isTrue);
  });
}
