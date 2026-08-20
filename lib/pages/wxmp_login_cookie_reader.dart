/*
 * 微信公众号 Cookie 读取 adapter — 绑定同一 WebViewEnvironment
 * @Project : SSPU-AllinOne
 * @File : wxmp_login_cookie_reader.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 一次公众号登录 Cookie 读取的去重结果。
class WxmpCookieReadResult {
  /// 创建 Cookie 名称和值的读取结果。
  ///
  /// :param cookieMap: Cookie 名称和值。
  /// :param cookieNames: 读取到的 Cookie 名称集合。
  const WxmpCookieReadResult({
    required this.cookieMap,
    required this.cookieNames,
  });

  /// Cookie 名称和值。
  final Map<String, String> cookieMap;

  /// 去重后的 Cookie 名称集合。
  final Set<String> cookieNames;
}

/// 从与登录 WebView 相同的环境读取公众号 Cookie。
///
/// :param successUrl: 登录成功后的当前 URL。
/// :param controller: 当前页面 generation 对应的 WebView 控制器。
/// :param webViewEnvironment: Windows 自定义 WebView2 环境。
/// :returns: 合并 CookieManager 与 document.cookie 的结果。
Future<WxmpCookieReadResult> readWxmpCookies({
  required String successUrl,
  required InAppWebViewController controller,
  WebViewEnvironment? webViewEnvironment,
}) async {
  final cookieManager = CookieManager.instance(
    webViewEnvironment: webViewEnvironment,
  );
  final cookieMap = <String, String>{};
  final cookieNames = <String>{};
  final currentUrl = await controller.getUrl();
  final cookieUrls = <String>{
    'https://mp.weixin.qq.com/',
    'https://mp.weixin.qq.com/cgi-bin/home',
    'https://mp.weixin.qq.com/cgi-bin/searchbiz',
    'https://mp.weixin.qq.com/cgi-bin/appmsg',
    'https://mp.weixin.qq.com/cgi-bin/appmsgpublish',
    if (currentUrl != null) currentUrl.toString(),
    successUrl,
  };

  for (final cookieUrl in cookieUrls) {
    final cookies = await cookieManager.getCookies(
      url: WebUri(cookieUrl),
      webViewController: controller,
    );
    for (final cookie in cookies) {
      final cookieValue = cookie.value?.toString() ?? '';
      if (cookie.name.isEmpty || cookieValue.isEmpty) continue;
      cookieMap[cookie.name] = cookieValue;
      cookieNames.add(cookie.name);
    }
  }

  final documentCookie = await _readDocumentCookie(controller);
  for (final cookiePart in documentCookie.split(';')) {
    final separatorIndex = cookiePart.indexOf('=');
    if (separatorIndex <= 0) continue;
    final cookieName = cookiePart.substring(0, separatorIndex).trim();
    final cookieValue = cookiePart.substring(separatorIndex + 1).trim();
    if (cookieName.isEmpty || cookieValue.isEmpty) continue;
    cookieMap[cookieName] = cookieValue;
    cookieNames.add(cookieName);
  }

  return WxmpCookieReadResult(cookieMap: cookieMap, cookieNames: cookieNames);
}

/// 读取当前文档可见的 Cookie 文本。
///
/// :param controller: 当前 WebView 控制器。
/// :returns: document.cookie 文本；读取失败时返回空字符串。
Future<String> _readDocumentCookie(InAppWebViewController controller) async {
  try {
    final cookieText = await controller.evaluateJavascript(
      source: 'document.cookie',
    );
    return cookieText?.toString() ?? '';
  } catch (_) {
    return '';
  }
}
