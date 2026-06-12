/*
 * 应用 User-Agent 服务 — 统一生成 OA/CAS 请求使用的应用身份标识
 * @Project : SSPU-AllinOne
 * @File : app_user_agent_service.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'package:flutter/foundation.dart';

import 'app_info_service.dart';
import 'app_user_agent_platform.dart';

/// 应用版本信息加载函数，便于测试注入。
typedef AppUserAgentVersionLoader = Future<AppVersionInfo> Function();

/// 统一生成网络请求使用的应用身份 User-Agent。
class AppUserAgentService {
  AppUserAgentService._();

  /// HTTP User-Agent 中的产品名。
  static const String productName = 'SSPU-AllinOne';

  /// 平台插件不可用时使用的版本号。
  static const String fallbackVersion = '0.0.0';

  static String _userAgent = build(
    version: fallbackVersion,
    platform: currentAppUserAgentPlatform(),
    osVersion: currentAppUserAgentOsVersion(),
  );

  /// 当前标准 User-Agent。
  static String get userAgent => _userAgent;

  /// 从平台包信息初始化标准 User-Agent。
  ///
  /// :param loadVersionInfo: 可选版本加载函数，测试中用于绕过平台插件。
  /// :param platform: 可选平台名，测试中用于固定输出。
  /// :param osVersion: 可选系统版本，测试中用于固定输出。
  /// :returns: 初始化后的标准 User-Agent。
  static Future<String> initialize({
    AppUserAgentVersionLoader? loadVersionInfo,
    String? platform,
    String? osVersion,
  }) async {
    var version = fallbackVersion;
    try {
      final versionInfo =
          await (loadVersionInfo ?? AppInfoService.instance.loadVersionInfo)();
      if (versionInfo.version.trim().isNotEmpty) {
        version = versionInfo.version;
      }
    } catch (_) {
      version = fallbackVersion;
    }

    _userAgent = build(
      version: version,
      platform: platform ?? currentAppUserAgentPlatform(),
      osVersion: osVersion ?? currentAppUserAgentOsVersion(),
    );
    return _userAgent;
  }

  /// 按应用约定格式构造 User-Agent。
  ///
  /// :param version: 应用版本号。
  /// :param platform: 平台名。
  /// :param osVersion: 操作系统版本描述。
  /// :returns: 形如 `SSPU-AllinOne/{version} ({platform}; {os_version})` 的值。
  static String build({
    required String version,
    required String platform,
    required String osVersion,
  }) {
    final safeVersion = _sanitizeProductVersion(
      version,
      fallback: fallbackVersion,
    );
    final safePlatform = _sanitizeCommentSegment(platform);
    final safeOsVersion = _sanitizeCommentSegment(osVersion);
    return '$productName/$safeVersion ($safePlatform; $safeOsVersion)';
  }

  /// 测试专用：覆盖当前标准 User-Agent。
  ///
  /// :param value: 覆盖值；为空时恢复为当前平台 fallback 值。
  @visibleForTesting
  static void debugSetUserAgentForTesting(String? value) {
    _userAgent =
        value ??
        build(
          version: fallbackVersion,
          platform: currentAppUserAgentPlatform(),
          osVersion: currentAppUserAgentOsVersion(),
        );
  }

  static String _sanitizeProductVersion(
    String value, {
    required String fallback,
  }) {
    final normalized = value.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._+-]+'),
      '_',
    );
    return normalized.isEmpty ? fallback : normalized;
  }

  static String _sanitizeCommentSegment(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'[();\\]+'), ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized.isEmpty ? 'unknown' : normalized;
  }
}
