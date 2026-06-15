/*
 * 首页测试 — 校验校园卡余额卡片展示、手动刷新和详情入口
 * @Project : SSPU-AllinOne
 * @File : home_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

/// 等待目标组件出现，避免页面异步加载尚未完成时提前断言。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 首页存在入场动画和 Fluent 点击态短计时器，测试结束前统一清理。
Future<void> disposeHomePage(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> pumpHomePage(
  WidgetTester tester, {
  CampusCardBalanceClient? campusCardService,
  AcademicEamsClient? academicEamsService,
  required CampusNetworkStatusService campusNetworkStatusService,
  required bool campusCardAutoRefreshEnabledOverride,
  int campusCardAutoRefreshIntervalOverride = 30,
  bool? campusCardVisible,
}) async {
  if (campusCardVisible != null) {
    await StorageService.setBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      campusCardVisible,
    );
  }
  await tester.pumpWidget(
    FluentApp(
      home: HomePage(
        campusCardService: campusCardService,
        academicEamsService: academicEamsService,
        campusNetworkStatusService: campusNetworkStatusService,
        campusCardAutoRefreshEnabledOverride:
            campusCardAutoRefreshEnabledOverride,
        campusCardAutoRefreshIntervalOverride:
            campusCardAutoRefreshIntervalOverride,
      ),
    ),
  );
}

const _homeDashboardTileKeys = [
  Key('home-student-profile-card'),
  Key('home-campus-card-balance-card'),
  Key('home-today-courses-tile'),
  Key('home-sports-attendance-tile'),
  Key('home-second-classroom-tile'),
  Key('home-messages-tile'),
  Key('home-email-tile'),
  Key('home-quick-links-tile'),
];

Map<Key, double> _dashboardTileColumnXByKey(WidgetTester tester) {
  final xs = <Key, double>{};
  for (final key in _homeDashboardTileKeys) {
    xs[key] = tester.getTopLeft(find.byKey(key)).dx.roundToDouble();
  }
  return xs;
}

void _expectDashboardTilesExist() {
  for (final key in _homeDashboardTileKeys) {
    expect(find.byKey(key), findsOneWidget);
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
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页校园卡卡片可手动刷新并进入详情页', (tester) async {
    final service = _FakeCampusCardClient(result: _successResult);
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );

    expect(find.text('校园卡余额'), findsOneWidget);
    expect(find.textContaining('自动刷新未开启'), findsOneWidget);

    await tester.tap(find.byIcon(FluentIcons.refresh));
    await pumpUntilFound(tester, find.text('¥23.45'));

    expect(find.text('刷新成功√'), findsOneWidget);
    expect(service.fetchCount, 1);
    expect(service.requireCampusNetworkValues, [false]);
    expect(service.queryTransactionsValues, [false]);
    expect(service.syncAllTransactionsValues, [true]);
    expect(find.text('账户余额'), findsNothing);
    expect(find.text('卡状态：冻结'), findsOneWidget);
    expect(find.textContaining('2026-04-29'), findsNothing);
    expect(find.textContaining('需要校园网或学校 VPN'), findsNothing);
    expect(find.text('上次刷新时间：2026-04-30 10:20'), findsOneWidget);
    final detailButton = find.byWidgetPredicate((widget) {
      return widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.label == '交易记录查询';
    });
    expect(detailButton, findsOneWidget);
    expect(
      find.descendant(
        of: detailButton,
        matching: find.byIcon(FluentIcons.chevronRight),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新成功√'), findsNothing);

    await tester.tap(find.text('交易记录查询'));
    await tester.pumpAndSettle();

    expect(find.text('校园卡详情'), findsOneWidget);
    expect(find.text('余额：¥23.45'), findsOneWidget);
    expect(find.text('交易记录'), findsOneWidget);
    expect(service.fetchCount, 1);
    await disposeHomePage(tester);
  });

  testWidgets('首页校园卡手动刷新失败时显示预置短原因', (tester) async {
    final service = _FakeCampusCardClient(result: _missingAccountResult);
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );

    final refreshButton = find.byKey(const Key('home-campus-card-refresh'));
    await tester.ensureVisible(refreshButton);
    await tester.tap(refreshButton);
    await pumpUntilFound(tester, find.text('刷新失败:未设置OA账号×'));

    expect(find.text('需要先填写 OA 账号'), findsOneWidget);
    expect(service.fetchCount, 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新失败:未设置OA账号×'), findsNothing);
    await disposeHomePage(tester);
  });

  testWidgets('首页校园卡未填写教务凭据时窄屏错误提示不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeCampusCardClient(result: _missingAccountResult);
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );

    final refreshButton = find.byKey(const Key('home-campus-card-refresh'));
    await tester.ensureVisible(refreshButton);
    await tester.tap(refreshButton);
    await pumpUntilFound(tester, find.text('刷新失败:未设置OA账号×'));

    final card = find.byKey(const Key('home-campus-card-balance-card'));
    final cardRect = tester.getRect(card);
    for (final text in [
      '需要先填写 OA 账号',
      '前往设置页保存学工号后，再刷新校园卡余额。',
      '刷新失败:未设置OA账号×',
    ]) {
      final textRect = tester.getRect(
        find.descendant(of: card, matching: find.text(text)),
      );
      expect(textRect.left, greaterThanOrEqualTo(cardRect.left));
      expect(textRect.right, lessThanOrEqualTo(cardRect.right));
      expect(textRect.top, greaterThanOrEqualTo(cardRect.top));
      expect(textRect.bottom, lessThanOrEqualTo(cardRect.bottom));
    }
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页学籍信息卡片展示身份摘要且无刷新时间', (tester) async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final academicService = _FakeAcademicEamsClient(
      cachedProfile: _studentProfile,
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();

    await pumpHomePage(
      tester,
      academicEamsService: academicService,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(tester, find.text('学籍信息'));

    final profileCard = find.byKey(const Key('home-student-profile-card'));
    expect(profileCard, findsOneWidget);
    expect(
      find.descendant(of: profileCard, matching: find.text('本专科教务')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profileCard, matching: find.text('张三')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profileCard, matching: find.text('20260001')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profileCard, matching: find.text('计算机与信息工程学院')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profileCard, matching: find.text('软件工程')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profileCard, matching: find.text('软件 241')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profileCard, matching: find.textContaining('来自学籍信息')),
      findsNothing,
    );
    expect(
      find.descendant(of: profileCard, matching: find.textContaining('上次刷新')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: profileCard,
        matching: find.byIcon(FluentIcons.refresh),
      ),
      findsNothing,
    );
    expect(academicService.refreshCount, 0);
    await disposeHomePage(tester);
  });

  testWidgets('首页仪表盘宽屏使用三列瀑布流磁贴', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();

    await pumpHomePage(
      tester,
      campusCardService: _FakeCampusCardClient(
        result: _successResult,
        cachedResult: _freshCachedResult,
      ),
      academicEamsService: _FakeAcademicEamsClient(
        cachedProfile: _studentProfile,
      ),
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-campus-card-balance-card')),
    );

    _expectDashboardTilesExist();
    final columnXs = _dashboardTileColumnXByKey(tester);
    expect(columnXs.values.toSet(), hasLength(3));
    expect(
      columnXs[const Key('home-student-profile-card')],
      columnXs[const Key('home-sports-attendance-tile')],
    );
    expect(
      columnXs[const Key('home-sports-attendance-tile')],
      columnXs[const Key('home-email-tile')],
    );
    expect(
      columnXs[const Key('home-campus-card-balance-card')],
      columnXs[const Key('home-second-classroom-tile')],
    );
    expect(
      columnXs[const Key('home-second-classroom-tile')],
      columnXs[const Key('home-quick-links-tile')],
    );
    expect(
      columnXs[const Key('home-today-courses-tile')],
      columnXs[const Key('home-messages-tile')],
    );
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页仪表盘中屏使用两列瀑布流磁贴', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();

    await pumpHomePage(
      tester,
      campusCardService: _FakeCampusCardClient(
        result: _successResult,
        cachedResult: _freshCachedResult,
      ),
      academicEamsService: _FakeAcademicEamsClient(
        cachedProfile: _studentProfile,
      ),
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-campus-card-balance-card')),
    );

    _expectDashboardTilesExist();
    final columnXs = _dashboardTileColumnXByKey(tester);
    expect(columnXs.values.toSet(), hasLength(2));
    expect(
      columnXs[const Key('home-student-profile-card')],
      columnXs[const Key('home-today-courses-tile')],
    );
    expect(
      columnXs[const Key('home-today-courses-tile')],
      columnXs[const Key('home-second-classroom-tile')],
    );
    expect(
      columnXs[const Key('home-second-classroom-tile')],
      columnXs[const Key('home-email-tile')],
    );
    expect(
      columnXs[const Key('home-campus-card-balance-card')],
      columnXs[const Key('home-sports-attendance-tile')],
    );
    expect(
      columnXs[const Key('home-sports-attendance-tile')],
      columnXs[const Key('home-messages-tile')],
    );
    expect(
      columnXs[const Key('home-messages-tile')],
      columnXs[const Key('home-quick-links-tile')],
    );
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页仪表盘窄屏使用单列瀑布流磁贴', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();

    await pumpHomePage(
      tester,
      campusCardService: _FakeCampusCardClient(
        result: _successResult,
        cachedResult: _freshCachedResult,
      ),
      academicEamsService: _FakeAcademicEamsClient(
        cachedProfile: _studentProfile,
      ),
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-campus-card-balance-card')),
    );

    _expectDashboardTilesExist();
    final columnXs = _dashboardTileColumnXByKey(tester);
    expect(columnXs.values.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页校园卡刷新控件保持在上次刷新文案右侧', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();

    await pumpHomePage(
      tester,
      campusCardService: _FakeCampusCardClient(
        result: _successResult,
        cachedResult: _freshCachedResult,
      ),
      academicEamsService: _FakeAcademicEamsClient(
        cachedProfile: _studentProfile,
      ),
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-campus-card-balance-card')),
    );

    final refreshCenter = tester.getCenter(
      find.byKey(const Key('home-campus-card-refresh')),
    );
    final lastRefresh = find.textContaining('上次刷新时间：').first;
    final lastRefreshCenter = tester.getCenter(lastRefresh);
    final lastRefreshRight = tester.getTopRight(lastRefresh).dx;
    final refreshLeft = tester
        .getTopLeft(find.byKey(const Key('home-campus-card-refresh')))
        .dx;

    expect((refreshCenter.dy - lastRefreshCenter.dy).abs(), lessThan(1));
    expect(refreshLeft - lastRefreshRight, greaterThanOrEqualTo(0));
    expect(refreshLeft - lastRefreshRight, lessThan(16));
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页无 OA 账密时学籍卡片显示设置引导', (tester) async {
    var settingsOpened = false;
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await tester.pumpWidget(
      FluentApp(
        home: HomePage(
          academicEamsService: _FakeAcademicEamsClient(),
          campusNetworkStatusService: campusNetworkStatusService,
          campusCardAutoRefreshEnabledOverride: false,
          onOpenSettings: () => settingsOpened = true,
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('需要先保存 OA 账号密码'));

    final profileCard = find.byKey(const Key('home-student-profile-card'));
    expect(
      find.descendant(of: profileCard, matching: find.text('学籍信息会在保存后自动读取')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: profileCard, matching: find.text('前往设置')),
    );
    await tester.pump();
    expect(settingsOpened, isTrue);
    await disposeHomePage(tester);
  });

  testWidgets('首页学籍卡片隐藏设置关闭后不展示', (tester) async {
    await StorageService.setBool(
      StorageKeys.homeStudentProfileCardVisible,
      false,
    );
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        cachedProfile: _studentProfile,
      ),
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('学籍信息'), findsNothing);
    expect(find.text('校园卡余额'), findsOneWidget);
    await disposeHomePage(tester);
  });

  testWidgets('首页校园卡卡片隐藏设置关闭后不展示且学籍卡占满', (tester) async {
    await AcademicCredentialsService.instance.saveCredentials(
      oaAccount: '20260001',
      oaPassword: 'oa-pass',
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      academicEamsService: _FakeAcademicEamsClient(
        cachedProfile: _studentProfile,
      ),
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
      campusCardVisible: false,
    );
    await pumpUntilFound(tester, find.text('学籍信息'));

    expect(find.text('学籍信息'), findsOneWidget);
    expect(find.text('校园卡余额'), findsNothing);
    await disposeHomePage(tester);
  });

  testWidgets('校园卡自动刷新开启时会主动读取余额', (tester) async {
    final service = _FakeCampusCardClient(result: _successResult);
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('¥23.45'));

    expect(service.fetchCount, 1);
    expect(service.requireCampusNetworkValues, [true]);
    await disposeHomePage(tester);
  });

  testWidgets('首页进入时优先显示未过期校园卡缓存且不主动刷新', (tester) async {
    final service = _FakeCampusCardClient(
      result: _successResult,
      cachedResult: _freshCachedResult,
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('¥88.88'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.descendant(
        of: find.byKey(const Key('home-campus-card-balance-card')),
        matching: find.text('¥88.88'),
      ),
      findsOneWidget,
    );
    expect(service.fetchCount, 0);
    await disposeHomePage(tester);
  });

  testWidgets('校园卡详情页分页和日期校验不会清空旧记录', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final service = _FakeCampusCardClient(result: _manyRecordsResult);
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );

    await tester.tap(find.byIcon(FluentIcons.refresh));
    await pumpUntilFound(tester, find.text('¥120.00'));
    await tester.tap(find.text('交易记录查询'));
    await tester.pumpAndSettle();

    expect(service.fetchCount, 1);
    expect(find.textContaining('第 1 / 2 页 · 共 21 条'), findsOneWidget);
    expect(find.text('交易 01'), findsOneWidget);
    expect(find.text('交易 21'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('campus-card-next-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campus-card-next-page')));
    await tester.pumpAndSettle();

    expect(find.textContaining('第 2 / 2 页 · 共 21 条'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('交易 21'), findsOneWidget);

    await tester.ensureVisible(find.text('开始日期'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(FluentTextField).first, 'bad-date');
    await tester.tap(find.text('筛选'));
    await tester.pump();

    expect(find.text('日期格式应为 yyyy-MM-dd。'), findsOneWidget);
    expect(service.fetchCount, 1);
    // After bad-date filter, _filteredRecords returns empty, so "交易 21" is hidden.
    // The page-2 assertion above already verified pagination.
    await disposeHomePage(tester);
  });

  testWidgets('首页静默自动刷新失败时保留已有校园卡缓存', (tester) async {
    final service = _FakeCampusCardClient(
      result: _missingAccountResult,
      cachedResult: _staleCachedResult,
    );
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: true,
    );

    await pumpUntilFound(tester, find.text('¥66.66'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(service.fetchCount, 1);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-campus-card-balance-card')),
        matching: find.text('¥66.66'),
      ),
      findsOneWidget,
    );
    expect(find.text('请先保存学工号'), findsNothing);
    await disposeHomePage(tester);
  });

  testWidgets('首页停留期间按自动刷新间隔静默更新校园卡', (tester) async {
    final service = _FakeCampusCardClient(result: _successResult);
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusCardService: service,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: true,
      campusCardAutoRefreshIntervalOverride: 1,
    );

    await pumpUntilFound(tester, find.text('¥23.45'));
    expect(service.fetchCount, 1);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(service.fetchCount, 2);
    await disposeHomePage(tester);
  });

  testWidgets('首页右上角显示小型网络状态指示', (tester) async {
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await pumpHomePage(
      tester,
      campusNetworkStatusService: campusNetworkStatusService,
      campusCardAutoRefreshEnabledOverride: false,
    );

    await pumpUntilFound(
      tester,
      find.byKey(const Key('campus-network-status-home')),
    );

    expect(find.byKey(const Key('campus-network-status-home')), findsOneWidget);
    expect(find.text('VPN'), findsOneWidget);
    await disposeHomePage(tester);
  });
}

CampusNetworkStatusService _buildCampusNetworkStatusService() {
  return CampusNetworkStatusService(
    probe: (uri, timeout) async {
      return CampusNetworkProbeResult(
        reachable: true,
        statusCode: 200,
        detail: '已访问 ${uri.host}，HTTP 200',
      );
    },
  );
}

class _FakeCampusCardClient implements CampusCardBalanceClient {
  _FakeCampusCardClient({required this.result, this.cachedResult});

  final CampusCardQueryResult result;
  final CampusCardQueryResult? cachedResult;
  int fetchCount = 0;
  final List<bool> requireCampusNetworkValues = [];

  @override
  Future<CampusCardQueryResult?> readLatestCachedCampusCard() async {
    return cachedResult;
  }

  @override
  Future<CampusCardQueryResult> fetchCampusCard({
    DateTime? startDate,
    DateTime? endDate,
    bool requireCampusNetwork = true,
    bool queryTransactions = false,
    bool syncAllTransactions = false,
  }) async {
    fetchCount++;
    requireCampusNetworkValues.add(requireCampusNetwork);
    startDateValues.add(startDate);
    endDateValues.add(endDate);
    queryTransactionsValues.add(queryTransactions);
    syncAllTransactionsValues.add(syncAllTransactions);
    return result;
  }

  final List<DateTime?> startDateValues = [];
  final List<DateTime?> endDateValues = [];
  final List<bool> queryTransactionsValues = [];
  final List<bool> syncAllTransactionsValues = [];
}

class _FakeAcademicEamsClient implements AcademicEamsClient {
  _FakeAcademicEamsClient({this.cachedProfile});

  final AcademicEamsProfile? cachedProfile;
  int refreshCount = 0;

  @override
  Future<AcademicEamsProfile?> readCachedStudentProfile() async {
    return cachedProfile;
  }

  @override
  Future<AcademicEamsProfile?> refreshStudentProfileIfIncomplete({
    bool forceRefresh = false,
  }) async {
    refreshCount++;
    return cachedProfile;
  }

  @override
  Future<AcademicEamsQueryResult> fetchCourseTable({
    bool requireCampusNetwork = true,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AcademicEamsQueryResult> fetchOverview({
    bool requireCampusNetwork = true,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedCourseTable() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedOverview() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedExamSchedule() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult> fetchExamSchedule({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    String? examTypeId,
    bool requireCampusNetwork = true,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AcademicEamsQueryResult> fetchGrades({
    bool requireCampusNetwork = true,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGrades() async {
    return null;
  }

  @override
  Future<AcademicEamsQueryResult> fetchGradeProcess({
    AcademicTermChoice? term,
    AcademicEamsSemesterOption? semester,
    bool requireCampusNetwork = true,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AcademicEamsQueryResult?> readLatestCachedGradeProcess() async {
    return null;
  }
}

const AcademicEamsProfile _studentProfile = AcademicEamsProfile(
  name: '张三',
  studentId: '20260001',
  department: '计算机与信息工程学院',
  major: '软件工程',
  className: '软件 241',
  gender: '男',
  studyLength: '4 年',
  educationLevel: '本科',
  rawFields: {},
);

final CampusCardQueryResult _successResult = CampusCardQueryResult(
  status: CampusCardQueryStatus.success,
  message: '校园卡查询成功',
  detail: '已读取校园卡余额、卡状态和交易记录。',
  checkedAt: DateTime(2026, 4, 30, 10, 20),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn//interface/Entrance.jsp?id=xykxt',
  ),
  finalUri: Uri.parse('https://card.sspu.edu.cn/epay/'),
  snapshot: CampusCardSnapshot(
    balance: 23.45,
    status: '冻结',
    fetchedAt: DateTime(2026, 4, 30, 10, 20),
    sourceUri: Uri.parse('https://card.sspu.edu.cn/epay/'),
    records: const [
      CampusCardTransactionRecord(
        occurredAt: '2026-04-29 12:10',
        amount: -12.5,
        merchant: '一食堂',
        type: '消费',
        balanceAfter: 23.45,
        rawCells: ['2026-04-29 12:10', '消费', '一食堂', '-12.50', '23.45'],
      ),
    ],
  ),
);

final CampusCardQueryResult _manyRecordsResult = CampusCardQueryResult(
  status: CampusCardQueryStatus.success,
  message: '校园卡查询成功',
  detail: '已读取校园卡余额、卡状态和交易记录。',
  checkedAt: DateTime(2026, 6, 9, 12, 47),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn//interface/Entrance.jsp?id=xykxt',
  ),
  finalUri: Uri.parse('https://card.sspu.edu.cn/epay/consume/query'),
  snapshot: CampusCardSnapshot(
    balance: 120,
    status: '正常',
    fetchedAt: DateTime(2026, 6, 9, 12, 47),
    sourceUri: Uri.parse('https://card.sspu.edu.cn/epay/consume/query'),
    records: List.unmodifiable(
      List.generate(21, (index) {
        final number = index + 1;
        return CampusCardTransactionRecord(
          occurredAt: '2026-06-${number.toString().padLeft(2, '0')} 12:00',
          amount: -number.toDouble(),
          title: '交易 ${number.toString().padLeft(2, '0')}',
          counterparty: '窗口 $number',
          paymentMethod: '校园卡',
          status: '成功',
          rawCells: [
            '2026-06-${number.toString().padLeft(2, '0')} 12:00',
            '交易 ${number.toString().padLeft(2, '0')}',
            '窗口 $number',
            number.toStringAsFixed(2),
            '校园卡',
            '成功',
          ],
        );
      }),
    ),
  ),
);

final CampusCardQueryResult _freshCachedResult = _buildCachedResult(
  balance: 88.88,
  status: '正常',
  checkedAt: DateTime.now(),
);

final CampusCardQueryResult _staleCachedResult = _buildCachedResult(
  balance: 66.66,
  status: '正常',
  checkedAt: DateTime.now().subtract(const Duration(hours: 2)),
);

final CampusCardQueryResult _missingAccountResult = CampusCardQueryResult(
  status: CampusCardQueryStatus.missingOaAccount,
  message: '请先保存学工号',
  detail: '本地安全存储中没有 OA 账号。',
  checkedAt: DateTime(2026, 4, 30, 10, 30),
  entranceUri: Uri.parse(
    'https://oa.sspu.edu.cn//interface/Entrance.jsp?id=xykxt',
  ),
);

CampusCardQueryResult _buildCachedResult({
  required double balance,
  required String status,
  required DateTime checkedAt,
}) {
  return CampusCardQueryResult(
    status: CampusCardQueryStatus.success,
    message: '已显示本地校园卡缓存',
    detail: '显示最近一次成功读取并保存的校园卡余额、状态和交易记录。',
    checkedAt: checkedAt,
    entranceUri: Uri.parse(
      'https://oa.sspu.edu.cn//interface/Entrance.jsp?id=xykxt',
    ),
    finalUri: Uri.parse('https://card.sspu.edu.cn/epay/'),
    snapshot: CampusCardSnapshot(
      balance: balance,
      status: status,
      fetchedAt: checkedAt,
      sourceUri: Uri.parse('https://card.sspu.edu.cn/epay/'),
      records: const [],
    ),
  );
}
