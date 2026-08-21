/* 清源密码对话框测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/services/password_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/widgets/password_dialogs.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  testWidgets('设置密码对话框拒绝不一致输入并保存一致密码', (tester) async {
    bool? result;
    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '设置密码',
            onTap: () async => result = await showSetPasswordDialog(context),
          ),
        ),
      ),
    );

    await tester.tap(find.text('设置密码'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'first');
    await tester.enterText(find.byType(EditableText).at(1), 'second');
    await tester.tap(find.text('设置密码').last);
    await tester.pump();
    expect(find.text('两次输入的密码不一致'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(1), 'first');
    await tester.tap(find.text('设置密码').last);
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(await PasswordService.verifyPassword('first'), isTrue);
  });
}
