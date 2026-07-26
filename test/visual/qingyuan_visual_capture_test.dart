/* 清源 Flutter 视觉候选采集 — 四档视口、亮暗主题、六类组件面板。 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/app.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/models/academic_calendar.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/academic_calendar_page.dart';
import 'package:sspu_allinone/pages/academic_calendar_pdf_page.dart';
import 'package:sspu_allinone/pages/academic_page.dart';
import 'package:sspu_allinone/pages/course_schedule_page.dart';
import 'package:sspu_allinone/pages/email_page.dart';
import 'package:sspu_allinone/pages/external_link_confirmation_page.dart';
import 'package:sspu_allinone/pages/home_page.dart';
import 'package:sspu_allinone/pages/info_page.dart';
import 'package:sspu_allinone/pages/legal_notice_page.dart';
import 'package:sspu_allinone/pages/lock_page.dart';
import 'package:sspu_allinone/pages/quick_links_page.dart';
import 'package:sspu_allinone/pages/settings_appearance_page.dart';
import 'package:sspu_allinone/pages/settings_data_privacy_page.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/services/system_auth_service.dart';
import 'package:sspu_allinone/services/app_update_service.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/widgets/app_close_confirmation_dialog.dart';
import 'package:sspu_allinone/widgets/app_more_destinations.dart';
import 'package:sspu_allinone/widgets/app_startup_status.dart';
import 'package:sspu_allinone/widgets/legal_consent_dialog.dart';
import 'package:sspu_allinone/widgets/settings_general_section.dart';
import 'package:sspu_allinone/widgets/settings_security_section.dart';
import 'package:sspu_allinone/widgets/settings_update_section.dart';
import 'package:sspu_allinone/widgets/settings_wechat_auth_status_card.dart';

import '../support/qingyuan_visual_fixtures.dart';

const _captureEnabled = bool.fromEnvironment('QINGYUAN_VISUAL_CAPTURE');
const _surfacePrefix = String.fromEnvironment('QINGYUAN_VISUAL_SURFACE_PREFIX');
const _platform = String.fromEnvironment(
  'QINGYUAN_VISUAL_PLATFORM',
  defaultValue: 'local',
);

const _viewports = <Size>[
  Size(360, 800),
  Size(768, 900),
  Size(1200, 900),
  Size(1600, 1000),
];

const _fontAssets = <String>[
  'assets/fonts/MiSans-Regular.ttf',
  'assets/fonts/MiSans-Medium.ttf',
  'assets/fonts/MiSans-Semibold.ttf',
  'assets/fonts/MiSans-Bold.ttf',
];

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
  for (final surface in _surfaces) {
    if (_surfacePrefix.isNotEmpty && !surface.id.startsWith(_surfacePrefix)) {
      continue;
    }
    for (final viewport in _viewports) {
      for (final mode in [YhThemeMode.light, YhThemeMode.dark]) {
        final themeName = mode == YhThemeMode.light ? 'light' : 'dark';
        testWidgets('采集 ${surface.id} ${surface.state} $themeName '
            '${viewport.width.toInt()}x${viewport.height.toInt()}', (
          tester,
        ) async {
          debugDefaultTargetPlatformOverride = _targetPlatform;
          try {
            final output = Directory('build/visual/$_platform')
              ..createSync(recursive: true);
            await tester.binding.setSurfaceSize(viewport);
            final themeName = mode == YhThemeMode.light ? 'light' : 'dark';
            final boundaryKey = GlobalKey();
            final page = surface.builder();
            final content = surface.destination == null
                ? page
                : AppShell(
                    initialDestinationIndex: _destinationIndex(
                      surface.destination!,
                    ),
                    destinationOverrides: {surface.destination!: page},
                  );
            await tester.pumpWidget(
              YhApp(
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
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox.expand(child: content),
                  ),
                ),
              ),
            );
            await tester.pump(YhTheme.light.motion.slow);
            await surface.prepare?.call(tester);
            await tester.pump();
            final target = File(
              '${output.path}/${surface.id}--${surface.state}--$themeName--'
              '${viewport.width.toInt()}x${viewport.height.toInt()}.png',
            );
            await _capture(tester, boundaryKey, target, viewport);
            if (surface.externalRegionId != null) {
              await _writeExternalRegionSidecar(
                tester: tester,
                target: target,
                regionId: surface.externalRegionId!,
                regionKey: surface.externalRegionKey!,
                viewport: viewport,
              );
            }
            expect(target.lengthSync(), greaterThan(0));
            await surface.cleanup?.call(tester);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        }, skip: !_captureEnabled);
      }
    }
  }
}

TargetPlatform get _targetPlatform => switch (_platform) {
  'android' => TargetPlatform.android,
  'ios' => TargetPlatform.iOS,
  'macos' => TargetPlatform.macOS,
  'linux' => TargetPlatform.linux,
  _ => TargetPlatform.windows,
};

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

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  File target,
  Size viewport,
) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final result = await tester.runAsync<_CapturedPng>(() async {
    final captured = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await captured.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Flutter 截图编码失败：${target.path}');
      }
      return _CapturedPng(
        width: captured.width,
        height: captured.height,
        bytes: bytes.buffer.asUint8List(),
      );
    } finally {
      captured.dispose();
    }
  });
  if (result == null) throw StateError('Flutter 截图任务未返回：${target.path}');
  expect(result.width, viewport.width.toInt());
  expect(result.height, viewport.height.toInt());
  target.writeAsBytesSync(result.bytes, flush: true);
}

Future<void> _writeExternalRegionSidecar({
  required WidgetTester tester,
  required File target,
  required String regionId,
  required Key regionKey,
  required Size viewport,
}) async {
  final finder = find.byKey(regionKey);
  if (finder.evaluate().isEmpty) {
    throw StateError('外部区域 $regionId 未出现在 ${target.path}');
  }
  final rect = tester.getRect(finder).intersect(Offset.zero & viewport);
  if (rect.isEmpty) {
    throw StateError('外部区域 $regionId 没有可比较像素：${target.path}');
  }
  File('${target.path}.regions.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'externalRegions': [
        {
          'id': regionId,
          'x': rect.left.round(),
          'y': rect.top.round(),
          'width': rect.width.round(),
          'height': rect.height.round(),
        },
      ],
    }),
    flush: true,
  );
}

class _CapturedPng {
  const _CapturedPng({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}

class _VisualSurface {
  const _VisualSurface(
    this.id,
    this.builder, {
    this.state = 'content',
    this.prepare,
    this.cleanup,
    this.destination,
    this.externalRegionId,
    this.externalRegionKey,
  }) : assert(
         (externalRegionId == null) == (externalRegionKey == null),
         '外部区域 id 与 key 必须同时提供',
       );

  final String id;
  final String state;
  final Widget Function() builder;
  final Future<void> Function(WidgetTester tester)? prepare;
  final Future<void> Function(WidgetTester tester)? cleanup;
  final String? destination;
  final String? externalRegionId;
  final Key? externalRegionKey;
}

int _destinationIndex(String destination) => switch (destination) {
  '主页' => 0,
  '教务' => 1,
  '课表' => 2,
  '信息' => 3,
  '邮箱' => 4,
  '跳转' => 5,
  '设置' => 6,
  _ => throw ArgumentError.value(destination, 'destination'),
};

final _surfaces = <_VisualSurface>[
  _VisualSurface('components.actions', _actionsPanel),
  _VisualSurface('components.inputs', _inputsPanel),
  _VisualSurface('components.feedback', _feedbackPanel),
  _VisualSurface('components.navigation', _navigationPanel),
  _VisualSurface('components.data', _dataPanel),
  _VisualSurface('components.domain', _domainPanel),
  _VisualSurface(
    'shell.startup',
    () => const AppStartupStatus(progressLabel: '正在初始化应用'),
    state: 'loading',
  ),
  _VisualSurface(
    'shell.startup',
    () => AppStartupStatus(errorMessage: '启动初始化失败：本地存储暂时不可用。', onRetry: () {}),
    state: 'error',
  ),
  _VisualSurface('shell.navigation', _shellNavigation),
  _VisualSurface('shell.more-drawer', _moreDrawerSurface),
  _VisualSurface('shell.close-confirmation', _closeConfirmationSurface),
  _VisualSurface('consent.first-run', _consentInitial, state: 'initial'),
  _VisualSurface('consent.first-run', _consentContent),
  _VisualSurface('security.lock', _lockInitial, state: 'initial'),
  _VisualSurface(
    'security.lock',
    _lockLoading,
    state: 'loading',
    prepare: _prepareLockLoading,
  ),
  _VisualSurface(
    'security.lock',
    _lockError,
    state: 'error',
    prepare: _prepareLockError,
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.initial),
    state: 'initial',
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.loading),
    state: 'loading',
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.content),
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.stale),
    state: 'stale',
    prepare: _prepareHomeDashboard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.dashboard',
    () => _homeDashboardPage(HomeDashboardDisplayState.error),
    state: 'error',
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.loading),
    state: 'loading',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.content),
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.empty),
    state: 'empty',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.stale),
    state: 'stale',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card',
    () => _homeCampusCardPage(HomeCampusCardDisplayState.error),
    state: 'error',
    prepare: _prepareHomeCampusCard,
    destination: '主页',
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.content),
    prepare: _prepareCampusCardDetailContent,
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.empty),
    state: 'empty',
  ),
  _VisualSurface(
    'home.campus-card-detail',
    () => _campusCardDetailPage(CampusCardDetailDisplayState.error),
    state: 'error',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.initial),
    state: 'initial',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.loading),
    state: 'loading',
    prepare: _prepareAcademicOverviewLoading,
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.content),
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.empty),
    state: 'empty',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.stale),
    state: 'stale',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.overview',
    () => _academicOverview(_AcademicOverviewScenario.error),
    state: 'error',
    destination: '教务',
  ),
  _VisualSurface(
    'academic.grade-detail',
    _academicGradeDetailLoading,
    state: 'loading',
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicGradeContentResult),
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicGradeEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.grade-detail',
    () => _academicGradeDetail(qingyuanAcademicDetailErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.exam-detail',
    _academicExamDetailLoading,
    state: 'loading',
    prepare: _prepareAcademicExamLoading,
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicExamContentResult),
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicExamEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.exam-detail',
    () => _academicExamDetail(qingyuanAcademicDetailErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.grade-process',
    _academicGradeProcessLoading,
    state: 'loading',
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicGradeProcessContentResult),
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicGradeProcessEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.grade-process',
    () => _academicGradeProcess(qingyuanAcademicDetailErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.student-report',
    () => const StudentReportDetailPage(result: null, isLoading: true),
    state: 'loading',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(result: qingyuanHomeStudentReportResult),
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanAcademicStudentReportEmptyResult,
    ),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanAcademicStudentReportStaleResult,
    ),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.student-report',
    () => StudentReportDetailPage(
      result: qingyuanAcademicStudentReportErrorResult,
    ),
    state: 'error',
  ),
  _VisualSurface(
    'academic.student-report-rules',
    () => StudentReportRulesPage(
      summary: qingyuanAcademicStudentReportContentSummary,
    ),
  ),
  _VisualSurface(
    'academic.student-report-rules',
    () => StudentReportRulesPage(
      summary: qingyuanAcademicStudentReportEmptyResult.summary!,
    ),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => const SportsAttendanceDetailPage(result: null, isLoading: true),
    state: 'loading',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(result: qingyuanHomeSportsResult),
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(result: qingyuanAcademicSportsEmptyResult),
    state: 'empty',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(result: qingyuanAcademicSportsStaleResult),
    state: 'stale',
  ),
  _VisualSurface(
    'academic.sports-attendance',
    () => SportsAttendanceDetailPage(result: qingyuanAcademicSportsErrorResult),
    state: 'error',
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarLoading,
    state: 'loading',
  ),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarContent,
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
  _VisualSurface('academic.calendar', _academicCalendarEmpty, state: 'empty'),
  _VisualSurface(
    'academic.calendar',
    _academicCalendarStale,
    state: 'stale',
    externalRegionId: 'document',
    externalRegionKey: _academicCalendarExternalRegionKey,
  ),
  _VisualSurface('academic.calendar', _academicCalendarError, state: 'error'),
  _VisualSurface(
    'schedule.calendar',
    _scheduleInitial,
    state: 'initial',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleLoading,
    state: 'loading',
    prepare: _startScheduleLoading,
    destination: '课表',
  ),
  _VisualSurface('schedule.calendar', _scheduleContent, destination: '课表'),
  _VisualSurface(
    'schedule.calendar',
    _scheduleEmpty,
    state: 'empty',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleStale,
    state: 'stale',
    destination: '课表',
  ),
  _VisualSurface(
    'schedule.calendar',
    _scheduleError,
    state: 'error',
    destination: '课表',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.initial),
    state: 'initial',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.loading),
    state: 'loading',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.content, withMessages: true),
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.empty),
    state: 'empty',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.stale, withMessages: true),
    state: 'stale',
    destination: '信息',
  ),
  _VisualSurface(
    'info.feed',
    () => _infoPage(InfoPageDisplayState.error),
    state: 'error',
    destination: '信息',
  ),
  _VisualSurface(
    'info.filters',
    () => _infoPage(InfoPageDisplayState.content, withMessages: true),
    destination: '信息',
  ),
  _VisualSurface(
    'info.filters',
    () => _infoPage(
      InfoPageDisplayState.content,
      withMessages: true,
      filterEmpty: true,
    ),
    state: 'empty',
    destination: '信息',
  ),
  _VisualSurface(
    'mail.inbox',
    _mailInitial,
    state: 'initial',
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.inbox',
    _mailLoading,
    state: 'loading',
    prepare: _startMailLoading,
    destination: '邮箱',
  ),
  _VisualSurface('mail.inbox', _mailContent, destination: '邮箱'),
  _VisualSurface('mail.inbox', _mailEmpty, state: 'empty', destination: '邮箱'),
  _VisualSurface('mail.inbox', _mailStale, state: 'stale', destination: '邮箱'),
  _VisualSurface('mail.inbox', _mailError, state: 'error', destination: '邮箱'),
  _VisualSurface(
    'mail.message-detail',
    () => EmailMessageDetailPage(
      message: qingyuanEmailMessages.first,
      nowOverride: qingyuanVisualNow,
    ),
  ),
  _VisualSurface(
    'mail.compose',
    _mailContent,
    state: 'initial',
    prepare: _openMailCompose,
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.compose',
    _mailContent,
    prepare: _prepareMailComposeContent,
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.compose',
    _mailComposeLoading,
    state: 'loading',
    prepare: _prepareMailComposeLoading,
    destination: '邮箱',
  ),
  _VisualSurface(
    'mail.compose',
    _mailComposeError,
    state: 'error',
    prepare: _prepareMailComposeError,
    cleanup: _clearMailFeedback,
    destination: '邮箱',
  ),
  _VisualSurface('links.directory', _quickLinksContent, destination: '跳转'),
  _VisualSurface(
    'links.directory',
    _quickLinksLoading,
    state: 'loading',
    destination: '跳转',
  ),
  _VisualSurface(
    'links.directory',
    _quickLinksEmpty,
    state: 'empty',
    destination: '跳转',
  ),
  _VisualSurface(
    'links.directory',
    _quickLinksError,
    state: 'error',
    destination: '跳转',
  ),
  _VisualSurface(
    'links.external-confirmation',
    _externalLinkConfirmationContent,
  ),
  _VisualSurface(
    'links.external-confirmation',
    _externalLinkConfirmationError,
    state: 'error',
  ),
  _VisualSurface('legal.notice', _legalNoticeSurface),
  _VisualSurface('legal.agreement', _legalAgreementSurface),
  _VisualSurface('legal.privacy', _legalPrivacySurface),
  _VisualSurface('settings.account', _settingsAccountContent),
  _VisualSurface('settings.account', _settingsAccountError, state: 'error'),
  _VisualSurface(
    'settings.home-notifications',
    _settingsHomeNotifications,
    prepare: _showSettingsNotifications,
  ),
  _VisualSurface('settings.appearance', _settingsAppearance),
  for (final state in SettingsDataPrivacyState.values)
    _VisualSurface(
      'settings.data-privacy',
      () => _settingsDataPrivacy(state),
      state: state.name,
    ),
  for (final state in SettingsWechatAuthDisplayState.values)
    _VisualSurface(
      'settings.wechat-auth',
      () => _settingsWechatAuth(state),
      state: state.name,
    ),
  _VisualSurface('settings.update', _settingsUpdateInitial, state: 'initial'),
  _VisualSurface(
    'settings.update',
    _settingsUpdateLoading,
    state: 'loading',
    prepare: _startSettingsUpdateCheck,
  ),
  _VisualSurface(
    'settings.update',
    _settingsUpdateContent,
    prepare: _startSettingsUpdateCheck,
  ),
  _VisualSurface(
    'settings.update',
    _settingsUpdateError,
    state: 'error',
    prepare: _startSettingsUpdateCheck,
  ),
  _VisualSurface('settings.about', () => const AboutPage()),
  _VisualSurface(
    'external.webview',
    () => _externalWebViewSurface(loading: true),
    state: 'loading',
  ),
  _VisualSurface(
    'external.webview',
    () => _externalWebViewSurface(loading: false),
    externalRegionId: 'document',
    externalRegionKey: _webViewExternalRegionKey,
  ),
  _VisualSurface(
    'external.webview',
    () => const WebViewPage(url: 'invalid-url', initialTitle: '校园服务'),
    state: 'error',
  ),
  for (final state in const ['loading', 'content', 'error'])
    _VisualSurface(
      'external.pdf',
      () => _externalPdfSurface(state),
      state: state,
      externalRegionId: state == 'content' ? 'document' : null,
      externalRegionKey: state == 'content' ? _pdfExternalRegionKey : null,
    ),
  for (final state in const ['initial', 'content', 'error'])
    _VisualSurface(
      'external.system-auth',
      () => _externalSystemAuthSurface(state),
      state: state,
      externalRegionId: state == 'content' ? 'system-dialog' : null,
      externalRegionKey: state == 'content'
          ? _systemAuthExternalRegionKey
          : null,
    ),
];

Widget _settingsPageSurface(String title, Widget child) => Builder(
  builder: (context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(title: title),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.medium),
            child: child,
          ),
        ),
      ),
    );
  },
);

Widget _settingsAppearance() => _stateReferenceShell(
  SettingsAppearancePage(
    themeMode: YhThemeMode.system,
    onChanged: (_) {},
    onApply: () {},
  ),
);

Widget _stateReferenceShell(Widget page) => Builder(
  builder: (context) {
    final theme = context.yhTheme;
    final media = MediaQuery.of(context);
    final shellMedia = media.copyWith(
      size: Size(
        math.min(
          media.size.width,
          theme.breakpoint.expanded - theme.layout.divider,
        ),
        media.size.height,
      ),
    );
    return ColoredBox(
      color: theme.color.background,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.l,
          vertical: theme.spacing.l + theme.spacing.m,
        ),
        child: MediaQuery(
          data: shellMedia,
          child: AppShell(
            initialDestinationIndex: _destinationIndex('设置'),
            destinationOverrides: {'设置': page},
          ),
        ),
      ),
    );
  },
);

Widget _legalNoticeSurface() => _legalReferenceSurface(
  title: '法律声明',
  kicker: '法律与许可',
  summary: '正文从应用内确定性资源加载，加载失败仍保留返回和重试。',
  primaryActionLabel: '返回设置',
  sectionTitles: const ['非学校官方应用', '数据来源说明', '责任边界'],
);

Widget _legalPrivacySurface() => _legalReferenceSurface(
  title: '隐私说明',
  kicker: '法律与隐私',
  summary: '按数据类型说明收集目的、存储位置、联网时机和删除方式。',
  primaryActionLabel: '管理本地数据',
  sectionTitles: const ['账户凭据', '校园数据缓存', '诊断信息'],
);

Widget _legalAgreementSurface() => _legalReferenceSurface(
  title: '用户协议',
  kicker: '法律与协议',
  summary: '说明只读聚合、用户责任和外部服务边界，首次确认后仍可再次阅读。',
  primaryActionLabel: '返回',
  sectionTitles: const ['服务范围', '使用规则', '协议变更'],
);

Widget _legalReferenceSurface({
  required String title,
  required String kicker,
  required String summary,
  required String primaryActionLabel,
  required List<String> sectionTitles,
}) => Builder(
  builder: (context) {
    final theme = context.yhTheme;
    final media = MediaQuery.of(context);
    final shellMedia = media.copyWith(
      size: Size(
        math.min(
          media.size.width,
          theme.breakpoint.expanded - theme.layout.divider,
        ),
        media.size.height,
      ),
    );
    final page = LegalNoticePage(
      title: title,
      kicker: kicker,
      summary: summary,
      source: '随应用发布的文本',
      sourceTimestamp: '2026-07-18 · 09:30',
      primaryActionLabel: primaryActionLabel,
      sections: [
        for (var index = 0; index < sectionTitles.length; index++)
          LegalNoticeSection(
            title: sectionTitles[index],
            body: '${index + 1}. 本节说明该数据与功能的使用边界、保存位置和用户可执行的管理方式。',
          ),
      ],
    );
    return ColoredBox(
      color: theme.color.background,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.l,
          vertical: theme.spacing.l + theme.spacing.m,
        ),
        child: MediaQuery(
          data: shellMedia,
          child: AppShell(
            initialDestinationIndex: _destinationIndex('设置'),
            destinationOverrides: {'设置': page},
          ),
        ),
      ),
    );
  },
);

Widget _settingsHomeNotifications() => _settingsPageSurface(
  '首页与通知',
  SettingsGeneralSection(
    closeBehavior: 'ask',
    notificationEnabled: true,
    dndEnabled: true,
    homeStudentProfileCardVisible: true,
    homeCampusCardBalanceCardVisible: true,
    homeTodayCoursesTileVisible: true,
    homeSportsAttendanceTileVisible: true,
    homeStudentReportTileVisible: true,
    homeMessagesTileVisible: true,
    homeEmailTileVisible: true,
    homeQuickLinksTileVisible: true,
    dndStartHour: 22,
    dndStartMinute: 0,
    dndEndHour: 7,
    dndEndMinute: 0,
    onCloseBehaviorChanged: (_) {},
    onNotificationChanged: (_) {},
    onDndChanged: (_) {},
    onHomeStudentProfileCardVisibleChanged: (_) {},
    onHomeCampusCardBalanceCardVisibleChanged: (_) {},
    onHomeTodayCoursesTileVisibleChanged: (_) {},
    onHomeSportsAttendanceTileVisibleChanged: (_) {},
    onHomeStudentReportTileVisibleChanged: (_) {},
    onHomeMessagesTileVisibleChanged: (_) {},
    onHomeEmailTileVisibleChanged: (_) {},
    onHomeQuickLinksTileVisibleChanged: (_) {},
    onDndStartChanged: (_, _) async {},
    onDndEndChanged: (_, _) async {},
  ),
);

Future<void> _showSettingsNotifications(WidgetTester tester) async {
  await tester.ensureVisible(find.text('消息推送'));
  await tester.pump();
}

Widget _settingsAccountContent() =>
    _settingsPageSurface('账户连接', _settingsSecuritySection());

Widget _settingsAccountError() => _settingsPageSurface(
  '账户连接',
  Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const YhBanner(
        text: '账号验证失败：校园服务暂时不可达。请检查网络后重新验证。',
        kind: YhBannerKind.danger,
      ),
      SizedBox(height: YhTheme.light.spacing.m),
      _settingsSecuritySection(),
    ],
  ),
);

Widget _settingsSecuritySection() => SettingsSecuritySection(
  isPasswordEnabled: true,
  onPasswordProtectionChanged: (_) {},
  onChangePassword: () {},
  isQuickAuthEnabled: true,
  isQuickAuthAvailable: true,
  isQuickAuthBusy: false,
  onQuickAuthChanged: (_) {},
  onLock: () {},
);

Widget _settingsDataPrivacy(SettingsDataPrivacyState state) =>
    _stateReferenceShell(
      SettingsDataPrivacyPage(
        state: state,
        sourceTimestamp: '2026-07-18 · 09:30',
        onClearCampusCache: () async => true,
        onDisconnectAccounts: () async => true,
        onOpenPrivacy: () {},
      ),
    );

Widget _settingsWechatAuth(SettingsWechatAuthDisplayState state) =>
    _settingsPageSurface(
      '微信认证',
      SettingsWechatAuthStatusCard(
        state: state,
        configPath: '应用数据目录/wxmp_config.json',
        statusMessage: switch (state) {
          SettingsWechatAuthDisplayState.initial => '尚未连接公众号平台账号。',
          SettingsWechatAuthDisplayState.loading => '正在校验 Cookie 与 Token…',
          SettingsWechatAuthDisplayState.content => '认证有效，可获取已关注公众号推文。',
          SettingsWechatAuthDisplayState.error => '认证已过期，请重新扫码登录。',
        },
        onLogin: () {},
        onEdit: () {},
        onValidate: () {},
        onClear: state == SettingsWechatAuthDisplayState.content ? () {} : null,
      ),
    );

Widget _settingsUpdateInitial() => _settingsUpdateSurface(
  _VisualUpdateService(() async => _visualUpdateResult),
);

Widget _settingsUpdateLoading() => _settingsUpdateSurface(
  _VisualUpdateService(() => Completer<AppUpdateCheckResult>().future),
);

Widget _settingsUpdateContent() => _settingsUpdateSurface(
  _VisualUpdateService(() async => _visualUpdateResult),
);

Widget _settingsUpdateError() => _settingsUpdateSurface(
  _VisualUpdateService(
    () => Future.error(
      DioException(
        requestOptions: RequestOptions(path: '/releases'),
        type: DioExceptionType.connectionError,
        error: 'network unavailable',
      ),
    ),
  ),
);

Widget _settingsUpdateSurface(AppUpdateService service) => _settingsPageSurface(
  '应用更新',
  SettingsUpdateSection(
    updateService: service,
    launchUrlOverride: (_) async => true,
  ),
);

Future<void> _startSettingsUpdateCheck(WidgetTester tester) async {
  await tester.tap(find.text('检查更新').last);
  await tester.pump();
  await tester.pump();
}

class _VisualUpdateService extends AppUpdateService {
  _VisualUpdateService(this.loader);

  final Future<AppUpdateCheckResult> Function() loader;

  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) => loader();
}

const AppUpdateCheckResult _visualUpdateResult = AppUpdateCheckResult(
  status: AppUpdateStatus.upToDate,
  currentVersion: '1.0.0',
  channel: AppUpdateChannel.stable,
  release: null,
  recommendedAsset: null,
  message: '当前已是正式版最新版本。',
);

const Key _webViewExternalRegionKey = Key('visual-webview-document');
const Key _pdfExternalRegionKey = Key('visual-pdf-document');
const Key _systemAuthExternalRegionKey = Key('visual-system-auth-dialog');

Widget _externalWebViewSurface({required bool loading}) => WebViewPageFrame(
  title: loading ? '正在打开校园门户' : '校园门户',
  onBackPressed: () {},
  progress: loading ? 0.38 : null,
  actions: [
    YhIconButton(semanticLabel: '刷新', icon: YhIcons.refresh, onTap: () {}),
    YhIconButton(semanticLabel: '在浏览器中打开', icon: YhIcons.open, onTap: () {}),
  ],
  document: _externalDocumentRegion(
    key: _webViewExternalRegionKey,
    icon: YhIcons.open,
    title: loading ? '网页正在加载' : '上海第二工业大学校园门户',
    message: loading
        ? '平台 WebView runner 将在此处加载真实网页。'
        : '网页正文属于外部区域，按 SSIM 0.95 独立验收。',
    loading: loading,
  ),
);

Widget _externalPdfSurface(String state) => AcademicCalendarPdfFrame(
  title: '2025—2026 学年校历',
  onBack: () {},
  pageLabel: state == 'content' ? '第 1 / 4 页' : '页码加载中',
  onZoomOut: state == 'content' ? () {} : null,
  onZoomIn: state == 'content' ? () {} : null,
  onDownload: () {},
  onOpenExternal: () {},
  document: _externalDocumentRegion(
    key: _pdfExternalRegionKey,
    icon: state == 'error' ? YhIcons.warning : YhIcons.library,
    title: switch (state) {
      'loading' => '正在加载校历 PDF',
      'error' => 'PDF 加载失败',
      _ => '2025—2026 学年校历正文',
    },
    message: switch (state) {
      'loading' => '正在准备页面与字体…',
      'error' => '无法读取 PDF。可使用右上角按钮在外部应用中打开。',
      _ => 'PDF 正文属于外部区域，按 SSIM 0.95 独立验收。',
    },
    loading: state == 'loading',
  ),
);

Widget _externalSystemAuthSurface(String state) => Builder(
  builder: (context) => Stack(
    fit: StackFit.expand,
    children: [
      _lockInitial(),
      ColoredBox(color: context.yhTheme.color.scrim),
      Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final theme = context.yhTheme;
            final width = math.min(
              theme.layout.dialogWidth,
              constraints.maxWidth - theme.spacing.l * 2,
            );
            return KeyedSubtree(
              key: _systemAuthExternalRegionKey,
              child: SizedBox(
                width: width,
                height: theme.breakpoint.compact / 2,
                child: YhCard(
                  child: YhEmptyState(
                    icon: state == 'error'
                        ? YhIcons.warning
                        : YhIcons.fingerprint,
                    title: switch (state) {
                      'initial' => '准备系统认证',
                      'error' => '系统认证未完成',
                      _ => '验证身份以解锁工大聚合',
                    },
                    message: switch (state) {
                      'initial' => '系统即将请求设备 PIN 或生物识别。',
                      'error' => '请重试系统认证，或返回应用输入密码。',
                      _ => '此区域由操作系统绘制，按 SSIM 0.95 独立验收。',
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  ),
);

Widget _externalDocumentRegion({
  required Key key,
  required IconData icon,
  required String title,
  required String message,
  bool loading = false,
}) => Builder(
  builder: (context) => KeyedSubtree(
    key: key,
    child: ColoredBox(
      color: context.yhTheme.color.sunken,
      child: Center(
        child: loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const YhProgress(showPercent: false),
                  SizedBox(height: context.yhTheme.spacing.m),
                  Text(title),
                  SizedBox(height: context.yhTheme.spacing.xs),
                  Text(message),
                ],
              )
            : YhEmptyState(icon: icon, title: title, message: message),
      ),
    ),
  ),
);

Widget _shellNavigation({int initialDestinationIndex = 0}) {
  final page = const YhPageScaffold(
    appBar: YhAppBar(title: '清源导航'),
    body: YhEmptyState(
      icon: YhIcons.home,
      title: '校园服务都在这里',
      message: '主目的地随窗口宽度切换为底栏、紧凑导航轨或扩展导航轨。',
    ),
  );
  return AppShell(
    initialDestinationIndex: initialDestinationIndex,
    destinationOverrides: {
      for (final name in const ['主页', '教务', '课表', '信息', '邮箱', '跳转', '设置'])
        name: page,
    },
  );
}

Widget _moreDrawerSurface() => Builder(
  builder: (context) {
    final shell = _shellNavigation(initialDestinationIndex: 4);
    final media = MediaQuery.of(context);
    final usesCompactNavigation =
        media.size.width < context.yhTheme.breakpoint.medium;
    if (!usesCompactNavigation) {
      return shell;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        shell,
        ColoredBox(color: context.yhTheme.color.scrim),
        Align(
          alignment: Alignment.bottomCenter,
          child: YhBottomDrawer(
            title: '更多',
            child: AppMoreDestinationsContent(
              items: [
                AppMoreDestination(
                  label: '邮箱',
                  icon: YhIcons.mail,
                  selected: true,
                  onSelected: () {},
                ),
                AppMoreDestination(
                  label: '跳转',
                  icon: YhIcons.link,
                  onSelected: () {},
                ),
                AppMoreDestination(
                  label: '设置',
                  icon: YhIcons.settings,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

Widget _closeConfirmationSurface() => _modalSurface(
  background: _shellNavigation(),
  modal: AppCloseConfirmationDialog(
    onMinimize: (_) async {},
    onExit: (_) async {},
  ),
);

Widget _consentInitial() => _modalSurface(
  background: const AppStartupStatus(progressLabel: '正在准备法律与隐私说明'),
  modal: LegalConsentDialog(
    onAccept: () {},
    onDecline: () {},
    loadLegalNotice: (_) => Completer<String>().future,
  ),
);

Widget _consentContent() => _modalSurface(
  background: const AppStartupStatus(progressLabel: '正在准备法律与隐私说明'),
  modal: LegalConsentDialog(
    onAccept: () {},
    onDecline: () {},
    loadLegalNotice: (_) async => _visualLegalNotice,
  ),
);

Widget _modalSurface({required Widget background, required Widget modal}) =>
    Builder(
      builder: (context) => Stack(
        fit: StackFit.expand,
        children: [
          background,
          ColoredBox(color: context.yhTheme.color.scrim),
          modal,
        ],
      ),
    );

const String _visualLegalNotice = '''
工大聚合法律与隐私说明

一、免责声明
本应用仅在用户设备本地聚合校园服务信息，不代表学校官方发布渠道。

二、用户协议
用户应妥善保管账户信息，仅将本应用用于本人校园学习与生活服务。

三、隐私协议
凭据与业务缓存保存在本地；主动刷新时，数据会提交给对应校园服务处理。

四、第三方协议
开源软件、字体和平台能力按照各自许可证与系统条款使用。
''';

Widget _lockInitial() => LockPage(
  onUnlocked: () {},
  authentication: _VisualLockAuthentication(
    verification: Future<bool>.value(false),
  ),
);

Widget _lockLoading() => LockPage(
  onUnlocked: () {},
  authentication: _VisualLockAuthentication(
    verification: Completer<bool>().future,
  ),
);

Widget _lockError() => LockPage(
  onUnlocked: () {},
  authentication: _VisualLockAuthentication(
    verification: Future<bool>.value(false),
  ),
);

Future<void> _prepareLockLoading(WidgetTester tester) async {
  await tester.enterText(find.byType(YhTextField), 'visual-password');
  await tester.tap(find.text('解锁'));
  await tester.pump();
  if (find.text('正在验证…').evaluate().isEmpty) {
    throw StateError('锁屏未进入 loading 状态');
  }
}

Future<void> _prepareLockError(WidgetTester tester) async {
  await tester.enterText(find.byType(YhTextField), 'wrong-password');
  await tester.tap(find.text('解锁'));
  await tester.pump();
  await tester.pump();
  if (find.text('密码错误，请重试').evaluate().isEmpty) {
    throw StateError('锁屏未进入 error 状态');
  }
}

class _VisualLockAuthentication implements LockAuthenticationAdapter {
  const _VisualLockAuthentication({required this.verification});

  final Future<bool> verification;

  @override
  Future<bool> verifyPassword(String password) => verification;

  @override
  Future<bool> isQuickAuthEnabled() async => false;

  @override
  Future<bool> isSystemAuthAvailable() async => false;

  @override
  Future<SystemAuthResult> authenticate(String localizedReason) async =>
      SystemAuthResult.unavailable;
}

enum _AcademicOverviewScenario {
  initial,
  loading,
  content,
  empty,
  stale,
  error,
}

Widget _academicOverview(_AcademicOverviewScenario scenario) {
  final loading = scenario == _AcademicOverviewScenario.loading;
  final hasCache = switch (scenario) {
    _AcademicOverviewScenario.initial ||
    _AcademicOverviewScenario.loading => false,
    _ => true,
  };
  final overviewResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicOverviewEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicOverviewStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicDetailErrorResult,
    _ => qingyuanHomeAcademicResult,
  };
  final gradeResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicGradeEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicGradeStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicDetailErrorResult,
    _ => qingyuanAcademicGradeContentResult,
  };
  final examResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicExamEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicExamStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicDetailErrorResult,
    _ => qingyuanAcademicExamContentResult,
  };
  final sportsResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicSportsEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicSportsStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicSportsErrorResult,
    _ => qingyuanHomeSportsResult,
  };
  final reportResult = switch (scenario) {
    _AcademicOverviewScenario.empty => qingyuanAcademicStudentReportEmptyResult,
    _AcademicOverviewScenario.stale => qingyuanAcademicStudentReportStaleResult,
    _AcademicOverviewScenario.error => qingyuanAcademicStudentReportErrorResult,
    _ => qingyuanHomeStudentReportResult,
  };
  return AcademicPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: overviewResult,
      cachedOverviewResult: hasCache ? overviewResult : null,
      cachedGradeResult: hasCache ? gradeResult : null,
      cachedExamResult: hasCache ? examResult : null,
      examResult: examResult,
      gradeResult: gradeResult,
      pendingOverview: loading ? Completer<AcademicEamsQueryResult>() : null,
    ),
    sportsAttendanceService: QingyuanVisualSportsAttendanceClient(
      sportsResult,
      cacheEnabled: hasCache,
      pendingFetch: loading ? Completer<SportsAttendanceQueryResult>() : null,
    ),
    studentReportService: QingyuanVisualStudentReportClient(
      reportResult,
      cacheEnabled: hasCache,
      pendingFetch: loading ? Completer<StudentReportQueryResult>() : null,
    ),
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    academicEamsAutoRefreshEnabledOverride: loading,
    academicEamsAutoRefreshIntervalOverride: 30,
    sportsAttendanceAutoRefreshEnabledOverride: loading,
    sportsAttendanceAutoRefreshIntervalOverride: 30,
    studentReportAutoRefreshEnabledOverride: loading,
    studentReportAutoRefreshIntervalOverride: 30,
  );
}

Future<void> _prepareAcademicOverviewLoading(WidgetTester tester) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('正在读取本专科教务摘要...').evaluate().isNotEmpty) return;
  }
  throw StateError('教务概览未在固定等待窗口内进入 loading 状态');
}

Widget _academicGradeDetail(AcademicEamsQueryResult result) {
  return AcademicEamsGradeDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: result,
      gradeResult: result,
    ),
    initialResult: result,
    onResultChanged: (_) {},
  );
}

Widget _academicGradeDetailLoading() {
  return AcademicEamsGradeDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicGradeContentResult,
      pendingGrades: Completer<AcademicEamsQueryResult>(),
    ),
    initialResult: null,
    onResultChanged: (_) {},
  );
}

Widget _academicExamDetail(AcademicEamsQueryResult result) {
  return AcademicEamsExamDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: result,
      examResult: result,
    ),
    initialResult: result,
    initialSelectedTerm: qingyuanAcademicSemester.termChoice,
    initialSelectedSemester: qingyuanAcademicSemester,
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    onResultChanged: (_, _, _) {},
  );
}

Widget _academicExamDetailLoading() {
  return AcademicEamsExamDetailPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicExamContentResult,
      pendingExam: Completer<AcademicEamsQueryResult>(),
    ),
    initialResult: null,
    initialSelectedTerm: qingyuanAcademicSemester.termChoice,
    initialSelectedSemester: qingyuanAcademicSemester,
    academicTermService: buildQingyuanVisualAcademicTermService(),
    academicTermNow: qingyuanVisualNow,
    onResultChanged: (_, _, _) {},
  );
}

Future<void> _prepareAcademicExamLoading(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('academic-eams-exam-detail-search')));
  await tester.pump();
}

Widget _academicGradeProcess(AcademicEamsQueryResult result) {
  return AcademicEamsGradeProcessPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: result,
      gradeProcessResult: result,
    ),
    initialTerm: qingyuanAcademicSemester.termChoice,
    initialSemester: qingyuanAcademicSemester,
  );
}

Widget _academicGradeProcessLoading() {
  return AcademicEamsGradeProcessPage(
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: qingyuanAcademicGradeProcessContentResult,
      pendingGradeProcess: Completer<AcademicEamsQueryResult>(),
    ),
    initialTerm: qingyuanAcademicSemester.termChoice,
    initialSemester: qingyuanAcademicSemester,
  );
}

Widget _academicCalendarLoading() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      pendingViewer: Completer<AcademicCalendarSyncResult>(),
    ),
  );
}

Widget _academicCalendarContent() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      cachedEntries: qingyuanAcademicCalendarEntries,
      viewerResult: qingyuanAcademicCalendarContentResult,
    ),
  );
}

Widget _academicCalendarEmpty() {
  return _academicCalendarPage(
    const QingyuanVisualAcademicCalendarClient(
      viewerResult: qingyuanAcademicCalendarEmptyResult,
    ),
  );
}

Widget _academicCalendarStale() {
  return _academicCalendarPage(
    QingyuanVisualAcademicCalendarClient(
      cachedEntries: qingyuanAcademicCalendarEntries,
      viewerResult: qingyuanAcademicCalendarStaleResult,
    ),
  );
}

Widget _academicCalendarError() {
  return _academicCalendarPage(
    const QingyuanVisualAcademicCalendarClient(
      viewerResult: qingyuanAcademicCalendarErrorResult,
    ),
  );
}

const Key _academicCalendarExternalRegionKey = Key(
  'academic-calendar-external-region',
);

Widget _academicCalendarPage(QingyuanVisualAcademicCalendarClient service) {
  return AcademicCalendarPage(
    service: service,
    viewerBuilder: (context, entry) {
      final theme = context.yhTheme;
      return KeyedSubtree(
        key: _academicCalendarExternalRegionKey,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.color.sunken,
            border: Border.all(color: theme.color.border),
            borderRadius: BorderRadius.circular(theme.radius.l),
          ),
          child: YhEmptyState(
            icon: YhIcons.library,
            title: entry == null
                ? '请选择校历'
                : '${entry.schoolYearLabel} · 外部 PDF 区域',
            message: entry == null
                ? '从校历列表选择一个学年。'
                : '平台 runner 验证真实 PDF 正文；此区域按外部内容 0.95 独立判定。',
          ),
        ),
      );
    },
  );
}

const _qingyuanHomeQuickLinks = <QuickLinkItemConfig>[
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

Widget _homeDashboardPage(HomeDashboardDisplayState state) =>
    _homeCampusCardPage(
      HomeCampusCardDisplayState.content,
      dashboardState: state,
      focusCampusCard: false,
    );

Widget _homeCampusCardPage(
  HomeCampusCardDisplayState state, {
  HomeDashboardDisplayState dashboardState = HomeDashboardDisplayState.content,
  bool focusCampusCard = true,
}) {
  final result = switch (state) {
    HomeCampusCardDisplayState.empty => qingyuanCampusCardEmptyResult,
    HomeCampusCardDisplayState.stale => qingyuanCampusCardStaleResult,
    HomeCampusCardDisplayState.error => qingyuanCampusCardErrorResult,
    HomeCampusCardDisplayState.loading ||
    HomeCampusCardDisplayState.content => qingyuanCampusCardContentResult,
  };
  return HomePage(
    campusCardService: QingyuanVisualCampusCardClient(result: result),
    academicEamsService: QingyuanVisualAcademicEamsClient(
      result: focusCampusCard
          ? qingyuanAcademicOverviewEmptyResult
          : qingyuanHomeAcademicResult,
      cachedResult: focusCampusCard
          ? qingyuanAcademicOverviewEmptyResult
          : qingyuanHomeAcademicResult,
      cachedOverviewResult: focusCampusCard
          ? qingyuanAcademicOverviewEmptyResult
          : qingyuanHomeAcademicResult,
    ),
    sportsAttendanceService: QingyuanVisualSportsAttendanceClient(
      focusCampusCard
          ? qingyuanAcademicSportsEmptyResult
          : qingyuanHomeSportsResult,
    ),
    studentReportService: QingyuanVisualStudentReportClient(
      focusCampusCard
          ? qingyuanAcademicStudentReportEmptyResult
          : qingyuanHomeStudentReportResult,
    ),
    emailService: QingyuanVisualEmailClient(
      cachedResult: focusCampusCard
          ? qingyuanEmailEmptyResult
          : qingyuanHomeEmailResult,
    ),
    campusNetworkStatusService: _visualCampusNetworkStatusService(),
    campusCardAutoRefreshEnabledOverride: false,
    campusCardResultOverride: result,
    campusCardDisplayStateOverride: state,
    nowOverride: qingyuanVisualNow,
    messagesOverride: focusCampusCard ? const [] : qingyuanHomeMessages,
    homeUpdatedAtOverride: DateTime(2026, 7, 18, 8, 42),
    homeCountdownMinutesOverride: 42,
    homeCourseTimeOverrides: const {'数据结构': '10:00'},
    dashboardDisplayStateOverride: dashboardState,
    courseTableResultOverride: focusCampusCard
        ? qingyuanAcademicOverviewEmptyResult
        : qingyuanHomeAcademicResult,
    academicOverviewResultOverride: focusCampusCard
        ? qingyuanAcademicOverviewEmptyResult
        : qingyuanHomeAcademicResult,
    sportsAttendanceResultOverride: focusCampusCard
        ? qingyuanAcademicSportsEmptyResult
        : qingyuanHomeSportsResult,
    emailResultOverride: focusCampusCard
        ? qingyuanEmailEmptyResult
        : qingyuanHomeEmailResult,
    studentReportResultOverride: focusCampusCard
        ? qingyuanAcademicStudentReportEmptyResult
        : qingyuanHomeStudentReportResult,
    quickLinkFavoritesOverride: focusCampusCard
        ? const []
        : _qingyuanHomeQuickLinks,
  );
}

CampusNetworkStatusService _visualCampusNetworkStatusService() {
  return CampusNetworkStatusService(
    probe: (uri, timeout) async => CampusNetworkProbeResult(
      reachable: uri != CampusNetworkStatusService.defaultVpnProbeUri,
      statusCode: 200,
      detail: '视觉 fixture 已连接 ${uri.host}',
    ),
  );
}

Future<void> _prepareHomeCampusCard(WidgetTester tester) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find
        .byKey(const Key('home-campus-card-balance-card'))
        .evaluate()
        .isNotEmpty) {
      break;
    }
  }
  if (find
      .byKey(const Key('home-campus-card-balance-card'))
      .evaluate()
      .isEmpty) {
    throw StateError('校园卡 fixture 未在固定等待窗口内完成加载');
  }
  await _centerInScrollable(
    tester,
    find.byKey(const Key('home-campus-card-balance-card')),
  );
  await tester.pump();
}

Future<void> _prepareHomeDashboard(WidgetTester tester) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('高等数学').evaluate().isNotEmpty) return;
  }
  throw StateError('首页确定性 fixture 未在预期时间内完成加载');
}

Widget _campusCardDetailPage(CampusCardDetailDisplayState state) {
  final snapshot = state == CampusCardDetailDisplayState.empty
      ? qingyuanCampusCardEmptyResult.snapshot!
      : qingyuanCampusCardContentResult.snapshot!;
  return CampusCardDetailPage(
    initialSnapshot: snapshot,
    campusCardService: QingyuanVisualCampusCardClient(
      result: qingyuanCampusCardContentResult,
    ),
    nowOverride: qingyuanVisualNow,
    displayStateOverride: state,
  );
}

Future<void> _prepareCampusCardDetailContent(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('campus-card-recent-seven-days')));
  await tester.pump();
}

Widget _infoPage(
  InfoPageDisplayState state, {
  bool withMessages = false,
  bool filterEmpty = false,
}) => InfoPage(
  displayStateOverride: state,
  messagesOverride: withMessages ? qingyuanInfoMessages : const [],
  wechatSourceConfiguredOverride: true,
  nowOverride: qingyuanVisualNow,
  messageRenderLimitOverride: 3,
  filterEmptyOverride: filterEmpty,
);

Widget _schedulePage({
  required QingyuanVisualAcademicEamsClient service,
  AcademicEamsQueryResult? initialResult,
}) {
  return CourseSchedulePage(
    academicEamsService: service,
    initialResult: initialResult,
    autoRefreshEnabledOverride: false,
    nowOverride: qingyuanVisualNow,
  );
}

Widget _scheduleInitial() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
  ),
);

Widget _scheduleLoading() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
    pendingCourseTable: Completer<AcademicEamsQueryResult>(),
  ),
);

Future<void> _startScheduleLoading(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('course-schedule-refresh')));
}

Widget _scheduleContent() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleContentResult,
  ),
  initialResult: qingyuanScheduleContentResult,
);

Widget _scheduleEmpty() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleEmptyResult,
  ),
  initialResult: qingyuanScheduleEmptyResult,
);

Widget _scheduleStale() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleStaleResult,
  ),
  initialResult: qingyuanScheduleStaleResult,
);

Widget _scheduleError() => _schedulePage(
  service: QingyuanVisualAcademicEamsClient(
    result: qingyuanScheduleErrorResult,
  ),
  initialResult: qingyuanScheduleErrorResult,
);

Widget _mailPage(QingyuanVisualEmailClient service) {
  return EmailPage(
    emailService: service,
    emailAutoRefreshEnabledOverride: false,
    emailAutoRefreshIntervalOverride: 30,
    nowOverride: qingyuanVisualNow,
  );
}

Widget _mailInitial() => _mailPage(QingyuanVisualEmailClient());

Widget _mailLoading() => _mailPage(
  QingyuanVisualEmailClient(pendingFetch: Completer<EmailMailboxQueryResult>()),
);

Future<void> _startMailLoading(WidgetTester tester) async {
  await tester.tap(find.text('读取最近邮件').first);
}

Widget _mailContent() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailContentResult),
);

Widget _mailEmpty() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailEmptyResult),
);

Widget _mailStale() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailStaleResult),
);

Widget _mailError() => _mailPage(
  QingyuanVisualEmailClient(cachedResult: qingyuanEmailErrorResult),
);

Future<void> _openMailCompose(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('email-compose-open')));
  await tester.pump();
}

Future<void> _prepareMailComposeContent(WidgetTester tester) async {
  await _openMailCompose(tester);
  await _fillMailCompose(tester);
}

Future<void> _fillMailCompose(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(YhTextField, '收件人'),
    'advisor@example.invalid',
  );
  await tester.enterText(find.widgetWithText(YhTextField, '主题'), '课程安排确认');
  await tester.enterText(
    find.widgetWithText(YhTextField, '正文'),
    '老师您好，我已核对本学期课程安排，谢谢。',
  );
}

Widget _mailComposeLoading() => _mailPage(
  QingyuanVisualEmailClient(
    cachedResult: qingyuanEmailContentResult,
    pendingSend: Completer<EmailSendResult>(),
  ),
);

Widget _mailComposeError() => _mailPage(
  QingyuanVisualEmailClient(
    cachedResult: qingyuanEmailContentResult,
    sendResult: qingyuanEmailSendErrorResult,
  ),
);

Future<void> _prepareMailComposeSending(WidgetTester tester) async {
  await _openMailCompose(tester);
  await _fillMailCompose(tester);
  final sendButton = tester.widget<YhButton>(
    find.widgetWithText(YhButton, '发送邮件'),
  );
  sendButton.onTap?.call();
}

Future<void> _prepareMailComposeLoading(WidgetTester tester) async {
  await _prepareMailComposeSending(tester);
  await tester.pump();
}

Future<void> _prepareMailComposeError(WidgetTester tester) async {
  await _prepareMailComposeSending(tester);
  await tester.pump();
  await tester.pump();
}

Future<void> _centerInScrollable(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
}

Future<void> _clearMailFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}

const _quickLinkGroups = <QuickLinkGroupConfig>[
  QuickLinkGroupConfig(
    category: '学习与教务',
    items: [
      QuickLinkItemConfig(
        name: '教务系统',
        url: 'https://academic.example.invalid',
        icon: 'education',
      ),
      QuickLinkItemConfig(
        name: '超星学习通',
        url: 'https://learning.example.invalid',
        icon: 'education',
      ),
    ],
  ),
  QuickLinkGroupConfig(
    category: '校园服务',
    items: [
      QuickLinkItemConfig(
        name: '图书馆',
        url: 'https://library.example.invalid',
        icon: 'library',
      ),
      QuickLinkItemConfig(
        name: '校园卡服务',
        url: 'https://card.example.invalid',
        icon: 'finance',
      ),
    ],
  ),
  QuickLinkGroupConfig(
    category: '学校信息',
    items: [
      QuickLinkItemConfig(
        name: '学校官网',
        url: 'https://www.example.invalid',
        icon: 'globe',
      ),
      QuickLinkItemConfig(
        name: '统一身份认证',
        url: 'https://sso.example.invalid',
        icon: 'security',
      ),
    ],
  ),
];

Widget _quickLinksContent() => QuickLinksPage(
  groupsLoader: () async => _quickLinkGroups,
  onOpenUrl: (_) async {},
);

Widget _quickLinksLoading() {
  final pending = Completer<List<QuickLinkGroupConfig>>();
  return QuickLinksPage(groupsLoader: () => pending.future);
}

Widget _quickLinksEmpty() => QuickLinksPage(groupsLoader: () async => const []);

Widget _quickLinksError() => QuickLinksPage(
  groupsLoader: () => Future.error(StateError('fixture load failed')),
);

Widget _externalLinkConfirmationContent() => ExternalLinkConfirmationPage(
  displayName: '统一身份认证',
  uri: Uri.parse('https://auth.example.invalid/login'),
  authenticationRequired: true,
  authenticationReady: true,
);

Widget _externalLinkConfirmationError() => ExternalLinkConfirmationPage(
  displayName: '统一身份认证',
  uri: Uri.parse('https://auth.example.invalid/login'),
  authenticationRequired: true,
  authenticationReady: false,
);

Widget _panel(String title, List<Widget> children) => YhPageScaffold(
  appBar: YhAppBar(title: title),
  body: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.all(context.yhTheme.spacing.l),
      child: Wrap(
        spacing: context.yhTheme.spacing.m,
        runSpacing: context.yhTheme.spacing.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    ),
  ),
);

Widget _actionsPanel() => _panel('操作组件', [
  YhButton(label: '主要操作', onTap: () {}),
  YhButton(label: '次要操作', variant: YhButtonVariant.secondary, onTap: () {}),
  const YhButton(label: '禁用操作', disabled: true),
  YhIconButton(icon: YhIcons.refresh, semanticLabel: '刷新', onTap: () {}),
  YhFab(icon: YhIcons.add, semanticLabel: '新建', label: '新建', onTap: () {}),
  YhSegmented<String>(
    options: const [
      YhSegmentedOption(value: 'day', label: '日'),
      YhSegmentedOption(value: 'week', label: '周'),
      YhSegmentedOption(value: 'month', label: '月'),
    ],
    value: 'week',
    onChanged: (_) {},
  ),
  YhChip(label: '已选择', selected: true, onTap: () {}),
  YhChip(label: '筛选项', onTap: () {}),
  YhSwitch(value: true, semanticLabel: '通知', onChanged: (_) {}),
  YhCheckbox(label: '同意协议', value: true, onChanged: (_) {}),
  YhRadio<String>(
    label: '校内服务',
    value: 'campus',
    groupValue: 'campus',
    onChanged: (_) {},
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhSlider(value: 0.68, label: '透明度', onChanged: (_) {}),
  ),
  SizedBox(
    width: YhTheme.light.layout.formContentWidth,
    child: YhStepper(
      steps: const ['填写', '确认', '完成'],
      currentStep: 1,
      onStepSelected: (_) {},
    ),
  ),
]);

Widget _inputsPanel() => _panel('输入组件', [
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhTextField(label: '姓名', hint: '请输入姓名'),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhSearch(hint: '搜索课程、邮件或资讯'),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhTextarea(label: '备注', hint: '补充说明', maxLines: 3),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhSelect<String>(
      label: '学期',
      options: const [
        YhSelectOption(value: '2026-summer', label: '2026 夏季学期'),
        YhSelectOption(value: '2026-spring', label: '2026 春季学期'),
      ],
      value: '2026-summer',
      onChanged: (_) {},
    ),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhDatePicker(label: '查询日期', value: '2026-07-19', onTap: () {}),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: YhOtp(controller: TextEditingController(text: '260719')),
  ),
  SizedBox(
    width: YhTheme.light.layout.formFieldWidth,
    child: const YhTextField(label: '邮箱', errorText: '邮箱格式不正确'),
  ),
]);

Widget _feedbackPanel() => _panel('容器与反馈', [
  const SizedBox(width: 260, child: YhCard(child: Text('用于组织关联内容的清源卡片'))),
  const SizedBox(width: 260, child: YhTile(child: Text('可选择的内容磁贴'))),
  const SizedBox(
    width: 320,
    child: YhListItem(title: '校园通知', subtitle: '刚刚更新'),
  ),
  const SizedBox(
    width: 420,
    child: YhAccordion(
      title: '查看说明',
      content: Text('折叠内容遵循清源间距与焦点规范。'),
      initiallyExpanded: true,
    ),
  ),
  const SizedBox(width: 420, child: YhBanner(text: '数据已在 09:30 更新')),
  const YhToast(message: '设置已保存', actionLabel: '撤销'),
  const SizedBox(width: 320, child: YhSkeleton()),
  const SizedBox(
    width: 360,
    child: YhEmptyState(
      icon: YhIcons.inbox,
      title: '暂无内容',
      message: '完成同步后将在这里显示。',
    ),
  ),
  YhDialog(
    title: '确认操作',
    content: const Text('该操作会更新本地显示设置。'),
    actions: [
      YhButton(label: '取消', variant: YhButtonVariant.secondary, onTap: () {}),
      YhButton(label: '确认', onTap: () {}),
    ],
  ),
]);

Widget _navigationPanel() => _panel('导航组件', [
  SizedBox(
    width: YhTheme.light.layout.formContentWidth,
    child: YhTabs<String>(
      tabs: const [
        YhTab(value: 'overview', label: '总览', icon: YhIcons.home),
        YhTab(value: 'detail', label: '详情', icon: YhIcons.info),
      ],
      value: 'overview',
      onChanged: (_) {},
    ),
  ),
  YhPagination(page: 3, pageCount: 8, onChanged: (_) {}),
  SizedBox(
    width: YhTheme.light.layout.formContentWidth,
    child: YhBottomNav(
      items: const [
        YhNavigationItem(icon: YhIcons.home, label: '主页'),
        YhNavigationItem(icon: YhIcons.academic, label: '教务'),
        YhNavigationItem(icon: YhIcons.calendar, label: '课表'),
      ],
      index: 0,
      onChanged: (_) {},
    ),
  ),
  SizedBox(
    height: YhTheme.light.layout.bottomNavigationHeight * 4,
    child: YhNavRail(
      items: const [
        YhNavigationItem(icon: YhIcons.home, label: '主页'),
        YhNavigationItem(icon: YhIcons.settings, label: '设置'),
      ],
      index: 0,
      onChanged: (_) {},
    ),
  ),
]);

Widget _dataPanel() => _panel('数据展示', [
  const YhBadge(label: '12'),
  const YhStatusPill(label: '运行正常', kind: YhStatusKind.success),
  const YhStatusPill(label: '需要关注', kind: YhStatusKind.warning),
  const YhAvatar(semanticLabel: '清源用户', initials: '清'),
  const SizedBox(
    width: 260,
    child: YhMetricCard(label: '平均绩点', value: '3.82', caption: '较上学期 +0.12'),
  ),
  const SizedBox(width: 260, child: YhProgress(value: 0.76)),
  const YhRing(value: 0.82, label: '培养进度'),
  const SizedBox(
    width: 420,
    child: YhFeedItem(
      title: '夏季学期选课确认',
      summary: '请在规定时间内登录教务系统确认选课结果。',
      source: '教务处',
      timestamp: '09:30',
    ),
  ),
  const YhSourceBadge(label: '学校官网', icon: YhIcons.globe),
]);

Widget _domainPanel() => _panel('校园域组件', [
  const SizedBox(
    width: 360,
    child: YhTodayCard(
      title: '今天',
      subtitle: '7 月 19 日 · 星期日',
      child: Text('2 节课程 · 1 项待办'),
    ),
  ),
  const SizedBox(
    width: 300,
    child: YhCourseBlock(
      name: '高等数学',
      time: '08:00–09:35',
      location: '教学楼 310',
    ),
  ),
  const SizedBox(
    width: 360,
    child: YhAiMessage(
      message: '已为你整理今天的课程与待办。',
      role: YhMessageRole.assistant,
    ),
  ),
  const SizedBox(
    width: 280,
    child: YhBalanceModule(
      label: '校园卡余额',
      balance: '¥ 88.00',
      caption: '更新于 09:30',
    ),
  ),
  SizedBox(
    width: 220,
    child: YhQuickLink(
      icon: YhIcons.library,
      label: '图书馆',
      subtitle: '馆藏与借阅',
      color: YhTheme.light.color.serviceQuickLink,
      onTap: () {},
    ),
  ),
  const SizedBox(
    width: 360,
    child: YhAttendanceItem(
      title: '体育考勤',
      detail: '操场 · 07:30',
      status: '已签到',
      kind: YhStatusKind.success,
    ),
  ),
]);
