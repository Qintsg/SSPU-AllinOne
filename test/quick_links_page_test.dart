/* 清源快速跳转页面测试。 */

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/quick_links_page.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  const groups = <QuickLinkGroupConfig>[
    QuickLinkGroupConfig(
      category: '学习与教务',
      items: [
        QuickLinkItemConfig(
          name: '教务处',
          url: 'https://jwc.sspu.edu.cn/',
          icon: 'education',
        ),
        QuickLinkItemConfig(
          name: '图书馆',
          url: 'https://lib.sspu.edu.cn/',
          icon: 'library',
        ),
      ],
    ),
    QuickLinkGroupConfig(
      category: '学校信息',
      items: [
        QuickLinkItemConfig(
          name: '学校官网',
          url: 'https://www.sspu.edu.cn/',
          icon: 'globe',
        ),
      ],
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  testWidgets('清源快速跳转支持搜索、空状态和打开最佳匹配', (tester) async {
    String? openedUrl;
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => groups,
          onOpenUrl: (url) async => openedUrl = url,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(YhPageScaffold), findsOneWidget);
    expect(find.byType(YhQuickLink), findsNWidgets(3));
    await tester.enterText(find.byType(EditableText), '图书馆');
    await tester.pump();
    expect(find.byType(YhQuickLink), findsOneWidget);
    await tester.tap(find.text('打开最佳匹配'));
    await tester.pump();
    expect(openedUrl, 'https://lib.sspu.edu.cn/');

    await tester.enterText(find.byType(EditableText), '不存在的入口');
    await tester.pump();
    expect(find.text('未找到匹配的快捷入口'), findsOneWidget);
    expect(find.text('清除搜索'), findsOneWidget);
  });
}
