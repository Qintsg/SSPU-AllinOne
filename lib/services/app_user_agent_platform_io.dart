/*
 * 应用 User-Agent 平台信息 IO 实现 — 读取 dart:io 平台与系统版本
 * @Project : SSPU-AllinOne
 * @File : app_user_agent_platform_io.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'dart:io' as io;

/// 读取当前运行平台名称。
///
/// :returns: dart:io 规范化平台名，例如 windows、macos、linux、android 或 ios。
String currentAppUserAgentPlatform() {
  return io.Platform.operatingSystem;
}

/// 读取当前操作系统版本描述。
///
/// :returns: dart:io 提供的操作系统版本字符串。
String currentAppUserAgentOsVersion() {
  return io.Platform.operatingSystemVersion;
}
