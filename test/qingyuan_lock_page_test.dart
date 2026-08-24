/* 清源锁屏页面测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/lock_page.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  testWidgets('锁屏使用清源输入与行动并提示空密码', (tester) async {
    await tester.pumpWidget(YhApp(home: LockPage(onUnlocked: () {})));
    await tester.pump();

    expect(find.textContaining('应用已锁定'), findsOneWidget);
    expect(find.byType(YhTextField), findsOneWidget);
    expect(find.byType(YhButton), findsOneWidget);
    await tester.tap(find.text('解锁'));
    await tester.pump();
    expect(find.text('请输入密码'), findsOneWidget);
  });
}
