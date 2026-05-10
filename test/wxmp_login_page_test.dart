/*
 * 微信公众号平台登录页测试 — 校验 WebView2 Cookie 存储环境绑定
 * @Project : SSPU-all-in-one
 * @File : wxmp_login_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-09
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_all_in_one/pages/wxmp_login_page.dart';

void main() {
  test('CookieManager 使用登录 WebView 的 WebViewEnvironment', () {
    final previousPlatform = InAppWebViewPlatform.instance;
    InAppWebViewPlatform.instance = _TestInAppWebViewPlatform();
    addTearDown(() {
      if (previousPlatform != null) {
        InAppWebViewPlatform.instance = previousPlatform;
      }
    });

    final platformEnvironment = _TestPlatformWebViewEnvironment();
    final webViewEnvironment = WebViewEnvironment.fromPlatform(
      platform: platformEnvironment,
    );

    final cookieManager = debugCreateWxmpCookieManager(webViewEnvironment);

    // Windows WebView2 自定义用户数据目录依赖同一个 environment id 读取登录 Cookie。
    expect(
      cookieManager.platform.params.webViewEnvironment,
      same(platformEnvironment),
    );
  });
}

class _TestInAppWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformCookieManager createPlatformCookieManager(
    PlatformCookieManagerCreationParams params,
  ) {
    return _TestPlatformCookieManager(params);
  }
}

class _TestPlatformCookieManager extends PlatformCookieManager {
  _TestPlatformCookieManager(super.params) : super.implementation();
}

class _TestPlatformWebViewEnvironment extends PlatformWebViewEnvironment {
  _TestPlatformWebViewEnvironment()
    : super.implementation(const PlatformWebViewEnvironmentCreationParams());

  @override
  String get id => 'test-wxmp-login-env';

  @override
  Future<void> dispose() async {}
}
