/*
 * 应用更新解析工具 — Release 资产文件名、校验值与版本比较解析
 * @Project : SSPU-AllinOne
 * @File : app_update_parsing.dart
 * @Author : Qintsg
 * @Date : 2026-06-09
 */

part of 'app_update_service.dart';

class _ReleaseChecksumIndex {
  final Map<String, AppUpdateManifestAsset> manifestAssets;
  final Map<String, String> sha256Sums;

  const _ReleaseChecksumIndex({
    required this.manifestAssets,
    required this.sha256Sums,
  });

  _ResolvedSha256? resolveSha256(AppUpdateAsset asset) {
    final manifestSha = manifestAssets[asset.name]?.sha256;
    if (_isSha256Hex(manifestSha)) {
      return _ResolvedSha256(
        value: manifestSha!,
        source: AppUpdateChecksumSource.manifest,
      );
    }
    final sumsSha = sha256Sums[asset.name];
    if (_isSha256Hex(sumsSha)) {
      return _ResolvedSha256(
        value: sumsSha!,
        source: AppUpdateChecksumSource.sha256Sums,
      );
    }
    final digestSha = _parseGithubDigest(asset.digest);
    if (_isSha256Hex(digestSha)) {
      return _ResolvedSha256(
        value: digestSha!,
        source: AppUpdateChecksumSource.githubDigest,
      );
    }
    return null;
  }
}

class _ResolvedSha256 {
  final String value;
  final AppUpdateChecksumSource source;

  const _ResolvedSha256({required this.value, required this.source});
}

/// Release 文件名解析结果。
class AppUpdateAssetNameParts {
  /// 公开版本。
  final String version;

  /// 平台名称。
  final String platform;

  /// 架构名称。
  final String arch;

  /// 资产类型。
  final String kind;

  /// 扩展名。
  final String extension;

  const AppUpdateAssetNameParts({
    required this.version,
    required this.platform,
    required this.arch,
    required this.kind,
    required this.extension,
  });
}

final RegExp _assetNamePattern = RegExp(
  r'^SSPU-AllinOne-v(.+?)-(android|ios|windows|macos|linux|web)-'
  r'(universal|x64|arm64|armv7)'
  r'(?:-(installer|portable|bundle|static|unsigned|appimage|deb|rpm))?'
  r'(\.AppImage|\.tar\.gz|\.7z|\.zip|\.exe|\.dmg|\.deb|\.rpm|\.apk)$',
);

/// 解析 Release 资产文件名。
AppUpdateAssetNameParts? parseReleaseAssetName(String name) {
  final match = _assetNamePattern.firstMatch(name);
  if (match == null) return null;
  final platform = match.group(2)!;
  final extension = match.group(5)!;
  final explicitKind = match.group(4);
  return AppUpdateAssetNameParts(
    version: match.group(1)!,
    platform: platform,
    arch: match.group(3)!,
    kind: explicitKind ?? _inferReleaseKind(platform, extension),
    extension: extension,
  );
}

/// 从 manifest.json 文本解析资产与校验值。
Map<String, AppUpdateManifestAsset> parseManifestAssets(String content) {
  try {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) return const {};
    final platforms = decoded['platforms'];
    if (platforms is! List) return const {};
    final entries = <String, AppUpdateManifestAsset>{};
    for (final item in platforms.whereType<Map<String, dynamic>>()) {
      final filename = item['filename']?.toString() ?? '';
      final sha256Value = item['sha256']?.toString() ?? '';
      if (filename.isEmpty || !_isSha256Hex(sha256Value)) continue;
      entries[filename] = AppUpdateManifestAsset(
        platform: item['platform']?.toString() ?? '',
        arch: item['arch']?.toString() ?? '',
        kind: item['kind']?.toString() ?? '',
        filename: filename,
        sha256: sha256Value.toLowerCase(),
      );
    }
    return entries;
  } catch (_) {
    return const {};
  }
}

/// 从 SHA256SUMS.txt 文本解析校验值。
Map<String, String> parseSha256Sums(String content) {
  final entries = <String, String>{};
  for (final rawLine in const LineSplitter().convert(content)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final match = RegExp(r'^([a-fA-F0-9]{64})\s+\*?(.+)$').firstMatch(line);
    if (match == null) continue;
    final filename = match.group(2)!.trim();
    if (filename.isEmpty) continue;
    entries[filename] = match.group(1)!.toLowerCase();
  }
  return entries;
}

/// 推断资产类型。
AppUpdateAssetKind inferAssetKind(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.exe') || lower.endsWith('.msix')) {
    return AppUpdateAssetKind.installer;
  }
  if (lower.endsWith('.dmg')) return AppUpdateAssetKind.dmg;
  if (lower.endsWith('.appimage')) return AppUpdateAssetKind.appImage;
  if (lower.endsWith('.deb')) return AppUpdateAssetKind.deb;
  if (lower.endsWith('.rpm')) return AppUpdateAssetKind.rpm;
  if (lower.endsWith('.apk')) return AppUpdateAssetKind.apk;
  if ((lower.endsWith('.zip') ||
          lower.endsWith('.7z') ||
          lower.endsWith('.tar.gz')) &&
      lower.contains('portable')) {
    return AppUpdateAssetKind.portable;
  }
  return AppUpdateAssetKind.other;
}

/// 计算文件 SHA-256。
Future<String> sha256ForFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

/// 格式化字节数。
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final digits = value >= 100 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
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

bool _isAuxiliaryAssetName(String lowerName) {
  return lowerName == 'manifest.json' ||
      lowerName == 'sha256sums.txt' ||
      lowerName == 'release-notes.md' ||
      lowerName.endsWith('.txt') ||
      lowerName.endsWith('.json') ||
      lowerName.endsWith('.md') ||
      lowerName.contains('-web-') ||
      lowerName.endsWith('.aab');
}

String _inferReleaseKind(String platform, String extension) {
  if (platform == 'android' && extension == '.apk') return 'bundle';
  if (platform == 'macos' && extension == '.dmg') return 'unsigned';
  return switch (extension) {
    '.exe' => 'installer',
    '.AppImage' => 'appimage',
    '.deb' => 'deb',
    '.rpm' => 'rpm',
    '.zip' || '.7z' || '.tar.gz' => 'portable',
    _ => 'other',
  };
}

String? _parseGithubDigest(String? digestValue) {
  if (digestValue == null || digestValue.trim().isEmpty) return null;
  final trimmed = digestValue.trim();
  if (_isSha256Hex(trimmed)) return trimmed.toLowerCase();
  final match = RegExp(r'^sha256:([a-fA-F0-9]{64})$').firstMatch(trimmed);
  return match?.group(1)?.toLowerCase();
}

bool _isSha256Hex(String? value) {
  if (value == null) return false;
  return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value.trim());
}

bool _sameSha256(String left, String right) {
  return left.toLowerCase() == right.toLowerCase();
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) return value;
  }
  return null;
}

String _safePathSegment(String value) {
  final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return sanitized.isEmpty ? 'unknown_release' : sanitized;
}
