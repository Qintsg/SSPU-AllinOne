/*
 * 应用更新模型 — Release 查询、下载与打开入口的数据结构
 * @Project : SSPU-AllinOne
 * @File : app_update_models.dart
 * @Author : Qintsg
 * @Date : 2026-06-09
 */

part of 'app_update_service.dart';

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

/// 支持本地打开安装入口的平台类型。
enum AppUpdateInstallSupport {
  /// 当前平台可尝试打开本地安装入口。
  supported,

  /// 当前平台不支持本地安装，仅保留 Release 页面入口。
  unsupported,
}

/// Release 资产类型。
enum AppUpdateAssetKind {
  /// 可直接启动的安装器或系统安装入口。
  installer,

  /// macOS DMG 安装镜像。
  dmg,

  /// Linux AppImage。
  appImage,

  /// Linux deb 包。
  deb,

  /// Linux rpm 包。
  rpm,

  /// Android APK。
  apk,

  /// 便携压缩包，需要用户手动替换。
  portable,

  /// 其它不应作为安装入口的资产。
  other,
}

/// 校验值来源。
enum AppUpdateChecksumSource {
  /// Release manifest.json。
  manifest,

  /// Release SHA256SUMS.txt。
  sha256Sums,

  /// GitHub API digest 字段。
  githubDigest,
}

/// 下载状态。
enum AppUpdateDownloadStatus {
  /// 正在下载。
  downloading,

  /// 下载成功并已通过校验。
  verified,

  /// 下载取消。
  canceled,

  /// 下载或校验失败。
  failed,
}

/// 本地安装入口打开结果。
enum AppUpdateOpenStatus {
  /// 已交给系统打开。
  opened,

  /// 当前平台不支持本地安装入口。
  unsupported,

  /// 安装入口尚未通过校验。
  notVerified,

  /// 系统拒绝或无法打开。
  failed,
}

/// 当前运行平台摘要，便于测试注入平台与架构。
class AppUpdateRuntimePlatform {
  /// 平台名称，使用 release manifest 中的平台枚举。
  final String name;

  /// 架构名称，使用 release manifest 中的架构枚举。
  final String arch;

  /// 是否支持本地文件系统。
  final bool supportsLocalFiles;

  /// 是否支持尝试打开本地安装入口。
  final bool supportsLocalInstall;

  const AppUpdateRuntimePlatform({
    required this.name,
    required this.arch,
    required this.supportsLocalFiles,
    required this.supportsLocalInstall,
  });

  /// 从当前 Flutter 运行时解析平台摘要。
  factory AppUpdateRuntimePlatform.current() {
    if (kIsWeb) {
      return const AppUpdateRuntimePlatform(
        name: 'web',
        arch: 'universal',
        supportsLocalFiles: false,
        supportsLocalInstall: false,
      );
    }

    final arch = _normalizeRuntimeArch();
    if (Platform.isWindows) {
      return AppUpdateRuntimePlatform(
        name: 'windows',
        arch: arch,
        supportsLocalFiles: true,
        supportsLocalInstall: true,
      );
    }
    if (Platform.isMacOS) {
      return const AppUpdateRuntimePlatform(
        name: 'macos',
        arch: 'universal',
        supportsLocalFiles: true,
        supportsLocalInstall: true,
      );
    }
    if (Platform.isLinux) {
      return AppUpdateRuntimePlatform(
        name: 'linux',
        arch: arch,
        supportsLocalFiles: true,
        supportsLocalInstall: true,
      );
    }
    if (Platform.isAndroid) {
      return const AppUpdateRuntimePlatform(
        name: 'android',
        arch: 'universal',
        supportsLocalFiles: true,
        supportsLocalInstall: true,
      );
    }
    if (Platform.isIOS) {
      return const AppUpdateRuntimePlatform(
        name: 'ios',
        arch: 'universal',
        supportsLocalFiles: true,
        supportsLocalInstall: false,
      );
    }
    return const AppUpdateRuntimePlatform(
      name: 'unknown',
      arch: 'unknown',
      supportsLocalFiles: false,
      supportsLocalInstall: false,
    );
  }

  static String _normalizeRuntimeArch() {
    final architecture = [
      Platform.environment['PROCESSOR_ARCHITEW6432'],
      Platform.environment['PROCESSOR_ARCHITECTURE'],
      Platform.environment['HOSTTYPE'],
      Platform.environment['MACHTYPE'],
    ].whereType<String>().join(' ').toLowerCase();
    if (architecture.contains('arm64') || architecture.contains('aarch64')) {
      return 'arm64';
    }
    if (architecture.contains('x64') ||
        architecture.contains('x86_64') ||
        architecture.contains('amd64')) {
      return 'x64';
    }
    if (architecture.contains('arm')) return 'armv7';
    return 'x64';
  }
}

/// GitHub Release 资产摘要。
class AppUpdateAsset {
  /// 资产文件名。
  final String name;

  /// 浏览器下载地址。
  final String downloadUrl;

