/*
 * WebView2 环境全局单例 — Windows 平台 WebViewEnvironment 持有者
 * flutter_inappwebview 在 Windows 上要求需要共享 Cookie 的 WebView 实例
 * 使用同一个 WebViewEnvironment；本文件按需懒加载环境，避免启动即加载
 * Chromium / WebView2 native 资源导致关闭时产生无页面场景的清理噪声。
 * @Project : SSPU-AllinOne
 * @File : webview_env.dart
 * @Author : Qintsg
 * @Date : 2026-04-21
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/app_data_directory_service.dart';

/// Windows 平台全局 WebViewEnvironment 实例。
///
/// 仅在首次打开内嵌 WebView 或微信公众号登录页时创建；非 Windows 平台始终为 null。
WebViewEnvironment? globalWebViewEnvironment;

/// 防止短时间内多个页面同时触发 WebView2 环境创建。
Future<WebViewEnvironment?>? _globalWebViewEnvironmentFuture;

/// 当前平台是否需要自定义 Windows WebView2 环境。
bool get _supportsWindowsWebView => !kIsWeb && Platform.isWindows;

/// 获取全局 WebView2 环境；未创建时按需初始化。
///
/// Windows 自定义用户数据目录依赖同一个环境读取登录 Cookie；因此所有需要
/// Cookie 共享的页面都应通过此入口获取环境，而不是在应用启动时提前创建。
Future<WebViewEnvironment?> ensureGlobalWebViewEnvironment() async {
  if (!_supportsWindowsWebView) return null;
  final environment = globalWebViewEnvironment;
  if (environment != null) return environment;

  final pendingEnvironment = _globalWebViewEnvironmentFuture;
  if (pendingEnvironment != null) return pendingEnvironment;

  final creationFuture = _createGlobalWebViewEnvironment();
  _globalWebViewEnvironmentFuture = creationFuture;
  try {
    globalWebViewEnvironment = await creationFuture;
    return globalWebViewEnvironment;
  } finally {
    _globalWebViewEnvironmentFuture = null;
  }
}

/// 释放已创建的全局 WebView2 环境。
///
/// 退出应用时显式释放环境，可让插件先销毁隐藏 WebView2 controller，减少
/// Chromium 窗口类在进程结束阶段才清理造成的 shell 侧错误输出。
Future<void> disposeGlobalWebViewEnvironment() async {
  if (!_supportsWindowsWebView) return;

  final pendingEnvironment = _globalWebViewEnvironmentFuture;
  var environment = globalWebViewEnvironment;
  _globalWebViewEnvironmentFuture = null;
  globalWebViewEnvironment = null;

  if (environment == null && pendingEnvironment != null) {
    environment = await pendingEnvironment;
  }

  await environment?.dispose();
}

/// 创建带统一用户数据目录的 Windows WebView2 环境。
Future<WebViewEnvironment?> _createGlobalWebViewEnvironment() async {
  final availableVersion = await WebViewEnvironment.getAvailableVersion();
  if (availableVersion == null) return null;

  final webViewDataFolder = await AppDataDirectoryService.ensureDirectoryPath(
    'webview2',
  );
  return WebViewEnvironment.create(
    settings: WebViewEnvironmentSettings(userDataFolder: webViewDataFolder),
  );
}
