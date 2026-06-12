/*
 * 应用 User-Agent 平台信息降级实现 — Web 等非 IO 平台使用 Flutter 平台摘要
 * @Project : SSPU-AllinOne
 * @File : app_user_agent_platform_stub.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'package:flutter/foundation.dart';

/// 读取当前运行平台名称。
///
/// :returns: Web 平台返回 web，其它降级场景返回 Flutter 目标平台名。
String currentAppUserAgentPlatform() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform.name;
}

/// 读取当前操作系统版本描述。
///
/// :returns: 非 IO 平台无法稳定读取系统版本，返回 unknown。
String currentAppUserAgentOsVersion() {
  return 'unknown';
}