  /// 资产大小，单位字节。
  final int size;

  /// GitHub API digest 字段。
  final String? digest;

  const AppUpdateAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    this.digest,
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

  /// 资产类型。
  AppUpdateAssetKind get kind => inferAssetKind(name);

  /// 是否为便携压缩包。
  bool get isPortable => kind == AppUpdateAssetKind.portable;
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
                    digest: asset['digest']?.toString(),
                  ),
                )
                .where((asset) => asset.name.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

/// Release manifest 中的资产元数据。
class AppUpdateManifestAsset {
  /// 平台名称。
  final String platform;

  /// 架构名称。
  final String arch;

  /// 资产类型。
  final String kind;

  /// 文件名。
  final String filename;

  /// SHA-256 校验值。
  final String sha256;

  const AppUpdateManifestAsset({
    required this.platform,
    required this.arch,
    required this.kind,
    required this.filename,
    required this.sha256,
  });
}

/// 推荐安装资产与校验信息。
class AppUpdateResolvedAsset {
  /// GitHub 资产摘要。
  final AppUpdateAsset asset;

  /// 平台名称。
  final String platform;

  /// 架构名称。
  final String arch;

  /// 发布类型。
  final String kind;

  /// SHA-256 校验值。
  final String? sha256;

  /// 校验值来源。
  final AppUpdateChecksumSource? checksumSource;

  /// 本地安装支持状态。
  final AppUpdateInstallSupport installSupport;

  const AppUpdateResolvedAsset({
    required this.asset,
    required this.platform,
    required this.arch,
    required this.kind,
    required this.sha256,
    required this.checksumSource,
    required this.installSupport,
  });

  /// 是否有可用校验值。
  bool get hasChecksum => sha256 != null && sha256!.isNotEmpty;

  /// 是否为便携压缩包。
  bool get isPortable => asset.isPortable;

  /// 安装入口标签。
  String get openActionLabel {
    if (isPortable) return '打开所在文件夹';
    return '打开安装入口';
  }

  /// 校验来源展示文本。
  String get checksumSourceLabel {
    return switch (checksumSource) {
      AppUpdateChecksumSource.manifest => 'manifest.json',
      AppUpdateChecksumSource.sha256Sums => 'SHA256SUMS.txt',
      AppUpdateChecksumSource.githubDigest => 'GitHub API',
      null => '未提供',
    };
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
  final AppUpdateResolvedAsset? recommendedAsset;

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

/// 下载进度事件。
class AppUpdateDownloadProgress {
  /// 已接收字节数。
  final int received;

  /// 总字节数，未知时为 -1。
  final int total;

  const AppUpdateDownloadProgress({
    required this.received,
    required this.total,
  });

  /// 下载百分比，未知时为 null。
  double? get percent {
    if (total <= 0) return null;
    return (received / total).clamp(0, 1).toDouble();
  }

  /// 人类可读进度。
  String get displayText {
    final receivedText = formatBytes(received);
    if (total <= 0) return '$receivedText / 未知大小';
    return '$receivedText / ${formatBytes(total)}';
  }
}

/// 下载与校验结果。
class AppUpdateDownloadResult {
  /// 下载状态。
  final AppUpdateDownloadStatus status;

  /// 资产。
  final AppUpdateResolvedAsset asset;

  /// 本地文件路径。
  final String? filePath;

  /// 错误说明。
  final String? message;

  /// 计算得到的 SHA-256。
  final String? actualSha256;

  const AppUpdateDownloadResult({
    required this.status,
    required this.asset,
    required this.filePath,
    required this.message,
    required this.actualSha256,
  });

  /// 是否已通过校验。
  bool get isVerified => status == AppUpdateDownloadStatus.verified;
}

/// 打开本地安装入口结果。
class AppUpdateOpenResult {
  /// 打开状态。
  final AppUpdateOpenStatus status;

  /// 结果说明。
  final String message;

  const AppUpdateOpenResult({required this.status, required this.message});

  /// 是否已成功交给系统打开。
  bool get isOpened => status == AppUpdateOpenStatus.opened;
}

/// 文件打开结果，隔离 open_filex 的具体类型。
class AppUpdateFileOpenResult {
  /// 是否打开成功。
  final bool success;

  /// 系统返回信息。
  final String message;

  const AppUpdateFileOpenResult({required this.success, required this.message});
}

/// 下载函数类型。
typedef AppUpdateDownloadFile =
    Future<void> Function(
      String url,
      String savePath, {
      required CancelToken cancelToken,
      required void Function(int received, int total) onReceiveProgress,
    });

/// 本地文件打开函数类型。
typedef AppUpdateOpenFile =
    Future<AppUpdateFileOpenResult> Function(String path);

/// 应用数据目录函数类型。
typedef AppUpdateEnsureDirectory = Future<String> Function(String relativePath);

/// 应用版本信息加载函数类型。
typedef AppUpdateLoadVersionInfo = Future<AppVersionInfo> Function();
