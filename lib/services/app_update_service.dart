/*
 * 应用更新服务 — 通过 GitHub Release 查询、下载、校验并打开安装入口
 * @Project : SSPU-AllinOne
 * @File : app_update_service.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

import 'app_data_directory_service.dart';
import 'app_info_service.dart';
import 'http_service.dart';

part 'app_update_models.dart';
part 'app_update_parsing.dart';

/// GitHub Release 更新检查服务。
class AppUpdateService {
  AppUpdateService({
    HttpService? httpService,
    AppInfoService? appInfoService,
    AppUpdateRuntimePlatform? runtimePlatform,
    AppUpdateDownloadFile? downloadFile,
    AppUpdateOpenFile? openFile,
    AppUpdateEnsureDirectory? ensureDirectory,
    AppUpdateLoadVersionInfo? loadVersionInfo,
  }) : _httpService = httpService ?? HttpService.instance,
       _appInfoService = appInfoService ?? AppInfoService.instance,
       _runtimePlatform = runtimePlatform ?? AppUpdateRuntimePlatform.current(),
       _downloadFile = downloadFile,
       _openFile = openFile,
       _ensureDirectory =
           ensureDirectory ?? AppDataDirectoryService.ensureDirectoryPath,
       _loadVersionInfo = loadVersionInfo;

  /// 默认服务实例。
  static final AppUpdateService instance = AppUpdateService();

  static const String _releasesApiUrl =
      'https://api.github.com/repos/Qintsg/SSPU-AllinOne/releases';

  final HttpService _httpService;
  final AppInfoService _appInfoService;
  final AppUpdateRuntimePlatform _runtimePlatform;
  final AppUpdateDownloadFile? _downloadFile;
  final AppUpdateOpenFile? _openFile;
  final AppUpdateEnsureDirectory _ensureDirectory;
  final AppUpdateLoadVersionInfo? _loadVersionInfo;

  /// 检查指定渠道是否存在可用更新。
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) async {
    final currentVersionInfo = await (_loadVersionInfo != null
        ? _loadVersionInfo()
        : _appInfoService.loadVersionInfo());
    final currentVersion = normalizeVersion(currentVersionInfo.version);
    final releases = await _fetchReleases();
    final release = _selectRelease(releases, channel);

    if (release == null) {
      return AppUpdateCheckResult(
        status: AppUpdateStatus.unavailable,
        currentVersion: currentVersion,
        channel: channel,
        release: null,
        recommendedAsset: null,
        message: '所选渠道暂无可用 Release。',
      );
    }

    final recommendedAsset = await resolveRecommendedAsset(release);
    final hasNewerVersion =
        comparePublicVersions(release.version, currentVersion) > 0;

    if (!hasNewerVersion) {
      return AppUpdateCheckResult(
        status: AppUpdateStatus.upToDate,
        currentVersion: currentVersion,
        channel: channel,
        release: release,
        recommendedAsset: recommendedAsset,
        message: '当前已是${_channelLabel(channel)}最新版本。',
      );
    }

    return AppUpdateCheckResult(
      status: AppUpdateStatus.available,
      currentVersion: currentVersion,
      channel: channel,
      release: release,
      recommendedAsset: recommendedAsset,
      message: recommendedAsset == null
          ? _runtimePlatform.supportsLocalInstall
                ? '发现新版本 ${release.version}，但未找到当前平台的安装包。'
                : '发现新版本 ${release.version}，当前平台不支持应用内安装。'
          : '发现新版本 ${release.version}，可在应用内下载并校验安装包。',
    );
  }

  /// 选择最适合当前平台的 Release 资产。
  ///
  /// 保留旧同步 API，适用于仅需要资产名称筛选的调用。
  AppUpdateAsset? selectRecommendedAsset(List<AppUpdateAsset> assets) {
    return _selectRecommendedAsset(
      assets,
      const _ReleaseChecksumIndex(manifestAssets: {}, sha256Sums: {}),
    );
  }

  /// 解析推荐资产及校验来源。
  Future<AppUpdateResolvedAsset?> resolveRecommendedAsset(
    AppReleaseInfo release,
  ) async {
    if (!_runtimePlatform.supportsLocalFiles) return null;
    final checksums = await _loadReleaseChecksums(release);
    final asset = _selectRecommendedAsset(release.assets, checksums);
    if (asset == null) return null;
    final parsed = parseReleaseAssetName(asset.name);
    final manifestAsset = checksums.manifestAssets[asset.name];
    final sha = checksums.resolveSha256(asset);
    return AppUpdateResolvedAsset(
      asset: asset,
      platform: manifestAsset?.platform ?? parsed?.platform ?? 'unknown',
      arch: manifestAsset?.arch ?? parsed?.arch ?? 'unknown',
      kind: manifestAsset?.kind ?? parsed?.kind ?? asset.kind.name,
      sha256: sha?.value,
      checksumSource: sha?.source,
      installSupport: _runtimePlatform.supportsLocalInstall
          ? AppUpdateInstallSupport.supported
          : AppUpdateInstallSupport.unsupported,
    );
  }

  /// 下载并校验推荐资产。
  Future<AppUpdateDownloadResult> downloadAndVerify(
    AppReleaseInfo release,
    AppUpdateResolvedAsset resolvedAsset, {
    required CancelToken cancelToken,
    required void Function(AppUpdateDownloadProgress progress)
    onReceiveProgress,
  }) async {
    if (!resolvedAsset.hasChecksum) {
      return AppUpdateDownloadResult(
        status: AppUpdateDownloadStatus.failed,
        asset: resolvedAsset,
        filePath: null,
        message: 'Release 未提供 ${resolvedAsset.asset.name} 的 SHA-256 校验值。',
        actualSha256: null,
      );
    }

    final directoryPath = await _ensureDirectory(
      'update_downloads${Platform.pathSeparator}${_safePathSegment(release.tagName)}',
    );
    final savePath =
        '$directoryPath${Platform.pathSeparator}${resolvedAsset.asset.name}';
    final saveFile = File(savePath);

    try {
      if (await saveFile.exists()) {
        await saveFile.delete();
      }
      await _download(
        resolvedAsset.asset.downloadUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          onReceiveProgress(
            AppUpdateDownloadProgress(received: received, total: total),
          );
        },
      );

      final actualSha256 = await sha256ForFile(saveFile);
      if (!_sameSha256(actualSha256, resolvedAsset.sha256!)) {
        await _deleteIfExists(saveFile);
        return AppUpdateDownloadResult(
          status: AppUpdateDownloadStatus.failed,
          asset: resolvedAsset,
          filePath: null,
          message: '安装包校验失败，请重新下载。',
          actualSha256: actualSha256,
        );
      }

      return AppUpdateDownloadResult(
        status: AppUpdateDownloadStatus.verified,
        asset: resolvedAsset,
        filePath: savePath,
        message: '安装包校验通过。',
        actualSha256: actualSha256,
      );
    } on DioException catch (error) {
      await _deleteIfExists(saveFile);
      if (error.type == DioExceptionType.cancel) {
        return AppUpdateDownloadResult(
          status: AppUpdateDownloadStatus.canceled,
          asset: resolvedAsset,
          filePath: null,
          message: '下载已取消。',
          actualSha256: null,
        );
      }
      return AppUpdateDownloadResult(
        status: AppUpdateDownloadStatus.failed,
        asset: resolvedAsset,
        filePath: null,
        message: HttpService.describeError(error),
        actualSha256: null,
      );
    } catch (error) {
      await _deleteIfExists(saveFile);
      return AppUpdateDownloadResult(
        status: AppUpdateDownloadStatus.failed,
        asset: resolvedAsset,
        filePath: null,
        message: '下载安装包失败：$error',
        actualSha256: null,
      );
    }
  }

  /// 打开已校验的安装入口。
  Future<AppUpdateOpenResult> openVerifiedDownload(
    AppUpdateDownloadResult result,
  ) async {
    final filePath = result.filePath;
    if (!result.isVerified || filePath == null || filePath.isEmpty) {
      return const AppUpdateOpenResult(
        status: AppUpdateOpenStatus.notVerified,
        message: '安装包尚未通过校验，不能打开安装入口。',
      );
    }
    if (result.asset.installSupport == AppUpdateInstallSupport.unsupported) {
      return const AppUpdateOpenResult(
        status: AppUpdateOpenStatus.unsupported,
        message: '当前平台不支持应用内打开本地安装入口，请前往 Release 页面下载。',
      );
    }

    final pathToOpen = result.asset.isPortable
        ? File(filePath).parent.path
        : filePath;
    final openResult = await _open(pathToOpen);
    if (openResult.success) {
      return AppUpdateOpenResult(
        status: AppUpdateOpenStatus.opened,
        message: result.asset.isPortable
            ? '已打开安装包所在文件夹，请手动替换应用文件。'
            : '已打开安装入口，请按系统提示完成安装。',
      );
    }

    final fallback = _runtimePlatform.name == 'android'
        ? '系统拒绝打开 APK。请在文件管理器中找到下载的 APK，并按系统提示允许本次安装。'
        : result.asset.isPortable
        ? '无法打开文件夹。请手动前往 $pathToOpen 替换应用文件。'
        : '系统无法打开安装入口。请手动前往 $pathToOpen。';

    return AppUpdateOpenResult(
      status: AppUpdateOpenStatus.failed,
      message: openResult.message.isEmpty
          ? fallback
          : '$fallback\n${openResult.message}',
    );
  }

  Future<List<AppReleaseInfo>> _fetchReleases() async {
    final response = await _httpService.get<List<dynamic>>(
      _releasesApiUrl,
      options: Options(
        headers: const {'Accept': 'application/vnd.github+json'},
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AppReleaseInfo.fromJson)
        .where(
          (release) => release.version.isNotEmpty && release.htmlUrl.isNotEmpty,
        )
        .toList(growable: false);
  }

  AppReleaseInfo? _selectRelease(
    List<AppReleaseInfo> releases,
    AppUpdateChannel channel,
  ) {
    final filtered = releases
        .where((release) {
          return switch (channel) {
            AppUpdateChannel.stable => !release.prerelease,
            AppUpdateChannel.preview => release.prerelease,
          };
        })
        .toList(growable: false);
    filtered.sort((a, b) => comparePublicVersions(b.version, a.version));
    return filtered.firstOrNull;
  }

  Future<_ReleaseChecksumIndex> _loadReleaseChecksums(
    AppReleaseInfo release,
  ) async {
    final manifestIndex = await _loadManifestIndex(release);
    final shaIndex = await _loadSha256SumsIndex(release);
    return _ReleaseChecksumIndex(
      manifestAssets: manifestIndex,
      sha256Sums: shaIndex,
    );
  }

  Future<Map<String, AppUpdateManifestAsset>> _loadManifestIndex(
    AppReleaseInfo release,
  ) async {
    final manifestAsset = _firstWhereOrNull(
      release.assets,
      (asset) => asset.name.toLowerCase() == 'manifest.json',
    );
    if (manifestAsset == null || manifestAsset.downloadUrl.isEmpty) {
      return const {};
    }
    try {
      final response = await _httpService.get<String>(
        manifestAsset.downloadUrl,
        options: Options(responseType: ResponseType.plain),
      );
      return parseManifestAssets(response.data ?? '');
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, String>> _loadSha256SumsIndex(
    AppReleaseInfo release,
  ) async {
    final sumsAsset = _firstWhereOrNull(
      release.assets,
      (asset) => asset.name.toLowerCase() == 'sha256sums.txt',
    );
    if (sumsAsset == null || sumsAsset.downloadUrl.isEmpty) return const {};
    try {
      final response = await _httpService.get<String>(
        sumsAsset.downloadUrl,
        options: Options(responseType: ResponseType.plain),
      );
      return parseSha256Sums(response.data ?? '');
    } catch (_) {
      return const {};
    }
  }

  AppUpdateAsset? _selectRecommendedAsset(
    List<AppUpdateAsset> assets,
    _ReleaseChecksumIndex checksums,
  ) {
    final candidates = assets.where(_isInstallAssetForRuntime).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((left, right) {
      final leftScore = _assetScore(left, checksums);
      final rightScore = _assetScore(right, checksums);
      return rightScore.compareTo(leftScore);
    });
    return candidates.first;
  }

  bool _isInstallAssetForRuntime(AppUpdateAsset asset) {
    final name = asset.name.toLowerCase();
    if (_isAuxiliaryAssetName(name)) return false;
    final parsed = parseReleaseAssetName(asset.name);
    if (parsed != null) {
      if (parsed.platform != _runtimePlatform.name) return false;
      if (!_archMatches(parsed.arch)) return false;
      return _isAllowedKindForRuntime(parsed.kind, parsed.extension);
    }
    if (!_matchesRuntimePlatformName(name)) return false;
    if (!_matchesRuntimeArchName(name)) return false;
    return inferAssetKind(name) != AppUpdateAssetKind.other;
  }

  bool _matchesRuntimePlatformName(String lowerName) {
    return switch (_runtimePlatform.name) {
      'windows' => lowerName.contains('windows'),
      'macos' => lowerName.contains('macos'),
      'linux' => lowerName.contains('linux'),
      'android' => lowerName.contains('android'),
      _ => false,
    };
  }

  bool _matchesRuntimeArchName(String lowerName) {
    if (_runtimePlatform.name == 'macos' ||
        _runtimePlatform.name == 'android') {
      return lowerName.contains('universal') ||
          (!lowerName.contains('x64') && !lowerName.contains('arm64'));
    }
    if (_runtimePlatform.arch == 'x64') {
      return lowerName.contains('x64') && !lowerName.contains('arm64');
    }
    if (_runtimePlatform.arch == 'arm64') {
      return lowerName.contains('arm64');
    }
    return lowerName.contains(_runtimePlatform.arch);
  }

  bool _archMatches(String assetArch) {
    if (assetArch == 'universal') {
      return _runtimePlatform.name == 'macos' ||
          _runtimePlatform.name == 'android';
    }
    return assetArch == _runtimePlatform.arch;
  }

  bool _isAllowedKindForRuntime(String kind, String extension) {
    return switch (_runtimePlatform.name) {
      'windows' =>
        (kind == 'installer' && extension == '.exe') ||
            (kind == 'portable' && (extension == '.zip' || extension == '.7z')),
      'macos' => extension == '.dmg',
      'linux' =>
        (kind == 'appimage' && extension == '.AppImage') ||
            (kind == 'deb' && extension == '.deb') ||
            (kind == 'rpm' && extension == '.rpm') ||
            (kind == 'portable' && extension == '.tar.gz'),
      'android' => extension == '.apk',
      _ => false,
    };
  }

  int _assetScore(AppUpdateAsset asset, _ReleaseChecksumIndex checksums) {
    final name = asset.name.toLowerCase();
    final parsed = parseReleaseAssetName(asset.name);
    final kind = parsed?.kind ?? _kindNameFromAsset(asset);
    var score = 0;
    score += switch (_runtimePlatform.name) {
      'windows' => switch (kind) {
        'installer' => 100,
        'portable' => 60,
        _ => 0,
      },
      'macos' => name.endsWith('.dmg') ? 100 : 0,
      'linux' => switch (kind) {
        'appimage' => 100,
        'deb' => 80,
        'rpm' => 70,
        'portable' => 50,
        _ => 0,
      },
      'android' => name.endsWith('.apk') ? 100 : 0,
      _ => 0,
    };
    if (checksums.manifestAssets.containsKey(asset.name)) score += 10;
    if (checksums.sha256Sums.containsKey(asset.name)) score += 5;
    if (asset.digest != null && asset.digest!.isNotEmpty) score += 3;
    return score;
  }

  String _kindNameFromAsset(AppUpdateAsset asset) {
    return switch (asset.kind) {
      AppUpdateAssetKind.installer => 'installer',
      AppUpdateAssetKind.dmg => 'unsigned',
      AppUpdateAssetKind.appImage => 'appimage',
      AppUpdateAssetKind.deb => 'deb',
      AppUpdateAssetKind.rpm => 'rpm',
      AppUpdateAssetKind.apk => 'bundle',
      AppUpdateAssetKind.portable => 'portable',
      AppUpdateAssetKind.other => 'other',
    };
  }

  Future<void> _download(
    String url,
    String savePath, {
    required CancelToken cancelToken,
    required void Function(int received, int total) onReceiveProgress,
  }) async {
    final downloadFile = _downloadFile;
    if (downloadFile != null) {
      await downloadFile(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return;
    }
    await _httpService.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<AppUpdateFileOpenResult> _open(String path) async {
    final openFile = _openFile;
    if (openFile != null) return openFile(path);
    final result = await OpenFilex.open(path);
    return AppUpdateFileOpenResult(
      success: result.type == ResultType.done,
      message: result.message,
    );
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _channelLabel(AppUpdateChannel channel) {
    return switch (channel) {
      AppUpdateChannel.stable => '正式版',
      AppUpdateChannel.preview => '测试版',
    };
  }
}
