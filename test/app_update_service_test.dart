/*
 * 应用更新服务测试 — 校验版本比较、Release 解析、下载校验与打开入口
 * @Project : SSPU-AllinOne
 * @File : app_update_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/app_info_service.dart';
import 'package:sspu_allinone/services/app_update_service.dart';
import 'package:sspu_allinone/services/http_service.dart';

void main() {
  group('comparePublicVersions', () {
    test('按数字段和渠道顺序比较公开版本', () {
      expect(comparePublicVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(
        comparePublicVersions('1.0.0-beta', '1.0.0-alpha'),
        greaterThan(0),
      );
      expect(comparePublicVersions('1.0.0', '1.0.0-rc'), greaterThan(0));
      expect(comparePublicVersions('1.0.0+3', '1.0.0+1'), 0);
      expect(comparePublicVersions('1.0.0.1-hotfix', '1.0.0'), greaterThan(0));
    });
  });

  test('AppReleaseInfo 从 GitHub Release JSON 提取公开版本与资产', () {
    final release = AppReleaseInfo.fromJson({
      'name': 'SSPU-AllinOne v1.2.0-beta',
      'tag_name': 'v1.2.0-beta',
      'prerelease': true,
      'html_url':
          'https://github.com/Qintsg/SSPU-AllinOne/releases/tag/v1.2.0-beta',
      'published_at': '2026-05-18T00:00:00Z',
      'assets': [
        {
          'name': 'SSPU-AllinOne-v1.2.0-beta-windows-x64-installer.exe',
          'browser_download_url': 'https://example.com/installer.exe',
          'size': 10485760,
          'digest': 'sha256:${_sha256OfText('installer')}',
        },
      ],
    });

    expect(release.version, '1.2.0-beta');
    expect(release.prerelease, isTrue);
    expect(release.assets.single.displaySize, '10.0 MB');
    expect(release.assets.single.digest, startsWith('sha256:'));
  });

  group('Release 校验值解析', () {
    test('解析 manifest.json 中的资产元数据', () {
      final manifest = jsonEncode({
        'platforms': [
          {
            'platform': 'windows',
            'arch': 'x64',
            'kind': 'installer',
            'filename': _windowsX64Installer,
            'sha256': _hashA,
          },
          {
            'platform': 'web',
            'arch': 'universal',
            'kind': 'static',
            'filename': 'SSPU-AllinOne-v1.2.0-web-universal-static.zip',
            'sha256': _hashB,
          },
        ],
      });

      final parsed = parseManifestAssets(manifest);

      expect(parsed[_windowsX64Installer]?.platform, 'windows');
      expect(parsed[_windowsX64Installer]?.arch, 'x64');
      expect(parsed[_windowsX64Installer]?.kind, 'installer');
      expect(parsed[_windowsX64Installer]?.sha256, _hashA);
    });

    test('解析 SHA256SUMS.txt 中的 GNU 风格校验行', () {
      final parsed = parseSha256Sums(
        '$_hashA  $_windowsX64Installer\n'
        '$_hashB  *SSPU-AllinOne-v1.2.0-linux-x64-appimage.AppImage\n'
        'not-a-checksum  ignored\n',
      );

      expect(parsed[_windowsX64Installer], _hashA);
      expect(
        parsed['SSPU-AllinOne-v1.2.0-linux-x64-appimage.AppImage'],
        _hashB,
      );
      expect(parsed, hasLength(2));
    });
  });

  group('推荐资产选择', () {
    test('Windows x64 和 arm64 严格分流，并优先 installer', () {
      final x64Service = _buildService(platform: _windowsX64Platform);
      final arm64Service = _buildService(platform: _windowsArm64Platform);
      final assets = _assets([
        _windowsX64Portable,
        _windowsArm64Installer,
        _windowsX64Installer,
        _windowsArm64Portable,
        'manifest.json',
        'SHA256SUMS.txt',
        'SSPU-AllinOne-v1.2.0-web-universal-static.zip',
        'SSPU-AllinOne-v1.2.0-android-universal.aab',
      ]);

      expect(
        x64Service.selectRecommendedAsset(assets)?.name,
        _windowsX64Installer,
      );
      expect(
        arm64Service.selectRecommendedAsset(assets)?.name,
        _windowsArm64Installer,
      );
    });

    test('Windows 没有 installer 时使用 portable 备选', () {
      final service = _buildService(platform: _windowsX64Platform);

      final selected = service.selectRecommendedAsset(
        _assets([_windowsX64Portable]),
      );

      expect(selected?.name, _windowsX64Portable);
    });

    test('macOS、Linux、Android 按平台默认优先级推荐', () {
      final macService = _buildService(platform: _macosPlatform);
      final linuxService = _buildService(platform: _linuxX64Platform);
      final androidService = _buildService(platform: _androidPlatform);
      final assets = _assets([
        'SSPU-AllinOne-v1.2.0-macos-universal-unsigned.dmg',
        'SSPU-AllinOne-v1.2.0-linux-x64-rpm.rpm',
        'SSPU-AllinOne-v1.2.0-linux-x64-deb.deb',
        'SSPU-AllinOne-v1.2.0-linux-x64-appimage.AppImage',
        'SSPU-AllinOne-v1.2.0-linux-x64-portable.tar.gz',
        'SSPU-AllinOne-v1.2.0-android-universal.apk',
      ]);

      expect(
        macService.selectRecommendedAsset(assets)?.name,
        'SSPU-AllinOne-v1.2.0-macos-universal-unsigned.dmg',
      );
      expect(
        linuxService.selectRecommendedAsset(assets)?.name,
        'SSPU-AllinOne-v1.2.0-linux-x64-appimage.AppImage',
      );
      expect(
        androidService.selectRecommendedAsset(assets)?.name,
        'SSPU-AllinOne-v1.2.0-android-universal.apk',
      );
    });

    test('manifest 校验优先，其次 SHA256SUMS，再退回 GitHub digest', () async {
      final service = _buildService(
        platform: _windowsX64Platform,
        responses: {
          'https://example.com/manifest.json': jsonEncode({
            'platforms': [
              {
                'platform': 'windows',
                'arch': 'x64',
                'kind': 'installer',
                'filename': _windowsX64Installer,
                'sha256': _hashA,
              },
            ],
          }),
          'https://example.com/SHA256SUMS.txt':
              '$_hashB  $_windowsX64Installer\n',
        },
      );

      final resolved = await service.resolveRecommendedAsset(
        _releaseWithAssets([
          _asset('manifest.json'),
          _asset('SHA256SUMS.txt'),
          _asset(_windowsX64Installer, digest: 'sha256:$_hashC'),
        ]),
      );

      expect(resolved?.sha256, _hashA);
      expect(resolved?.checksumSource, AppUpdateChecksumSource.manifest);
    });

    test('manifest 失败时回退 SHA256SUMS，缺失时回退 digest', () async {
      final shaService = _buildService(
        platform: _windowsX64Platform,
        responses: {
          'https://example.com/manifest.json': 'not json',
          'https://example.com/SHA256SUMS.txt':
              '$_hashB  $_windowsX64Installer\n',
        },
      );
      final shaResolved = await shaService.resolveRecommendedAsset(
        _releaseWithAssets([
          _asset('manifest.json'),
          _asset('SHA256SUMS.txt'),
          _asset(_windowsX64Installer, digest: 'sha256:$_hashC'),
        ]),
      );
      final digestService = _buildService(
        platform: _windowsX64Platform,
        responses: {
          'https://example.com/manifest.json': 'not json',
          'https://example.com/SHA256SUMS.txt': '',
        },
      );
      final digestResolved = await digestService.resolveRecommendedAsset(
        _releaseWithAssets([
          _asset('manifest.json'),
          _asset('SHA256SUMS.txt'),
          _asset(_windowsX64Installer, digest: 'sha256:$_hashC'),
        ]),
      );

      expect(shaResolved?.sha256, _hashB);
      expect(shaResolved?.checksumSource, AppUpdateChecksumSource.sha256Sums);
      expect(digestResolved?.sha256, _hashC);
      expect(
        digestResolved?.checksumSource,
        AppUpdateChecksumSource.githubDigest,
      );
    });

    test('不支持本地安装的平台不推荐本地资产', () async {
      final service = _buildService(
        platform: const AppUpdateRuntimePlatform(
          name: 'web',
          arch: 'universal',
          supportsLocalFiles: false,
          supportsLocalInstall: false,
        ),
      );

      final resolved = await service.resolveRecommendedAsset(
        _releaseWithAssets([_asset(_windowsX64Installer)]),
      );

      expect(resolved, isNull);
    });
  });

  group('更新检查', () {
    test('stable 与 preview Release 按渠道筛选', () async {
      final service = _buildService(
        platform: _windowsX64Platform,
        currentVersion: '1.0.0+9',
        responses: {
          _releasesApiUrl: jsonEncode([
            _releaseJson('v1.1.0', prerelease: false),
            _releaseJson('v1.2.0-beta', prerelease: true),
          ]),
        },
      );

      final stable = await service.checkForUpdates(
        channel: AppUpdateChannel.stable,
      );
      final preview = await service.checkForUpdates(
        channel: AppUpdateChannel.preview,
      );

      expect(stable.release?.version, '1.1.0');
      expect(preview.release?.version, '1.2.0-beta');
      expect(stable.status, AppUpdateStatus.available);
      expect(preview.status, AppUpdateStatus.available);
    });
  });

  group('下载、校验与打开入口', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'app_update_service_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('SHA256 成功后保留文件，并允许打开安装入口', () async {
      final payload = utf8.encode('installer payload');
      final expectedSha = sha256.convert(payload).toString();
      final openedPaths = <String>[];
      final service = _buildService(
        platform: _windowsX64Platform,
        ensureDirectory: (_) async => tempDirectory.path,
        downloadFile:
            (
              url,
              savePath, {
              required cancelToken,
              required onReceiveProgress,
            }) async {
              onReceiveProgress(payload.length, payload.length);
              await File(savePath).writeAsBytes(payload);
            },
        openFile: (path) async {
          openedPaths.add(path);
          return const AppUpdateFileOpenResult(success: true, message: 'done');
        },
      );
      final resolved = _resolvedAsset(sha256Value: expectedSha);
      final progressEvents = <AppUpdateDownloadProgress>[];

      final result = await service.downloadAndVerify(
        _releaseWithAssets([resolved.asset]),
        resolved,
        cancelToken: CancelToken(),
        onReceiveProgress: progressEvents.add,
      );
      final openResult = await service.openVerifiedDownload(result);

      expect(result.isVerified, isTrue);
      expect(result.filePath, isNotNull);
      expect(await File(result.filePath!).exists(), isTrue);
      expect(progressEvents.single.percent, 1);
      expect(openResult.status, AppUpdateOpenStatus.opened);
      expect(openedPaths.single, result.filePath);
    });

    test('SHA256 失败后删除半成品并阻止打开入口', () async {
      final payload = utf8.encode('tampered payload');
      final service = _buildService(
        platform: _windowsX64Platform,
        ensureDirectory: (_) async => tempDirectory.path,
        downloadFile:
            (
              url,
              savePath, {
              required cancelToken,
              required onReceiveProgress,
            }) async {
              await File(savePath).writeAsBytes(payload);
            },
      );

      final result = await service.downloadAndVerify(
        _releaseWithAssets([_asset(_windowsX64Installer)]),
        _resolvedAsset(sha256Value: _hashA),
        cancelToken: CancelToken(),
        onReceiveProgress: (_) {},
      );
      final openResult = await service.openVerifiedDownload(result);

      expect(result.status, AppUpdateDownloadStatus.failed);
      expect(result.filePath, isNull);
      expect(tempDirectory.listSync().whereType<File>().toList(), isEmpty);
      expect(openResult.status, AppUpdateOpenStatus.notVerified);
    });

    test('缺失 SHA256 时不下载且不允许打开', () async {
      var downloadCalled = false;
      final service = _buildService(
        platform: _windowsX64Platform,
        ensureDirectory: (_) async => tempDirectory.path,
        downloadFile:
            (
              url,
              savePath, {
              required cancelToken,
              required onReceiveProgress,
            }) async {
              downloadCalled = true;
            },
      );

      final result = await service.downloadAndVerify(
        _releaseWithAssets([_asset(_windowsX64Installer)]),
        _resolvedAsset(sha256Value: null),
        cancelToken: CancelToken(),
        onReceiveProgress: (_) {},
      );

      expect(downloadCalled, isFalse);
      expect(result.status, AppUpdateDownloadStatus.failed);
      expect(result.message, contains('SHA-256'));
    });

    test('取消下载后删除半成品', () async {
      final service = _buildService(
        platform: _windowsX64Platform,
        ensureDirectory: (_) async => tempDirectory.path,
        downloadFile:
            (
              url,
              savePath, {
              required cancelToken,
              required onReceiveProgress,
            }) async {
              await File(savePath).writeAsString('partial');
              throw DioException(
                requestOptions: RequestOptions(path: url),
                type: DioExceptionType.cancel,
              );
            },
      );

      final result = await service.downloadAndVerify(
        _releaseWithAssets([_asset(_windowsX64Installer)]),
        _resolvedAsset(sha256Value: _hashA),
        cancelToken: CancelToken(),
        onReceiveProgress: (_) {},
      );

      expect(result.status, AppUpdateDownloadStatus.canceled);
      expect(tempDirectory.listSync().whereType<File>().toList(), isEmpty);
    });

    test('portable 压缩包打开所在目录，不直接打开压缩包', () async {
      final payload = utf8.encode('portable payload');
      final expectedSha = sha256.convert(payload).toString();
      final openedPaths = <String>[];
      final service = _buildService(
        platform: _windowsX64Platform,
        ensureDirectory: (_) async => tempDirectory.path,
        downloadFile:
            (
              url,
              savePath, {
              required cancelToken,
              required onReceiveProgress,
            }) async {
              await File(savePath).writeAsBytes(payload);
            },
        openFile: (path) async {
          openedPaths.add(path);
          return const AppUpdateFileOpenResult(success: true, message: 'done');
        },
      );
      final resolved = _resolvedAsset(
        name: _windowsX64Portable,
        sha256Value: expectedSha,
      );

      final result = await service.downloadAndVerify(
        _releaseWithAssets([resolved.asset]),
        resolved,
        cancelToken: CancelToken(),
        onReceiveProgress: (_) {},
      );
      final openResult = await service.openVerifiedDownload(result);

      expect(openResult.status, AppUpdateOpenStatus.opened);
      expect(openedPaths.single, tempDirectory.path);
    });

    test('Android APK 打开被拒绝时返回手动安装提示', () async {
      final service = _buildService(
        platform: _androidPlatform,
        openFile: (_) async => const AppUpdateFileOpenResult(
          success: false,
          message: 'permission denied',
        ),
      );
      final result = AppUpdateDownloadResult(
        status: AppUpdateDownloadStatus.verified,
        asset: _resolvedAsset(
          name: 'SSPU-AllinOne-v1.2.0-android-universal.apk',
          sha256Value: _hashA,
        ),
        filePath: '${tempDirectory.path}${Platform.pathSeparator}app.apk',
        message: null,
        actualSha256: _hashA,
      );

      final openResult = await service.openVerifiedDownload(result);

      expect(openResult.status, AppUpdateOpenStatus.failed);
      expect(openResult.message, contains('系统拒绝打开 APK'));
      expect(openResult.message, contains('permission denied'));
    });
  });
}

const _releasesApiUrl =
    'https://api.github.com/repos/Qintsg/SSPU-AllinOne/releases';
const _windowsX64Installer = 'SSPU-AllinOne-v1.2.0-windows-x64-installer.exe';
const _windowsArm64Installer =
    'SSPU-AllinOne-v1.2.0-windows-arm64-installer.exe';
const _windowsX64Portable = 'SSPU-AllinOne-v1.2.0-windows-x64-portable.zip';
const _windowsArm64Portable = 'SSPU-AllinOne-v1.2.0-windows-arm64-portable.zip';
const _hashA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hashB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _hashC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

const _windowsX64Platform = AppUpdateRuntimePlatform(
  name: 'windows',
  arch: 'x64',
  supportsLocalFiles: true,
  supportsLocalInstall: true,
);
const _windowsArm64Platform = AppUpdateRuntimePlatform(
  name: 'windows',
  arch: 'arm64',
  supportsLocalFiles: true,
  supportsLocalInstall: true,
);
const _macosPlatform = AppUpdateRuntimePlatform(
  name: 'macos',
  arch: 'universal',
  supportsLocalFiles: true,
  supportsLocalInstall: true,
);
const _linuxX64Platform = AppUpdateRuntimePlatform(
  name: 'linux',
  arch: 'x64',
  supportsLocalFiles: true,
  supportsLocalInstall: true,
);
const _androidPlatform = AppUpdateRuntimePlatform(
  name: 'android',
  arch: 'universal',
  supportsLocalFiles: true,
  supportsLocalInstall: true,
);

AppUpdateService _buildService({
  required AppUpdateRuntimePlatform platform,
  Map<String, String> responses = const {},
  String currentVersion = '1.0.0+1',
  AppUpdateDownloadFile? downloadFile,
  AppUpdateOpenFile? openFile,
  AppUpdateEnsureDirectory? ensureDirectory,
}) {
  final service = HttpService.instance;
  service.dio.httpClientAdapter = _FakeHttpAdapter(responses);
  return AppUpdateService(
    httpService: service,
    runtimePlatform: platform,
    downloadFile: downloadFile,
    openFile: openFile,
    ensureDirectory: ensureDirectory,
    loadVersionInfo: () async =>
        AppVersionInfo(version: currentVersion, buildNumber: ''),
  );
}

AppReleaseInfo _releaseWithAssets(List<AppUpdateAsset> assets) {
  return AppReleaseInfo(
    title: 'SSPU-AllinOne v1.2.0',
    tagName: 'v1.2.0',
    version: '1.2.0',
    prerelease: false,
    htmlUrl: 'https://github.com/Qintsg/SSPU-AllinOne/releases/tag/v1.2.0',
    publishedAt: DateTime.utc(2026, 5, 18),
    assets: assets,
  );
}

Map<String, dynamic> _releaseJson(String tag, {required bool prerelease}) {
  return {
    'name': 'SSPU-AllinOne $tag',
    'tag_name': tag,
    'prerelease': prerelease,
    'html_url': 'https://github.com/Qintsg/SSPU-AllinOne/releases/tag/$tag',
    'published_at': '2026-05-18T00:00:00Z',
    'assets': [
      {
        'name': _windowsX64Installer.replaceFirst('v1.2.0', tag),
        'browser_download_url': 'https://example.com/${tag}_installer.exe',
        'size': 1,
        'digest': 'sha256:$_hashA',
      },
    ],
  };
}

List<AppUpdateAsset> _assets(List<String> names) {
  return names.map(_asset).toList(growable: false);
}

AppUpdateAsset _asset(String name, {String? digest}) {
  return AppUpdateAsset(
    name: name,
    downloadUrl: 'https://example.com/$name',
    size: 1048576,
    digest: digest,
  );
}

AppUpdateResolvedAsset _resolvedAsset({
  String name = _windowsX64Installer,
  String? sha256Value = _hashA,
}) {
  final parsed = parseReleaseAssetName(name);
  return AppUpdateResolvedAsset(
    asset: _asset(name),
    platform: parsed?.platform ?? 'windows',
    arch: parsed?.arch ?? 'x64',
    kind: parsed?.kind ?? 'installer',
    sha256: sha256Value,
    checksumSource: sha256Value == null
        ? null
        : AppUpdateChecksumSource.manifest,
    installSupport: AppUpdateInstallSupport.supported,
  );
}

String _sha256OfText(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}

class _FakeHttpAdapter implements HttpClientAdapter {
  final Map<String, String> responses;

  const _FakeHttpAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    final hasResponse =
        responses.containsKey(url) || responses.containsKey(options.path);
    final content = responses[url] ?? responses[options.path] ?? '';
    if (!hasResponse) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      content,
      200,
      headers: {
        Headers.contentTypeHeader: [
          content.trimLeft().startsWith('[') ||
                  content.trimLeft().startsWith('{')
              ? Headers.jsonContentType
              : Headers.textPlainContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
