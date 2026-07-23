/* 清源快速跳转页面测试。 */

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/quick_links_page.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
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
    FlutterSecureStorage.setMockInitialValues({});
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
    expect(find.text('常用校园入口'), findsOneWidget);
    expect(find.textContaining('名称使用学生熟悉的任务语言'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('quick-links-group-学习与教务')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quick-links-group-学校信息')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(EditableText), '图书馆');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('quick-links-group-学习与教务')),
        matching: find.text('图书馆'),
      ),
      findsOneWidget,
    );
    expect(find.text('教务处'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(openedUrl, isNull);
    expect(find.text('确认打开外部网站'), findsOneWidget);
    expect(find.text('lib.sspu.edu.cn'), findsOneWidget);
    await tester.tap(find.text('打开外部网站'));
    await tester.pumpAndSettle();
    expect(openedUrl, 'https://lib.sspu.edu.cn/');

    await tester.enterText(find.byType(EditableText), '不存在的入口');
    await tester.pump();
    expect(find.text('未找到匹配的快捷入口'), findsOneWidget);
    expect(find.text('清除搜索'), findsOneWidget);
  });

  testWidgets('清源快速跳转在配置为空时显示明确空状态', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => const [],
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无快捷入口'), findsOneWidget);
    expect(find.text('当前配置没有可用的校园服务入口。'), findsOneWidget);
  });

  testWidgets('需要 OA 认证的外部入口在缺少会话时阻止跳转', (tester) async {
    String? openedUrl;
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '202412345',
      oaPassword: 'saved-but-not-logged-in',
    );
    expect(
      await AcademicCredentialsService.instance.readOaLoginSession(),
      isNull,
    );
    const oaGroups = <QuickLinkGroupConfig>[
      QuickLinkGroupConfig(
        category: '学习与教务',
        items: [
          QuickLinkItemConfig(
            name: '本专科教务系统（OA）',
            url: 'https://oa.sspu.edu.cn/interface/Entrance.jsp?id=bzkjw',
            icon: 'education',
          ),
        ],
      ),
    ];
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => oaGroups,
          onOpenUrl: (url) async => openedUrl = url,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('本专科教务系统（OA），外部链接，将打开外部应用'));
    await tester.pumpAndSettle();

    expect(find.text('确认打开外部网站'), findsOneWidget);
    expect(find.text('oa.sspu.edu.cn'), findsOneWidget);
    expect(find.textContaining('为避免无意义重定向'), findsOneWidget);
    expect(find.text('打开外部网站'), findsNothing);
    expect(openedUrl, isNull);
    await tester.tap(find.text('返回快捷入口'));
    await tester.pumpAndSettle();
    expect(find.text('常用校园入口'), findsOneWidget);
  });

  testWidgets('清源快速跳转加载失败后可重试进入目录', (tester) async {
    var loadCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async {
            loadCount += 1;
            if (loadCount == 1) throw StateError('fixture failed');
            return groups;
          },
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('无法加载快捷入口'), findsOneWidget);
    expect(
      find.textContaining('assets/config/quick_links.yaml'),
      findsOneWidget,
    );
    expect(find.text('重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('常用校园入口'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('quick-links-group-学习与教务')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quick-links-group-学校信息')),
      findsOneWidget,
    );
  });

  testWidgets('清源任务目录保留独立收藏交互', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => groups,
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('收藏教务处'));
    await tester.pumpAndSettle();

    expect(
      await StorageService.getStringList(StorageKeys.quickLinkFavoriteUrls),
      contains('https://jwc.sspu.edu.cn/'),
    );
    expect(find.bySemanticsLabel('取消收藏教务处'), findsOneWidget);
    expect(find.bySemanticsLabel('教务处，外部链接，将打开外部应用'), findsOneWidget);
  });

  testWidgets('清源快速跳转在紧凑宽度使用单列任务目录', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => groups,
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstGroup = find.byKey(const ValueKey('quick-links-group-学习与教务'));
    final secondGroup = find.byKey(const ValueKey('quick-links-group-学校信息'));
    expect(
      tester.getTopLeft(secondGroup).dy,
      greaterThan(tester.getBottomLeft(firstGroup).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('清源快速跳转紧凑页首与首个内容区遵循参考锚点', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => groups,
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final kicker = find.text('快速跳转');
    final description = find.textContaining('名称使用学生熟悉的任务语言');
    final search = find.byKey(const Key('quick-links-search-field'));
    final theme = tester.element(kicker).yhTheme;
    final safeTop = MediaQuery.paddingOf(tester.element(kicker)).top;

    expect(
      tester.getTopLeft(kicker).dy,
      safeTop + theme.spacing.l + theme.spacing.s + theme.layout.divider * 3,
    );
    expect(
      tester.getTopLeft(search).dy - tester.getBottomLeft(description).dy,
      theme.spacing.l + theme.spacing.xs,
    );
    expect(
      tester.widget<Text>(description).style?.fontSize,
      theme.typography.small.fontSize,
    );

    final firstRow = find.bySemanticsLabel('教务处，外部链接，将打开外部应用');
    final secondRow = find.bySemanticsLabel('图书馆，外部链接，将打开外部应用');
    expect(
      tester.getTopLeft(secondRow).dy - tester.getBottomLeft(firstRow).dy,
      theme.spacing.s,
    );
    expect(find.text('↗'), findsNWidgets(3));
  });

  testWidgets('清源快速跳转在 expanded 视口使用三列任务目录', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final expandedGroups = <QuickLinkGroupConfig>[
      ...groups,
      const QuickLinkGroupConfig(
        category: '校园服务',
        items: [
          QuickLinkItemConfig(
            name: '校园卡服务',
            url: 'https://card.example.invalid/',
            icon: 'finance',
          ),
        ],
      ),
    ];
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => expandedGroups,
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('quick-links-group-学习与教务'));
    final second = find.byKey(const ValueKey('quick-links-group-学校信息'));
    final third = find.byKey(const ValueKey('quick-links-group-校园服务'));
    expect(tester.getTopLeft(second).dy, tester.getTopLeft(first).dy);
    expect(tester.getTopLeft(third).dy, tester.getTopLeft(first).dy);
    expect(tester.getTopLeft(first).dx, lessThan(tester.getTopLeft(second).dx));
    expect(tester.getTopLeft(second).dx, lessThan(tester.getTopLeft(third).dx));
  });

  testWidgets('清源快速跳转状态卡总高度遵循 popover 契约', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () async => const [],
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byType(YhCard);
    final theme = tester.element(card).yhTheme;
    expect(
      tester.getSize(card).height,
      closeTo(theme.layout.popoverWidth + theme.spacing.xl, 0.1),
    );
  });

  testWidgets('清源快速跳转加载态使用紧凑环形活动指示器', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final pending = Completer<List<QuickLinkGroupConfig>>();
    await tester.pumpWidget(
      YhApp(
        home: QuickLinksPage(
          groupsLoader: () => pending.future,
          onOpenUrl: (_) async {},
        ),
      ),
    );
    await tester.pump();

    final ring = find.byType(YhRing);
    final theme = tester.element(ring).yhTheme;
    expect(ring, findsOneWidget);
    expect(find.byType(YhProgress), findsNothing);
    expect(tester.getSize(ring), Size.square(theme.control.compact));
  });
}
