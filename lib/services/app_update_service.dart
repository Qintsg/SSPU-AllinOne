/*
 * 应用更新服务 — 通过 GitHub Release 查询可用版本与平台下载资产
 * @Project : SSPU-AllinOne
 * @File : app_update_service.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'dart:io';

import 'package:dio/dio.dart';

import 'app_info_service.dart';
import 'http_service.dart';

/// 应用更新检查渠道。
enum AppUpdateChannel {
  /// 正式版渠道，仅读取 GitHub Release 中的普通 Release。
  stable,

  /// 测试版渠道，优先读取 GitHub Release 中的 Pre-release。
  preview,
}

/// 应用更新检查结果类型。
enum AppUpdateStatus {
  /// 发现比当前版本新的 Release。
  available,

  /// 当前版本已是所选渠道的最新版本。
  upToDate,

  /// 所选渠道暂无可用 Release。
  unavailable,
}

/// GitHub Release 资产摘要。
class AppUpdateAsset {
  /// 资产文件名。
  final String name;

  /// 浏览器下载地址。
  final String downloadUrl;

  /// 资产大小，单位字节。
  final int size;

  const AppUpdateAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  /// 人类可读大小。
  String get displaySize {
    if (size <= 0) return '未知大小';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = size.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final digits = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
  }
}

/// GitHub Release 摘要。
class AppReleaseInfo {
  /// GitHub Release 标题。
  final String title;

  /// GitHub Tag 名称。
  final String tagName;

  /// 公开版本号，不含前缀 v。
  final String version;

  /// 是否为 Pre-release。
  final bool prerelease;

  /// GitHub Release 页面地址。
  final String htmlUrl;

  /// 发布时间。
  final DateTime? publishedAt;

  /// Release 资产列表。
  final List<AppUpdateAsset> assets;

  const AppReleaseInfo({
    required this.title,
    required this.tagName,
    required this.version,
    required this.prerelease,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
  });

  /// 从 GitHub REST API JSON 创建 Release 摘要。
  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name']?.toString() ?? '';
    final assetsJson = json['assets'];
    return AppReleaseInfo(
      title: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : tagName,
      tagName: tagName,
      version: normalizeVersion(tagName),
      prerelease: json['prerelease'] == true,
      htmlUrl: json['html_url']?.toString() ?? '',
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
      assets: assetsJson is List
          ? assetsJson
                .whereType<Map<String, dynamic>>()
                .map(
                  (asset) => AppUpdateAsset(
                    name: asset['name']?.toString() ?? '',
                    downloadUrl:
                        asset['browser_download_url']?.toString() ?? '',
                    size: int.tryParse(asset['size']?.toString() ?? '') ?? 0,
                  ),
                )
                .where((asset) => asset.name.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

/// 应用更新检查结果。
class AppUpdateCheckResult {
  /// 检查状态。
  final AppUpdateStatus status;

  /// 当前应用版本。
  final String currentVersion;

  /// 检查渠道。
  final AppUpdateChannel channel;

  /// 最新 Release 信息。
  final AppReleaseInfo? release;

  /// 推荐下载资产。
  final AppUpdateAsset? recommendedAsset;

  /// 结果说明。
  final String message;

  const AppUpdateCheckResult({
    required this.status,
    required this.currentVersion,
    required this.channel,
    required this.release,
    required this.recommendedAsset,
    required this.message,
  });

  /// 是否发现新版本。
  bool get hasUpdate => status == AppUpdateStatus.available;
}

/// GitHub Release 更新检查服务。
class AppUpdateService {
  AppUpdateService({HttpService? httpService, AppInfoService? appInfoService})
    : _httpService = httpService ?? HttpService.instance,
      _appInfoService = appInfoService ?? AppInfoService.instance;

  /// 默认服务实例。
  static final AppUpdateService instance = AppUpdateService();

  static const String _releasesApiUrl =
      'https://api.github.com/repos/Qintsg/SSPU-AllinOne/releases';

  final HttpService _httpService;
  final AppInfoService _appInfoService;

  /// 检查指定渠道是否存在可用更新。
  Future<AppUpdateCheckResult> checkForUpdates({
    AppUpdateChannel channel = AppUpdateChannel.stable,
  }) async {
    final currentVersionInfo = await _appInfoService.loadVersionInfo();
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

    final recommendedAsset = selectRecommendedAsset(release.assets);
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
          ? '发现新版本 ${release.version}，但未找到当前平台的安装包。'
          : '发现新版本 ${release.version}，可下载安装包更新。',
    );
  }

  /// 选择最适合当前平台的 Release 资产。
  AppUpdateAsset? selectRecommendedAsset(List<AppUpdateAsset> assets) {
    final candidates = assets
        .where((asset) {
          final name = asset.name.toLowerCase();
          if (name.endsWith('.txt') || name.endsWith('.json')) return false;
          if (Platform.isWindows) {
            return name.contains('windows') &&
                (name.endsWith('.exe') ||
                    name.endsWith('.msix') ||
                    name.endsWith('.zip') ||
                    name.endsWith('.7z'));
          }
          if (Platform.isMacOS) {
            return name.contains('macos') &&
                (name.endsWith('.dmg') || name.endsWith('.zip'));
          }
          if (Platform.isLinux) {
            return name.contains('linux') &&
                (name.endsWith('.deb') ||
                    name.endsWith('.appimage') ||
                    name.endsWith('.tar.gz') ||
                    name.endsWith('.zip'));
          }
          if (Platform.isAndroid) {
            return name.contains('android') &&
                (name.endsWith('.apk') || name.endsWith('.aab'));
          }
          if (Platform.isIOS) {
            return name.contains('ios') &&
                (name.endsWith('.ipa') || name.endsWith('.zip'));
          }
          return false;
        })
        .toList(growable: false);

    if (candidates.isEmpty) return null;
    return candidates.reduce((best, asset) {
      return _assetScore(asset.name) > _assetScore(best.name) ? asset : best;
    });
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

  int _assetScore(String assetName) {
    final name = assetName.toLowerCase();
    var score = 0;
    if (name.contains('installer')) score += 30;
    if (name.contains('portable')) score += 20;
    if (name.contains('universal')) score += 15;
    if (name.contains('x64')) score += 10;
    if (name.endsWith('.exe') ||
        name.endsWith('.dmg') ||
        name.endsWith('.apk')) {
      score += 8;
    }
    return score;
  }

  String _channelLabel(AppUpdateChannel channel) {
    return switch (channel) {
      AppUpdateChannel.stable => '正式版',
      AppUpdateChannel.preview => '测试版',
    };
  }
}

/// 去除版本号前缀和构建号，返回公开版本号。
String normalizeVersion(String version) {
  final trimmed = version.trim();
  final withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V')
      ? trimmed.substring(1)
      : trimmed;
  return withoutPrefix.split('+').first;
}

/// 比较公开版本号，返回正数表示 [left] 更新。
int comparePublicVersions(String left, String right) {
  final leftParts = _parseVersionParts(left);
  final rightParts = _parseVersionParts(right);
  final maxLength = leftParts.numbers.length > rightParts.numbers.length
      ? leftParts.numbers.length
      : rightParts.numbers.length;

  for (var index = 0; index < maxLength; index++) {
    final leftNumber = index < leftParts.numbers.length
        ? leftParts.numbers[index]
        : 0;
    final rightNumber = index < rightParts.numbers.length
        ? rightParts.numbers[index]
        : 0;
    if (leftNumber != rightNumber) return leftNumber.compareTo(rightNumber);
  }

  return _channelRank(
    leftParts.channel,
  ).compareTo(_channelRank(rightParts.channel));
}

({List<int> numbers, String channel}) _parseVersionParts(String version) {
  final publicVersion = normalizeVersion(version);
  final segments = publicVersion.split('-');
  final numbers = segments.first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
  final channel = segments.length > 1 ? segments[1].toLowerCase() : 'stable';
  return (numbers: numbers, channel: channel);
}

int _channelRank(String channel) {
  return switch (channel) {
    'alpha' => 0,
    'beta' => 1,
    'rc' => 2,
    'stable' => 3,
    'hotfix' => 4,
    'lts' => 5,
    _ => -1,
  };
}
