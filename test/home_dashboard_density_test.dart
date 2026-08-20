/*
 * 清源首页 v04 密度与行动坞回归测试
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_density_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import 'support/qingyuan_visual_fixtures.dart';

const _favorites = <QuickLinkItemConfig>[
  QuickLinkItemConfig(
    name: '统一身份认证',
    url: 'https://oa.example.invalid/',
    icon: 'security',
  ),
  QuickLinkItemConfig(
    name: '图书馆',
    url: 'https://library.example.invalid/',
    icon: 'library',
  ),
  QuickLinkItemConfig(
    name: '学校官网',
    url: 'https://www.example.invalid/',
    icon: 'globe',
  ),
];

CampusNetworkStatusService _networkService() {
  return CampusNetworkStatusService(
    probe: (uri, timeout) async => const CampusNetworkProbeResult(
      reachable: true,
      statusCode: 200,
      detail: '校园网可用',
    ),
  );
}

Widget _homeAt(Size size) {
  return YhApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: 1,
        disableAnimations: true,
      ),
      child: AppShell(
        destinationOverrides: {
          '主页': HomePage(
            campusNetworkStatusService: _networkService(),
            campusCardAutoRefreshEnabledOverride: false,
            campusCardResultOverride: qingyuanCampusCardContentResult,
            nowOverride: qingyuanVisualNow,
            messagesOverride: qingyuanHomeMessages,
            homeUpdatedAtOverride: qingyuanAcademicEvidenceTime,
            homeCountdownMinutesOverride: 42,
            homeCourseTimeOverrides: const {'数据结构': '10:00'},
            dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
            courseTableResultOverride: qingyuanHomeAcademicResult,
            academicOverviewResultOverride: qingyuanHomeAcademicResult,
            sportsAttendanceResultOverride: qingyuanHomeSportsResult,
            emailResultOverride: qingyuanHomeEmailResult,
            studentReportResultOverride: qingyuanHomeStudentReportResult,
            quickLinkFavoritesOverride: _favorites,
          ),
        },
      ),
    ),
  );
}

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_homeAt(size));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _setVisibleOverviewItems(Set<String> visible) async {
  final keys = <String>[
    StorageKeys.homeStudentProfileCardVisible,
    StorageKeys.homeCampusCardBalanceCardVisible,
    StorageKeys.homeEmailTileVisible,
    StorageKeys.homeSportsAttendanceTileVisible,
  ];
  for (final key in keys) {
    await StorageService.setBool(key, visible.contains(key));
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  testWidgets('1600x1000 主区按内容封顶且行动坞紧随主区', (tester) async {
    await _pumpHome(tester, const Size(1600, 1000));

    final timeline = tester.getRect(
      find.byKey(const Key('home-today-courses-tile')),
    );
    final dock = tester.getRect(find.byKey(const Key('home-utility-dock')));
    final theme = tester
        .element(find.byKey(const Key('home-today-courses-tile')))
        .yhTheme;

    expect(timeline.height, lessThanOrEqualTo(420));
    expect(dock.top - timeline.bottom, theme.spacing.m);
    expect(dock.height, lessThanOrEqualTo(88));
    expect(tester.takeException(), isNull);
  });

  testWidgets('行动坞只保留一层卡片且快捷入口没有常驻按钮框', (tester) async {
    await _pumpHome(tester, const Size(1200, 900));

    final dock = find.byKey(const Key('home-utility-dock'));
    expect(tester.widget(dock), isA<YhCard>());
    expect(
      find.descendant(of: dock, matching: find.byType(YhCard)),
      findsNothing,
    );
    expect(
      find.descendant(of: dock, matching: find.byType(YhQuickLink)),
      findsNothing,
    );
    expect(
      find.descendant(of: dock, matching: find.byType(YhIconButton)),
      findsNothing,
    );
    for (var index = 0; index < _favorites.length; index++) {
      final action = find.byKey(Key('home-quick-link-action-$index'));
      expect(action, findsOneWidget);
      expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('360x800 行动坞单层呈现且第二课堂不换行', (tester) async {
    await _pumpHome(tester, const Size(360, 800));

    expect(
      find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    final title = find.descendant(
      of: find.byKey(const Key('home-second-classroom-tile')),
      matching: find.text('第二课堂'),
    );
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).maxLines, 1);
    final dock = tester.getRect(find.byKey(const Key('home-utility-dock')));
    final bottomNavigation = tester.getRect(find.byType(YhBottomNav));
    expect(dock.bottom, lessThanOrEqualTo(bottomNavigation.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面端关闭全部服务摘要时移除空概览框并释放主区宽度', (tester) async {
    await _setVisibleOverviewItems(const <String>{});
    await _pumpHome(tester, const Size(1200, 900));

    expect(find.byKey(const Key('home-overview-stack')), findsNothing);
    final timeline = tester.getRect(
      find.byKey(const Key('home-today-courses-tile')),
    );
    expect(timeline.width, greaterThan(780));
    expect(tester.takeException(), isNull);
  });

  testWidgets('仅保留一个服务摘要时按内容收束而不拉伸空卡片', (tester) async {
    await _setVisibleOverviewItems(const <String>{
      StorageKeys.homeCampusCardBalanceCardVisible,
    });
    await _pumpHome(tester, const Size(1200, 900));

    final overview = tester.getRect(
      find.byKey(const Key('home-overview-stack')),
    );
    final timeline = tester.getRect(
      find.byKey(const Key('home-today-courses-tile')),
    );
    expect(overview.height, lessThan(timeline.height));
    expect(overview.height, greaterThanOrEqualTo(64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('紧凑端按实际摘要行数收束且不引入页面滚动', (tester) async {
    await _setVisibleOverviewItems(const <String>{
      StorageKeys.homeCampusCardBalanceCardVisible,
    });
    await _pumpHome(tester, const Size(360, 800));

    expect(
      find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    final overview = tester.getRect(
      find.byKey(const Key('home-overview-stack')),
    );
    expect(overview.height, lessThanOrEqualTo(72));
    expect(tester.takeException(), isNull);
  });
}
