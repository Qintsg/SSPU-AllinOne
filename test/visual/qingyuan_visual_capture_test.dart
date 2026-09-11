/*
 * 清源 Flutter 视觉候选采集 — 四档视口、亮暗主题与全量状态面板
 * @Project : SSPU-AllinOne
 * @File : qingyuan_visual_capture_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

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
import 'package:sspu_allinone/models/academic_term.dart';
import 'package:sspu_allinone/models/academic_credentials.dart';
import 'package:sspu_allinone/models/academic_eams.dart';
import 'package:sspu_allinone/models/email_mailbox.dart';
import 'package:sspu_allinone/models/sports_attendance.dart';
import 'package:sspu_allinone/models/student_report.dart';
import 'package:sspu_allinone/pages/about_page.dart';
import 'package:sspu_allinone/pages/ai_services_page.dart';
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
import 'package:sspu_allinone/pages/settings_about_page.dart';
import 'package:sspu_allinone/pages/settings_data_privacy_page.dart';
import 'package:sspu_allinone/pages/settings_page.dart';
import 'package:sspu_allinone/pages/settings_wechat_auth_page.dart';
import 'package:sspu_allinone/pages/wxmp_login_page.dart';
import 'package:sspu_allinone/pages/settings_update_page.dart';
import 'package:sspu_allinone/pages/webview_page_frame.dart';
import 'package:sspu_allinone/services/system_auth_service.dart';
import 'package:sspu_allinone/services/app_update_service.dart';
import 'package:sspu_allinone/services/quick_links_config_service.dart';
import 'package:sspu_allinone/services/campus_network_status_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';
import 'package:sspu_allinone/services/academic_term_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';
import 'package:sspu_allinone/widgets/app_close_confirmation_dialog.dart';
import 'package:sspu_allinone/widgets/app_more_destinations.dart';
import 'package:sspu_allinone/widgets/app_startup_status.dart';
import 'package:sspu_allinone/widgets/legal_consent_dialog.dart';
import 'package:sspu_allinone/widgets/password_dialogs.dart';
import 'package:sspu_allinone/widgets/settings_security_section.dart'
    show SettingsDataPrivacyState;
import 'package:sspu_allinone/widgets/settings_data_privacy_confirmation_dialogs.dart';
import 'package:sspu_allinone/widgets/settings_wechat_config_dialog.dart';
import 'package:sspu_allinone/widgets/settings_wechat_auth_status_card.dart';

import '../support/qingyuan_visual_fixtures.dart';
import 'qingyuan_component_visual_panels.dart';

part 'qingyuan_visual_surfaces_global.dart';
part 'qingyuan_visual_surfaces_academic.dart';
part 'qingyuan_visual_surfaces_content.dart';
part 'qingyuan_visual_surfaces_settings_external.dart';
part 'qingyuan_visual_fixtures_settings.dart';
part 'qingyuan_visual_fixtures_external.dart';
part 'qingyuan_visual_fixtures_global.dart';
part 'qingyuan_visual_fixtures_academic.dart';
part 'qingyuan_visual_fixtures_content.dart';

const _captureEnabled = bool.fromEnvironment('QINGYUAN_VISUAL_CAPTURE');
const _deviceCapture = bool.fromEnvironment('QINGYUAN_VISUAL_DEVICE_CAPTURE');
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

/// 注册清源视觉矩阵的确定性采集测试。
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
          if (!_deviceCapture) {
            debugDefaultTargetPlatformOverride = _targetPlatform;
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = viewport;
          }
          try {
            final output = Directory('build/visual/$_platform');
            if (!_deviceCapture) output.createSync(recursive: true);
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
              RepaintBoundary(
                key: boundaryKey,
                child: YhApp(
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
            await surface.cleanup?.call(tester);
          } finally {
            if (!_deviceCapture) {
              debugDefaultTargetPlatformOverride = null;
              tester.view.resetDevicePixelRatio();
              tester.view.resetPhysicalSize();
            }
            await tester.binding.setSurfaceSize(null);
          }
        }, skip: !_captureEnabled);
      }
    }
  }
}

/// 解析 _targetPlatform 使用的确定性视觉测试值。
///
/// :returns: 对应的确定性测试值。
TargetPlatform get _targetPlatform => switch (_platform) {
  'android' => TargetPlatform.android,
  'ios' => TargetPlatform.iOS,
  'macos' => TargetPlatform.macOS,
  'linux' => TargetPlatform.linux,
  _ => TargetPlatform.windows,
};

/// 准备 _loadVisualFonts 对应的确定性视觉状态。
///
/// :returns: 视觉状态准备完成时结束。
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

/// 准备 _capture 对应的确定性视觉状态。
///
/// :param tester: 当前视觉场景输入。
/// :param boundaryKey: 当前视觉场景输入。
/// :param target: 当前视觉场景输入。
/// :param viewport: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
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
  await _writeVisualArtifact(target.path, result.bytes);
  expect(result.bytes, isNotEmpty);
}

/// 准备 _writeExternalRegionSidecar 对应的确定性视觉状态。
///
/// :param viewport: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
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
  final sidecar = const JsonEncoder.withIndent('  ').convert({
    'externalRegions': [
      {
        'id': regionId,
        'x': rect.left.round(),
        'y': rect.top.round(),
        'width': rect.width.round(),
        'height': rect.height.round(),
      },
    ],
  });
  await _writeVisualArtifact(
    '${target.path}.regions.json',
    Uint8List.fromList(utf8.encode('$sidecar\n')),
  );
}

/// 准备 _writeVisualArtifact 对应的确定性视觉状态。
///
/// :param path: 当前视觉场景输入。
/// :param bytes: 当前视觉场景输入。
/// :returns: 视觉状态准备完成时结束。
Future<void> _writeVisualArtifact(String path, Uint8List bytes) async {
  if (_deviceCapture) {
    final hostRelativePath = '../${path.replaceAll('\\', '/')}';
    await goldenFileComparator.update(Uri.parse(hostRelativePath), bytes);
    return;
  }
  final target = File(path);
  target.parent.createSync(recursive: true);
  target.writeAsBytesSync(bytes, flush: true);
}

class _CapturedPng {
  /// 创建包含尺寸与编码字节的视觉截图结果。
  ///
  /// :param width: 截图像素宽度。
  /// :param height: 截图像素高度。
  /// :param bytes: PNG 编码字节。
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
  /// 注册单个视觉 surface 及其确定性准备动作。
  ///
  /// :param id: 视觉清单 surface 标识。
  /// :param builder: 生产页面构建器。
  /// :param state: 当前页面状态。
  /// :param prepare: 截图前准备动作。
  /// :param cleanup: 截图后清理动作。
  /// :param destination: 应用壳目的地。
  /// :param externalRegionId: 外部区域标识。
  /// :param externalRegionKey: 外部区域定位键。
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

/// 解析 _destinationIndex 使用的确定性视觉测试值。
///
/// :param destination: 当前视觉场景输入。
/// :returns: 对应的确定性测试值。
int _destinationIndex(String destination) => switch (destination) {
  '主页' => 0,
  '教务' => 1,
  '课表' => 2,
  '信息' => 3,
  '邮箱' => 4,
  '跳转' => 5,
  '设置' => 6,
  'AI 服务' => 7,
  _ => throw ArgumentError.value(destination, 'destination'),
};

final _surfaces = <_VisualSurface>[
  ..._globalAndHomeSurfaces,
  ..._academicSurfaces,
  ..._contentSurfaces,
  ..._settingsAndExternalSurfaces,
];
