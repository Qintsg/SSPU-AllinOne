/*
 * 设置页应用更新组件测试 — 校验下载、取消、校验状态与窄屏布局
 * @Project : SSPU-AllinOne
 * @File : settings_update_section_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-09
 */

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:dio/dio.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/app_update_service.dart';
import 'package:sspu_allinone/widgets/settings_update_section.dart';

void main() {
  Future<void> pumpUpdateSection(
    WidgetTester tester, {
    required _FakeAppUpdateService service,
    Future<bool> Function(Uri uri)? launchUrlOverride,
    Size? surfaceSize,
    bool taskPage = false,
  }) async {
    if (surfaceSize != null) {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(surfaceSize);
    }
    final section = SettingsUpdateSection(
      updateService: service,
      launchUrlOverride: launchUrlOverride,
      taskPage: taskPage,
    );
    await tester.pumpWidget(
      YhApp(
        home: taskPage
            ? section
            : YhPageScaffold(body: SingleChildScrollView(child: section)),
      ),
    );
  }

  Future<void> resetView(WidgetTester tester) async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('显示下载进度并可取消下载', (tester) async {
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(),
      downloadHandler:
          (
            release,
            asset, {
            required cancelToken,
            required onReceiveProgress,
          }) async {
            onReceiveProgress(
              const AppUpdateDownloadProgress(received: 512, total: 1024),
            );
            await cancelToken.whenCancel;
            return AppUpdateDownloadResult(
              status: AppUpdateDownloadStatus.canceled,
              asset: asset,
              filePath: null,
              message: '下载已取消。',
              actualSha256: null,
            );
          },
    );

    await pumpUpdateSection(tester, service: service);
    await tapLastText(tester, '检查更新');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('下载并校验'));
    await tester.pump();

    expect(find.text('下载中'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('512 B / 1.0 KB'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.widgetWithText(YhButton, '检查更新'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.widgetWithText(YhButton, '正式版'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('下载已取消。'), findsOneWidget);
    expect(find.text('打开安装入口'), findsNothing);
  });

  testWidgets('校验失败时显示错误提示且不显示打开安装入口', (tester) async {
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(),
      downloadHandler:
          (
            release,
            asset, {
            required cancelToken,
            required onReceiveProgress,
          }) async {
            return AppUpdateDownloadResult(
              status: AppUpdateDownloadStatus.failed,
              asset: asset,
              filePath: null,
              message: '安装包校验失败，请重新下载。',
              actualSha256: 'bad',
            );
          },
    );

    await pumpUpdateSection(tester, service: service);
    await tapLastText(tester, '检查更新');
    await tester.pump();
    await tester.tap(find.text('下载并校验'));
    await tester.pumpAndSettle();

    expect(find.text('安装包校验失败，请重新下载。'), findsOneWidget);
    expect(find.text('打开安装入口'), findsNothing);
  });

  testWidgets('校验通过后才显示打开安装入口并可触发打开', (tester) async {
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(),
      downloadHandler:
          (
            release,
            asset, {
            required cancelToken,
            required onReceiveProgress,
          }) async {
            return AppUpdateDownloadResult(
              status: AppUpdateDownloadStatus.verified,
              asset: asset,
              filePath: 'C:/temp/installer.exe',
              message: '安装包校验通过。',
              actualSha256: _hash,
            );
          },
      openResult: const AppUpdateOpenResult(
        status: AppUpdateOpenStatus.opened,
        message: '已打开安装入口，请按系统提示完成安装。',
      ),
    );

    await pumpUpdateSection(tester, service: service);
    await tapLastText(tester, '检查更新');
    await tester.pump();
    await tester.tap(find.text('下载并校验'));
    await tester.pumpAndSettle();

    expect(find.text('安装包校验通过。'), findsOneWidget);
    expect(find.text('打开安装入口'), findsOneWidget);

    await tester.tap(find.text('打开安装入口'));
    await tester.pumpAndSettle();

    expect(service.openCalls, 1);
    expect(find.text('已打开安装入口，请按系统提示完成安装。'), findsOneWidget);
  });

  testWidgets('不支持本地安装的平台展示提示并保留 Release 入口', (tester) async {
    final openedUrls = <Uri>[];
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(
        message: '发现新版本 1.2.0，当前平台不支持应用内安装。',
        resolvedAsset: _resolvedAsset(
          installSupport: AppUpdateInstallSupport.unsupported,
        ),
      ),
    );

    await pumpUpdateSection(
      tester,
      service: service,
      launchUrlOverride: (uri) async {
        openedUrls.add(uri);
        return true;
      },
    );
    await tapLastText(tester, '检查更新');
    await tester.pumpAndSettle();

    expect(find.text('打开 Release'), findsOneWidget);
    expect(find.text('下载并校验'), findsNothing);
    expect(
      find.text('当前平台不支持在应用内打开本地安装入口，请使用 GitHub Release 页面下载。'),
      findsOneWidget,
    );

    await tester.tap(find.text('打开 Release'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(openedUrls.single.toString(), _release.htmlUrl);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('窄屏下按钮与长文件名不溢出', (tester) async {
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(
        resolvedAsset: _resolvedAsset(
          name:
              'SSPU-AllinOne-v1.2.0-windows-x64-installer-with-a-very-long-name.exe',
        ),
      ),
    );

    try {
      await pumpUpdateSection(
        tester,
        service: service,
        surfaceSize: const Size(320, 720),
      );
      await tapLastText(tester, '检查更新');
      await tester.pumpAndSettle();

      expect(find.text('打开 Release'), findsOneWidget);
      expect(find.text('下载并校验'), findsOneWidget);
      expect(find.textContaining('推荐资产：SSPU-AllinOne'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetView(tester);
    }
  });

  testWidgets('取消下载后保留 Release 并可直接重试', (tester) async {
    var downloadAttempt = 0;
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(),
      downloadHandler:
          (
            release,
            asset, {
            required cancelToken,
            required onReceiveProgress,
          }) async {
            downloadAttempt += 1;
            if (downloadAttempt == 1) {
              await cancelToken.whenCancel;
              return AppUpdateDownloadResult(
                status: AppUpdateDownloadStatus.canceled,
                asset: asset,
                filePath: null,
                message: '下载已取消。',
                actualSha256: null,
              );
            }
            return AppUpdateDownloadResult(
              status: AppUpdateDownloadStatus.verified,
              asset: asset,
              filePath: 'C:/temp/installer.exe',
              message: '安装包校验通过。',
              actualSha256: _hash,
            );
          },
    );

    await pumpUpdateSection(tester, service: service);
    await tapLastText(tester, '检查更新');
    await tester.pump();
    await tester.tap(find.text('下载并校验'));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('下载已取消。'), findsOneWidget);
    expect(find.text('打开 Release'), findsOneWidget);
    await tester.tap(find.text('下载并校验'));
    await tester.pumpAndSettle();
    expect(find.text('安装包校验通过。'), findsOneWidget);
    expect(downloadAttempt, 2);
  });

  testWidgets('Release 外部打开失败保留结果并显示重试反馈', (tester) async {
    final service = _FakeAppUpdateService(checkResult: _availableResult());
    await pumpUpdateSection(
      tester,
      service: service,
      launchUrlOverride: (_) async => false,
    );
    await tapLastText(tester, '检查更新');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('打开 Release'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开 Release'));
    await tester.pumpAndSettle();

    expect(find.textContaining('系统未能打开 Release'), findsOneWidget);
    expect(find.text('打开 Release'), findsOneWidget);
    expect(find.text('下载并校验'), findsOneWidget);
  });

  testWidgets('缺少校验值时不暴露当地安装入口', (tester) async {
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(
        resolvedAsset: _resolvedAsset(sha256: null),
      ),
    );
    await pumpUpdateSection(tester, service: service);
    await tapLastText(tester, '检查更新');
    await tester.pumpAndSettle();

    expect(find.textContaining('未找到 SHA-256'), findsOneWidget);
    expect(find.text('下载并校验'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.widgetWithText(YhButton, '下载并校验'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(find.text('打开安装入口'), findsNothing);
  });

  testWidgets('打开安装入口时锁定检查与渠道操作', (tester) async {
    final openCompleter = Completer<AppUpdateOpenResult>();
    final service = _FakeAppUpdateService(
      checkResult: _availableResult(),
      openHandler: (_) => openCompleter.future,
    );

    await pumpUpdateSection(tester, service: service);
    await tapLastText(tester, '检查更新');
    await tester.pump();
    await tester.tap(find.text('下载并校验'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开安装入口'));
    await tester.pump();

    expect(
      tester
          .getSemantics(find.widgetWithText(YhButton, '检查更新'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.widgetWithText(YhButton, '测试版'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    openCompleter.complete(
      const AppUpdateOpenResult(
        status: AppUpdateOpenStatus.opened,
        message: '已打开安装入口。',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('已打开安装入口。'), findsOneWidget);
  });

  testWidgets('任务页打开 Release 期间锁定其它操作且失败不冒充检查失败', (tester) async {
    final launchCompleter = Completer<bool>();
    final service = _FakeAppUpdateService(checkResult: _availableResult());
    await pumpUpdateSection(
      tester,
      service: service,
      taskPage: true,
      launchUrlOverride: (_) => launchCompleter.future,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('检查更新'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('打开 Release'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开 Release'));
    await tester.pump();

    expect(find.text('打开中'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('检查更新'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    launchCompleter.complete(false);
    await tester.pumpAndSettle();

    expect(find.textContaining('系统未能打开 Release'), findsOneWidget);
    expect(find.textContaining('无法从 GitHub Releases 完成本次检查'), findsNothing);
    expect(find.text('打开 Release'), findsOneWidget);
  });

  testWidgets('仅替换外链启动器时保留版本结果并隔离旧打开结果', (tester) async {
    final oldLaunch = Completer<bool>();
    final service = _FakeAppUpdateService(checkResult: _availableResult());
    await pumpUpdateSection(
      tester,
      service: service,
      taskPage: true,
      launchUrlOverride: (_) => oldLaunch.future,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('检查更新'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('打开 Release'));
    await tester.tap(find.text('打开 Release'));
    await tester.pump();

    await pumpUpdateSection(
      tester,
      service: service,
      taskPage: true,
      launchUrlOverride: (_) async => true,
    );
    await tester.pump();

    expect(find.text('当前版本 1.0.0'), findsOneWidget);
    expect(find.textContaining('发现新版本 1.2.0'), findsOneWidget);
    expect(find.text('打开中'), findsNothing);

    oldLaunch.complete(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('系统未能打开 Release'), findsNothing);
    expect(find.text('当前版本 1.0.0'), findsOneWidget);
  });
}

/// 点击最后一个匹配文本，避开设置项标题与按钮标签重名。
Future<void> tapLastText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
}

typedef _FakeDownloadHandler =
    Future<AppUpdateDownloadResult> Function(
      AppReleaseInfo release,
      AppUpdateResolvedAsset asset, {
      required CancelToken cancelToken,
      required void Function(AppUpdateDownloadProgress progress)
      onReceiveProgress,
    });

typedef _FakeOpenHandler =
    Future<AppUpdateOpenResult> Function(AppUpdateDownloadResult result);

class _FakeAppUpdateService extends AppUpdateService {
  _FakeAppUpdateService({
    required this.checkResult,
    this.downloadHandler,
    this.openHandler,
    this.openResult = const AppUpdateOpenResult(
      status: AppUpdateOpenStatus.opened,
      message: '已打开安装入口，请按系统提示完成安装。',
    ),
  }) : super(runtimePlatform: _windowsPlatform);

  final AppUpdateCheckResult checkResult;
  final _FakeDownloadHandler? downloadHandler;
  final _FakeOpenHandler? openHandler;
  final AppUpdateOpenResult openResult;
  int openCalls = 0;

  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) async {
    return checkResult;
  }

  @override
  Future<AppUpdateDownloadResult> downloadAndVerify(
    AppReleaseInfo release,
    AppUpdateResolvedAsset resolvedAsset, {
    required CancelToken cancelToken,
    required void Function(AppUpdateDownloadProgress progress)
    onReceiveProgress,
  }) async {
    final handler = downloadHandler;
    if (handler != null) {
      return handler(
        release,
        resolvedAsset,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    }
    return AppUpdateDownloadResult(
      status: AppUpdateDownloadStatus.verified,
      asset: resolvedAsset,
      filePath: 'C:/temp/installer.exe',
      message: '安装包校验通过。',
      actualSha256: _hash,
    );
  }

  @override
  Future<AppUpdateOpenResult> openVerifiedDownload(
    AppUpdateDownloadResult result,
  ) async {
    openCalls += 1;
    final handler = openHandler;
    if (handler != null) return handler(result);
    return openResult;
  }
}

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _windowsPlatform = AppUpdateRuntimePlatform(
  name: 'windows',
  arch: 'x64',
  supportsLocalFiles: true,
  supportsLocalInstall: true,
);
const _assetName = 'SSPU-AllinOne-v1.2.0-windows-x64-installer.exe';

final _release = AppReleaseInfo(
  title: 'SSPU-AllinOne v1.2.0',
  tagName: 'v1.2.0',
  version: '1.2.0',
  prerelease: false,
  htmlUrl: 'https://github.com/Qintsg/SSPU-AllinOne/releases/tag/v1.2.0',
  publishedAt: DateTime.utc(2026, 5, 18),
  assets: const [],
);

AppUpdateCheckResult _availableResult({
  String message = '发现新版本 1.2.0，可在应用内下载并校验安装包。',
  AppUpdateResolvedAsset? resolvedAsset,
}) {
  return AppUpdateCheckResult(
    status: AppUpdateStatus.available,
    currentVersion: '1.0.0',
    channel: AppUpdateChannel.stable,
    release: _release,
    recommendedAsset: resolvedAsset ?? _resolvedAsset(),
    message: message,
  );
}

AppUpdateResolvedAsset _resolvedAsset({
  String name = _assetName,
  AppUpdateInstallSupport installSupport = AppUpdateInstallSupport.supported,
  String? sha256 = _hash,
}) {
  return AppUpdateResolvedAsset(
    asset: AppUpdateAsset(
      name: name,
      downloadUrl: 'https://example.com/$name',
      size: 1048576,
    ),
    platform: 'windows',
    arch: 'x64',
    kind: 'installer',
    sha256: sha256,
    checksumSource: AppUpdateChecksumSource.manifest,
    installSupport: installSupport,
  );
}
