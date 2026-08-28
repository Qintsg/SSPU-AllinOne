/*
 * 微信公众号扫码登录测试注入 — Cookie、认证事务与校验边界
 * @Project : SSPU-AllinOne
 * @File : wxmp_login_test_hooks.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'wxmp_login_cookie_reader.dart';
import '../services/wxmp_article_service.dart';
import '../services/wxmp_auth_service.dart';

/// 测试替换 Cookie 读取器。
typedef WxmpCookieReaderOverride = Future<WxmpCookieReadResult> Function({
  required String successUrl,
  required InAppWebViewController controller,
  WebViewEnvironment? webViewEnvironment,
});

/// 测试替换认证保存器。
typedef WxmpAuthSaveOverride = Future<void> Function(
  String cookie,
  String token,
);

/// 微信公众号登录流程的可选测试注入点；生产页面保持为空。
class WxmpLoginTestOverrides {
  /// 创建登录流程测试替换集合。
  ///
  /// :param readCookies: Cookie 读取替换器。
  /// :param captureAuth: 原认证快照读取替换器。
  /// :param saveAuth: 候选认证保存替换器。
  /// :param validateAuth: 候选认证校验替换器。
  /// :param restoreAuth: 原认证恢复替换器。
  const WxmpLoginTestOverrides({
    this.readCookies,
    this.captureAuth,
    this.saveAuth,
    this.validateAuth,
    this.restoreAuth,
  });

  /// Cookie 读取替换器。
  final WxmpCookieReaderOverride? readCookies;

  /// 原认证快照读取替换器。
  final Future<WxmpAuthSnapshot> Function()? captureAuth;

  /// 候选认证保存替换器。
  final WxmpAuthSaveOverride? saveAuth;

  /// 候选认证校验替换器。
  final Future<WxmpAuthValidationResult> Function()? validateAuth;

  /// 原认证恢复替换器。
  final Future<void> Function(WxmpAuthSnapshot snapshot)? restoreAuth;
}
