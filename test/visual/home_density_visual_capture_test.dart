/*
 * 清源首页可配置概览密度 Flutter 视觉采集
 * @Project : SSPU-AllinOne
 * @File : home_density_visual_capture_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import '../support/qingyuan_visual_fixtures.dart';

const _captureEnabled = bool.fromEnvironment('QINGYUAN_HOME_DENSITY_CAPTURE');
const _viewports = <Size>[Size(360, 800), Size(1200, 900)];
const _fontAssets = <String>[
  'assets/fonts/MiSans-Regular.ttf',
  'assets/fonts/MiSans-Medium.ttf',
  'assets/fonts/MiSans-Semibold.ttf',
  'assets/fonts/MiSans-Bold.ttf',
];
const _quickLinks = <QuickLinkItemConfig>[
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
const _overviewKeys = <String>[
  StorageKeys.homeStudentProfileCardVisible,
  StorageKeys.homeCampusCardBalanceCardVisible,
  StorageKeys.homeEmailTileVisible,
  StorageKeys.homeSportsAttendanceTileVisible,
];
const _scenarios = <String, Set<String>>{
  'all': {
    StorageKeys.homeStudentProfileCardVisible,
    StorageKeys.homeCampusCardBalanceCardVisible,
    StorageKeys.homeEmailTileVisible,
    StorageKeys.homeSportsAttendanceTileVisible,
  },
  'single': {StorageKeys.homeCampusCardBalanceCardVisible},
  'none': <String>{},
};

/// 加载与主视觉矩阵相同的清源字体和图标字形。
///
/// :returns: 字体加载完成时结束。
Future<void> _loadVisualFonts() async {
  final loader = FontLoader(YhTypographyTokens.fontFamilyBody);
  for (final asset in _fontAssets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
  final regularIcons =
      FontLoader(
        'packages/fluentui_system_icons/FluentSystemIcons-Regular',
      )..addFont(
        rootBundle.load(
          'packages/fluentui_system_icons/fonts/FluentSystemIcons-Regular.ttf',
        ),
      );
  final filledIcons =
      FontLoader('packages/fluentui_system_icons/FluentSystemIcons-Filled')
        ..addFont(
          rootBundle.load(
            'packages/fluentui_system_icons/fonts/FluentSystemIcons-Filled.ttf',
          ),
        );
  await Future.wait([regularIcons.load(), filledIcons.load()]);
}

/// 构建视觉采集使用的校园网探测器。
///
/// :returns: 不访问网络的确定性校园网服务。
CampusNetworkStatusService _networkService() {
  return CampusNetworkStatusService(
    probe: (uri, timeout) async => const CampusNetworkProbeResult(
      reachable: true,
      statusCode: 200,
      detail: '校园网可用',
    ),
  );
}

/// 构建指定主题和尺寸的首页 fixture。
///
/// :param viewport: 目标视口。
/// :param mode: 清源主题模式。
/// :returns: 带统一脱敏数据的应用壳。
Widget _homeAt(Size viewport, YhThemeMode mode) {
  return YhApp(
    themeMode: mode,
    home: MediaQuery(
      data: MediaQueryData(
        size: viewport,
        devicePixelRatio: 1,
        disableAnimations: true,
        platformBrightness: mode == YhThemeMode.light
            ? Brightness.light
            : Brightness.dark,
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
            quickLinkFavoritesOverride: _quickLinks,
          ),
        },
      ),
    ),
  );
}

/// 写入一次 Flutter RepaintBoundary 截图并校验物理尺寸。
///
/// :param tester: 当前 widget 测试器。
/// :param boundaryKey: 截图边界键。
/// :param target: 输出文件。
/// :param viewport: 目标视口。
/// :returns: 无。
Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  File target,
  Size viewport,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final result = await tester
      .runAsync<({int width, int height, List<int> bytes})>(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) throw StateError('首页密度截图编码失败');
          return (
            width: image.width,
            height: image.height,
            bytes: data.buffer.asUint8List(),
          );
        } finally {
          image.dispose();
        }
      });
  if (result == null) throw StateError('首页密度截图未返回');
  expect(result.width, viewport.width.toInt());
  expect(result.height, viewport.height.toInt());
  target.parent.createSync(recursive: true);
  target.writeAsBytesSync(result.bytes, flush: true);
}

/// 注册稿外首页密度的多视口、多主题视觉采集。
///
/// :returns: 无返回值。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_captureEnabled) setUpAll(_loadVisualFonts);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });
  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
    SharedPreferences.setMockInitialValues({});
  });

  for (final entry in _scenarios.entries) {
    for (final viewport in _viewports) {
      for (final mode in [YhThemeMode.light, YhThemeMode.dark]) {
        testWidgets('采集首页密度 ${entry.key} ${mode.name} '
            '${viewport.width.toInt()}x${viewport.height.toInt()}', (
          tester,
        ) async {
          for (final key in _overviewKeys) {
            await StorageService.setBool(key, entry.value.contains(key));
          }
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport;
          await tester.binding.setSurfaceSize(viewport);
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(key: boundaryKey, child: _homeAt(viewport, mode)),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            find.byKey(const Key('home-today-courses-tile')),
            findsOneWidget,
          );
          if (entry.value.isEmpty) {
            expect(find.byKey(const Key('home-overview-stack')), findsNothing);
          } else {
            expect(
              find.byKey(const Key('home-overview-stack')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          final target = File(
            'build/visual/home-density/${entry.key}--${mode.name}--'
            '${viewport.width.toInt()}x${viewport.height.toInt()}.png',
          );
          await _capture(tester, boundaryKey, target, viewport);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          await tester.binding.setSurfaceSize(null);
        }, skip: !_captureEnabled);
      }
    }
  }
}
