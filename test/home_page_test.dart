/*
 * 首页测试 — 校验校园卡余额卡片展示、手动刷新和详情入口
 * @Project : SSPU-AllinOne
 * @File : home_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-04-30
 */

import 'dart:async';

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/campus_card.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/models/message_item.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/services/academic_credentials_service.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/email_service.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';

/// 等待目标组件出现，避免页面异步加载尚未完成时提前断言。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// 首页存在入场动画和清源点击态短计时器，测试结束前统一清理。
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
  DateTime? nowOverride,
  HomeDashboardDisplayState dashboardDisplayStateOverride =
      HomeDashboardDisplayState.content,
}) async {
  if (campusCardVisible != null) {
    await StorageService.setBool(
      StorageKeys.homeCampusCardBalanceCardVisible,
      campusCardVisible,
    );
  }
  await tester.pumpWidget(
    YhApp(
      home: HomePage(
        campusCardService: campusCardService,
        academicEamsService: academicEamsService,
        campusNetworkStatusService: campusNetworkStatusService,
        campusCardAutoRefreshEnabledOverride:
            campusCardAutoRefreshEnabledOverride,
        campusCardAutoRefreshIntervalOverride:
            campusCardAutoRefreshIntervalOverride,
        nowOverride: nowOverride,
        dashboardDisplayStateOverride: dashboardDisplayStateOverride,
      ),
    ),
  );
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

  testWidgets('桌面导航壳中的首页内容起点与冻结稿一致', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 900),
            devicePixelRatio: 1,
            disableAnimations: true,
          ),
          child: AppShell(
            destinationOverrides: {
              '主页': HomePage(
                campusNetworkStatusService: _buildCampusNetworkStatusService(),
                campusCardAutoRefreshEnabledOverride: false,
                nowOverride: DateTime(2026, 7, 18, 9, 18),
                dashboardDisplayStateOverride:
                    HomeDashboardDisplayState.content,
              ),
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(const Key('home-page-heading'))),
      const Offset(268, 32),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-today-courses-tile'))).width,
      closeTo(584.6, 0.2),
    );
    expect(
      tester.getSize(find.byKey(const Key('home-overview-stack'))).width,
      closeTo(283.4, 0.2),
    );

    await disposeHomePage(tester);
  });

  testWidgets('首页加载状态保留标题并明确正在汇总本地数据', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
          dashboardDisplayStateOverride: HomeDashboardDisplayState.loading,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('早上好，先看清今天。'), findsOneWidget);
    expect(find.text('正在整理今天'), findsOneWidget);
    expect(find.byKey(const Key('home-today-courses-tile')), findsNothing);

    await disposeHomePage(tester);
  });

  testWidgets('首页初始状态说明只读取本机缓存并提供明确操作', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
          dashboardDisplayStateOverride: HomeDashboardDisplayState.initial,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('尚未整理今天'), findsOneWidget);
    expect(find.text('读取首页数据'), findsOneWidget);
    expect(find.byKey(const Key('home-today-courses-tile')), findsNothing);

    await disposeHomePage(tester);
  });

  testWidgets('首页缓存陈旧时保留时间轨并提示缓存时间', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
          homeUpdatedAtOverride: DateTime(2026, 7, 18, 8, 42),
          dashboardDisplayStateOverride: HomeDashboardDisplayState.stale,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('home-dashboard-stale-banner')),
      findsOneWidget,
    );
    expect(find.textContaining('08:42'), findsWidgets);
    expect(find.byKey(const Key('home-today-courses-tile')), findsOneWidget);

    await disposeHomePage(tester);
  });

  testWidgets('首页缓存读取失败时说明保留旧缓存并提供重试', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.error,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('无法更新首页数据'), findsOneWidget);
    expect(find.textContaining('已有本地缓存不会被删除'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.byKey(const Key('home-today-courses-tile')), findsNothing);

    await disposeHomePage(tester);
  });

  testWidgets('首页辅助坞保留第二课堂和常用入口既有展示行为', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
          studentReportResultOverride: _studentReportResult,
          quickLinkFavoritesOverride: const [
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
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('home-utility-dock')), findsOneWidget);
    expect(find.text('已获 8.5 / 必修 10 学分'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('从今天直接出发'), findsOneWidget);
    for (final label in ['统一身份认证', '图书馆', '学校官网']) {
      expect(find.text(label), findsOneWidget);
      expect(find.bySemanticsLabel('$label，外部链接，将打开外部应用'), findsOneWidget);
      expect(
        tester.getSize(find.text(label).hitTestable()).height,
        greaterThan(0),
      );
    }

    await disposeHomePage(tester);
  });

  testWidgets('桌面壳内常用入口标题与操作保持并排', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      YhApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 900),
            devicePixelRatio: 1,
            disableAnimations: true,
          ),
          child: AppShell(
            destinationOverrides: {
              '主页': HomePage(
                campusNetworkStatusService: _buildCampusNetworkStatusService(),
                campusCardAutoRefreshEnabledOverride: false,
                dashboardDisplayStateOverride:
                    HomeDashboardDisplayState.content,
                studentReportResultOverride: _studentReportResult,
                quickLinkFavoritesOverride: const [
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
                ],
              ),
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final headingY = tester.getTopLeft(find.text('常用入口')).dy;
    final actionY = tester.getTopLeft(find.text('统一身份认证')).dy;
    expect((headingY - actionY).abs(), lessThan(YhTheme.light.spacing.xl2));

    await disposeHomePage(tester);
  });

  testWidgets('首页常用入口先展示外部网页确认边界再允许打开', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
          quickLinkFavoritesOverride: const [
            QuickLinkItemConfig(
              name: '学校官网',
              url: 'https://www.example.invalid/news',
              icon: 'globe',
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('学校官网'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('学校官网'));
    await tester.pumpAndSettle();

    expect(find.text('确认打开外部网站'), findsOneWidget);
    expect(find.text('www.example.invalid'), findsOneWidget);
    expect(find.text('打开外部网站'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await disposeHomePage(tester);
  });

  testWidgets('首页第二课堂未配置 OA 凭据时保留设置引导', (tester) async {
    var settingsOpened = false;
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          studentReportService: const _NullStudentReportClient(),
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
          quickLinkFavoritesOverride: const [],
          onOpenSettings: () => settingsOpened = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('需要先保存 OA 账号密码'), findsOneWidget);
    final card = find.byKey(const Key('home-second-classroom-tile'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pump();
    expect(settingsOpened, isTrue);

    await disposeHomePage(tester);
  });

  testWidgets('首页第二课堂缓存失败时展示明确失败语义', (tester) async {
    var settingsOpened = false;
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
          studentReportResultOverride: _studentReportErrorResult,
          quickLinkFavoritesOverride: const [],
          onOpenSettings: () => settingsOpened = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('第二课堂暂不可用'), findsOneWidget);
    expect(find.text('请检查校园网络后重试。'), findsOneWidget);
    expect(find.text('未更新'), findsOneWidget);
    final card = find.byKey(const Key('home-second-classroom-tile'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pump();
    expect(settingsOpened, isTrue);

    await disposeHomePage(tester);
  });

  testWidgets('首页辅助坞遵循第二课堂和常用入口显隐设置', (tester) async {
    await StorageService.setBool(
      StorageKeys.homeStudentReportTileVisible,
      false,
    );
    await StorageService.setBool(StorageKeys.homeQuickLinksTileVisible, false);
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
          studentReportResultOverride: _studentReportResult,
          quickLinkFavoritesOverride: const [
            QuickLinkItemConfig(
              name: '学校官网',
              url: 'https://www.example.invalid/',
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home-utility-dock')), findsNothing);
    expect(find.text('第二课堂'), findsNothing);
    expect(find.text('从今天直接出发'), findsNothing);

    await disposeHomePage(tester);
  });

  testWidgets('首页根据本地缓存读取生命周期从加载转为初始状态', (tester) async {
    final courseTableCache = Completer<AcademicEamsQueryResult?>();
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          academicEamsService: _FakeAcademicEamsClient(
            courseTableCacheFuture: courseTableCache.future,
          ),
          campusCardService: _FakeCampusCardClient(result: _successResult),
          sportsAttendanceService: const _NullSportsAttendanceClient(),
          studentReportService: const _NullStudentReportClient(),
          emailService: const _NullEmailClient(),
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          messagesOverride: const [],
          quickLinkFavoritesOverride: const [],
        ),
      ),
    );

    expect(find.text('正在整理今天'), findsOneWidget);
    courseTableCache.complete();
    await pumpUntilFound(tester, find.text('尚未整理今天'));

    expect(find.text('尚未整理今天'), findsOneWidget);
    expect(find.byKey(const Key('home-today-courses-tile')), findsNothing);

    await disposeHomePage(tester);
  });

  testWidgets('首页本地缓存读取异常且没有旧数据时进入错误状态', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          academicEamsService: _FakeAcademicEamsClient(
            courseTableCacheError: StateError('cache unavailable'),
          ),
          campusCardService: _FakeCampusCardClient(result: _successResult),
          sportsAttendanceService: const _NullSportsAttendanceClient(),
          studentReportService: const _NullStudentReportClient(),
          emailService: const _NullEmailClient(),
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          messagesOverride: const [],
          quickLinkFavoritesOverride: const [],
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('无法更新首页数据'));

    expect(find.text('无法更新首页数据'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await disposeHomePage(tester);
  });

  testWidgets('首页局部缓存读取失败时保留已有内容并降级为陈旧状态', (tester) async {
    final cachedCard = _buildCachedResult(
      balance: 88.88,
      status: '正常',
      checkedAt: DateTime(2026, 7, 18, 8, 42),
    );
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          academicEamsService: _FakeAcademicEamsClient(
            courseTableCacheError: StateError('cache unavailable'),
          ),
          sportsAttendanceService: const _NullSportsAttendanceClient(),
          studentReportService: const _NullStudentReportClient(),
          emailService: const _NullEmailClient(),
          campusCardResultOverride: cachedCard,
          campusCardAutoRefreshEnabledOverride: false,
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          nowOverride: DateTime(2026, 7, 18, 9, 30),
          messagesOverride: const [],
          quickLinkFavoritesOverride: const [],
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-dashboard-stale-banner')),
    );

    expect(
      find.byKey(const Key('home-dashboard-stale-banner')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-today-courses-tile')), findsOneWidget);
    expect(find.text('¥88.88'), findsOneWidget);

    await disposeHomePage(tester);
  });

  testWidgets('首页任一业务缓存过期时不会被较新的其它缓存掩盖', (tester) async {
    final staleCard = _buildCachedResult(
      balance: 88.88,
      status: '正常',
      checkedAt: DateTime(2026, 7, 18, 7, 30),
    );
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          campusCardResultOverride: staleCard,
          studentReportResultOverride: _studentReportResult,
          quickLinkFavoritesOverride: const [],
          messagesOverride: const [],
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-dashboard-stale-banner')),
    );

    expect(
      find.byKey(const Key('home-dashboard-stale-banner')),
      findsOneWidget,
    );
    expect(find.text('85%'), findsOneWidget);

    await disposeHomePage(tester);
  });

  testWidgets('首页不会把消息发布时间误当成缓存刷新时间', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          academicEamsService: _FakeAcademicEamsClient(),
          sportsAttendanceService: const _NullSportsAttendanceClient(),
          emailService: const _NullEmailClient(),
          messagesOverride: [
            MessageItem(
              id: 'old-publication',
              title: '历史通知仍在本地缓存',
              date: '2020-01-01',
              url: 'https://news.example.invalid/old-publication',
              sourceType: MessageSourceType.schoolWebsite,
              sourceName: MessageSourceName.jwc,
              category: MessageCategory.jwcStudent,
              timestamp: DateTime(2020, 1, 1, 16).millisecondsSinceEpoch,
            ),
          ],
          campusCardResultOverride: _buildCachedResult(
            balance: 88.88,
            status: '正常',
            checkedAt: DateTime(2026, 7, 18, 9),
          ),
          studentReportResultOverride: _studentReportResult,
          quickLinkFavoritesOverride: const [],
          campusNetworkStatusService: _buildCampusNetworkStatusService(),
          campusCardAutoRefreshEnabledOverride: false,
          nowOverride: DateTime(2026, 7, 18, 9, 30),
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('home-today-courses-tile')),
    );

    expect(find.byKey(const Key('home-today-courses-tile')), findsOneWidget);
    expect(find.byKey(const Key('home-dashboard-stale-banner')), findsNothing);

    await disposeHomePage(tester);
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

    expect(
      find.descendant(
        of: find.byKey(const Key('home-campus-card-balance-card')),
        matching: find.text('校园卡'),
      ),
      findsOneWidget,
    );
    expect(find.text('尚未读取余额'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-campus-card-refresh')));
    await pumpUntilFound(tester, find.text('¥23.45'));

    expect(find.text('刷新成功√'), findsOneWidget);
    expect(service.fetchCount, 1);
    expect(service.requireCampusNetworkValues, [false]);
    expect(service.queryTransactionsValues, [false]);
    expect(service.syncAllTransactionsValues, [true]);
    expect(find.text('账户余额'), findsNothing);
    expect(find.textContaining('2026-04-29'), findsNothing);
    expect(find.textContaining('需要校园网或学校 VPN'), findsNothing);
    expect(find.text('校园卡 · 本地缓存'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('刷新成功√'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('home-campus-card-balance-card')),
    );
    await tester.tap(find.byKey(const Key('home-campus-card-balance-card')));
    await tester.pumpAndSettle();

    expect(find.text('校园卡详情'), findsOneWidget);
    expect(find.text('¥23.45'), findsOneWidget);
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

    expect(find.text('校园卡暂不可用'), findsOneWidget);
    expect(find.text('请检查 OA 登录与校园网络'), findsOneWidget);
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
    for (final text in ['校园卡暂不可用', '请检查 OA 登录与校园网络', '重试']) {
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

  testWidgets('首页标题使用固定日期并保持培养方案独立于学籍摘要', (tester) async {
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
      nowOverride: DateTime(2026, 7, 18, 9, 30),
    );
    await pumpUntilFound(tester, find.text('早上好，先看清今天。'));

    expect(find.text('7 月 18 日 · 星期六'), findsOneWidget);
    expect(find.text('培养方案'), findsOneWidget);
    expect(find.text('张三'), findsNothing);
    expect(find.text('20260001'), findsNothing);
    expect(academicService.refreshCount, 0);
    await disposeHomePage(tester);
  });

  testWidgets('首页宽屏使用时间轨与服务概览双栏', (tester) async {
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

    final timeline = tester.getRect(
      find.byKey(const Key('home-today-courses-tile')),
    );
    final overview = tester.getRect(
      find.byKey(const Key('home-overview-stack')),
    );
    expect(timeline.top, overview.top);
    expect(timeline.left, lessThan(overview.left));
    expect(timeline.width, greaterThan(overview.width));
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页中屏将服务概览堆叠到时间轨下方', (tester) async {
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

    final timeline = tester.getRect(
      find.byKey(const Key('home-today-courses-tile')),
    );
    final overview = tester.getRect(
      find.byKey(const Key('home-overview-stack')),
    );
    expect(timeline.left, overview.left);
    expect(timeline.bottom, lessThan(overview.top));
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页窄屏保持时间轨和概览单列且不溢出', (tester) async {
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

    final timeline = tester.getRect(
      find.byKey(const Key('home-today-courses-tile')),
    );
    final overview = tester.getRect(
      find.byKey(const Key('home-overview-stack')),
    );
    expect(timeline.left, overview.left);
    expect(timeline.bottom, lessThan(overview.top));
    expect(timeline.left, greaterThanOrEqualTo(0));
    expect(timeline.right, lessThanOrEqualTo(420));
    expect(timeline.height, lessThan(510));
    expect(
      tester.getTopLeft(find.byKey(const Key('home-campus-card-refresh'))).dy,
      24,
    );
    expect(find.byKey(const Key('home-customize')), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页校园卡刷新控件位于应用栏且保持 48dp 触控目标', (tester) async {
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

    final refreshRect = tester.getRect(
      find.byKey(const Key('home-campus-card-refresh')),
    );
    final cardRect = tester.getRect(
      find.byKey(const Key('home-campus-card-balance-card')),
    );

    expect(refreshRect.width, greaterThanOrEqualTo(48));
    expect(refreshRect.height, greaterThanOrEqualTo(48));
    expect(refreshRect.bottom, lessThan(cardRect.top));
    expect(tester.takeException(), isNull);
    await disposeHomePage(tester);
  });

  testWidgets('首页自定义入口在无 OA 账密时仍可打开设置', (tester) async {
    var settingsOpened = false;
    final campusNetworkStatusService = _buildCampusNetworkStatusService();
    await tester.pumpWidget(
      YhApp(
        home: HomePage(
          academicEamsService: _FakeAcademicEamsClient(),
          campusNetworkStatusService: campusNetworkStatusService,
          campusCardAutoRefreshEnabledOverride: false,
          dashboardDisplayStateOverride: HomeDashboardDisplayState.content,
          onOpenSettings: () => settingsOpened = true,
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('自定义首页'));

    expect(find.text('培养进度尚未读取'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-customize')));
    await tester.pump();
    expect(settingsOpened, isTrue);
    await disposeHomePage(tester);
  });

  testWidgets('首页培养方案概览隐藏设置关闭后不展示', (tester) async {
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

    expect(find.text('培养方案'), findsNothing);
    expect(
      find.byKey(const Key('home-campus-card-balance-card')),
      findsOneWidget,
    );
    await disposeHomePage(tester);
  });

  testWidgets('首页校园卡隐藏后保留培养方案与全局刷新', (tester) async {
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
    await pumpUntilFound(tester, find.text('培养方案'));

    expect(find.text('培养方案'), findsOneWidget);
    expect(
      find.byKey(const Key('home-campus-card-balance-card')),
      findsNothing,
    );
    expect(find.byKey(const Key('home-campus-card-refresh')), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('home-campus-card-refresh')));
    await pumpUntilFound(tester, find.text('¥120.00'));
    await tester.tap(find.byKey(const Key('home-campus-card-balance-card')));
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
    await tester.enterText(
      find.byKey(const Key('campus-card-start-date')),
      'bad-date',
    );
    await tester.tap(find.text('筛选'));
    await tester.pump();

    expect(find.text('日期格式应为 yyyy-MM-dd；已保留上一次有效筛选结果。'), findsOneWidget);
    expect(service.fetchCount, 1);
    expect(find.textContaining('第 2 / 2 页 · 共 21 条'), findsOneWidget);
    expect(find.text('交易 21'), findsOneWidget);
    await disposeHomePage(tester);
  });

  testWidgets('校园卡详情近七天使用固定时钟并切换为空状态', (tester) async {
    final snapshot = _manyRecordsResult.snapshot!;
    await tester.pumpWidget(
      YhApp(
        home: CampusCardDetailPage(
          initialSnapshot: snapshot,
          campusCardService: _FakeCampusCardClient(result: _manyRecordsResult),
          nowOverride: DateTime(2026, 6, 9, 9, 30),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('campus-card-recent-seven-days')));
    await tester.pump();

    final startField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('campus-card-start-date')),
        matching: find.byType(EditableText),
      ),
    );
    final endField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('campus-card-end-date')),
        matching: find.byType(EditableText),
      ),
    );
    expect(startField.controller.text, '2026-06-03');
    expect(endField.controller.text, '2026-06-09');
    expect(find.text('交易 03'), findsOneWidget);
    expect(find.text('交易 10'), findsNothing);

    await tester.tap(find.text('收入'));
    await tester.pump();

    expect(find.text('当前范围没有交易记录'), findsOneWidget);
    expect(find.text('清除筛选'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('校园卡详情交易卡在窄屏单列且宽屏三列', (tester) async {
    Future<void> pumpAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        YhApp(
          home: CampusCardDetailPage(
            initialSnapshot: _manyRecordsResult.snapshot!,
            campusCardService: _FakeCampusCardClient(
              result: _manyRecordsResult,
            ),
            nowOverride: DateTime(2026, 6, 9, 9, 30),
          ),
        ),
      );
      await tester.pump();
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAt(const Size(390, 900));
    final compactFirst = tester.getTopLeft(
      find.byKey(const Key('campus-card-transaction-0')),
    );
    final compactSecond = tester.getTopLeft(
      find.byKey(const Key('campus-card-transaction-1')),
    );
    expect(compactFirst.dx, compactSecond.dx);
    expect(compactSecond.dy, greaterThan(compactFirst.dy));

    await pumpAt(const Size(1200, 900));
    final expandedFirst = tester.getTopLeft(
      find.byKey(const Key('campus-card-transaction-0')),
    );
    final expandedSecond = tester.getTopLeft(
      find.byKey(const Key('campus-card-transaction-1')),
    );
    final expandedThird = tester.getTopLeft(
      find.byKey(const Key('campus-card-transaction-2')),
    );
    expect(expandedFirst.dy, expandedSecond.dy);
    expect(expandedSecond.dy, expandedThird.dy);
    expect(expandedFirst.dx, lessThan(expandedSecond.dx));
    expect(expandedSecond.dx, lessThan(expandedThird.dx));
    expect(tester.takeException(), isNull);
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
    expect(find.text('VPN 可用'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('campus-network-status-home')))
          .height,
      lessThanOrEqualTo(20),
    );
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

class _NullSportsAttendanceClient implements SportsAttendanceClient {
  const _NullSportsAttendanceClient();

  @override
  Future<SportsAttendanceQueryResult?>
  readLatestCachedAttendanceSummary() async => null;

  @override
  Future<SportsAttendanceQueryResult> fetchAttendanceSummary({
    bool requireCampusNetwork = true,
  }) {
    throw UnsupportedError('测试不会访问体育考勤服务');
  }
}

class _NullStudentReportClient implements StudentReportClient {
  const _NullStudentReportClient();

  @override
  Future<StudentReportQueryResult?>
  readLatestCachedSecondClassroomCredits() async => null;

  @override
  Future<StudentReportQueryResult> validateLoginStatus() {
    throw UnsupportedError('测试不会访问第二课堂服务');
  }

  @override
  Future<StudentReportQueryResult> fetchSecondClassroomCredits({
    bool requireCampusNetwork = true,
  }) {
    throw UnsupportedError('测试不会访问第二课堂服务');
  }
}

class _NullEmailClient implements EmailMailboxClient {
  const _NullEmailClient();

  @override
  Future<EmailMailboxQueryResult?> readLatestCachedMessages(
    EmailProtocol protocol,
  ) async => null;

  @override
  Future<EmailMailboxQueryResult> fetchMessages({
    required EmailProtocol protocol,
    int messageCount = 10,
  }) {
    throw UnsupportedError('测试不会访问邮箱服务');
  }

  @override
  Future<EmailSendResult> sendMessage(EmailComposeRequest request) {
    throw UnsupportedError('测试不会访问邮箱服务');
  }

  @override
  Future<EmailLoginValidationResult> validateLogin(EmailProtocol protocol) {
    throw UnsupportedError('测试不会访问邮箱服务');
  }
}

class _FakeAcademicEamsClient implements AcademicEamsClient {
  _FakeAcademicEamsClient({
    this.cachedProfile,
    this.courseTableCacheFuture,
    this.courseTableCacheError,
  });

  final AcademicEamsProfile? cachedProfile;
  final Future<AcademicEamsQueryResult?>? courseTableCacheFuture;
  final Object? courseTableCacheError;
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
    if (courseTableCacheError case final error?) throw error;
    return await (courseTableCacheFuture ?? Future.value());
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

final StudentReportQueryResult _studentReportResult = StudentReportQueryResult(
  status: StudentReportQueryStatus.success,
  message: '第二课堂学分查询成功',
  detail: '已读取脱敏第二课堂学分汇总。',
  checkedAt: DateTime(2026, 7, 18, 8, 42),
  entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
  summary: SecondClassroomCreditSummary(
    records: const [],
    totals: const SecondClassroomCreditTotals(
      totalEarnedCredit: 8.5,
      totalRequiredCredit: 10,
    ),
    fetchedAt: DateTime(2026, 7, 18, 8, 42),
    sourceUri: Uri.parse('https://student.example.invalid/report'),
  ),
);

final StudentReportQueryResult _studentReportErrorResult =
    StudentReportQueryResult(
      status: StudentReportQueryStatus.networkError,
      message: '第二课堂服务暂时不可用',
      detail: '请检查校园网络后重试。',
      checkedAt: DateTime(2026, 7, 18, 8, 42),
      entranceUri: Uri.parse('https://oa.example.invalid/student-report'),
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
