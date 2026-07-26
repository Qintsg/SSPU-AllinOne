/*
 * 微信公众号平台扫码登录页 — 内嵌 WebView 加载 mp.weixin.qq.com
 * 用户扫码登录后自动提取 Cookie 和 Token
 * @Project : SSPU-AllinOne
 * @File : wxmp_login_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-22
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/wxmp_article_service.dart';
import '../services/wxmp_auth_service.dart';
import '../widgets/webview_compact_toolbar.dart';

/// 公众号平台登录 URL
const String _wxmpLoginUrl = 'https://mp.weixin.qq.com/';

/// 测试入口：创建与登录 WebView 绑定到同一存储环境的 CookieManager。
@visibleForTesting
CookieManager debugCreateWxmpCookieManager(
  WebViewEnvironment? webViewEnvironment,
) {
  return _createWxmpCookieManager(webViewEnvironment);
}

/// Windows 自定义 WebView2 用户数据目录时，CookieManager 也必须使用同一环境。
CookieManager _createWxmpCookieManager(WebViewEnvironment? webViewEnvironment) {
  return CookieManager.instance(webViewEnvironment: webViewEnvironment);
}

/// 微信公众号平台扫码登录页
/// 加载 mp.weixin.qq.com，用户扫码后从 URL 提取 token，从 CookieManager 提取 Cookie
class WxmpLoginPage extends StatefulWidget {
  /// Windows 平台需要的 WebViewEnvironment（由外部传入）
  final WebViewEnvironment? webViewEnvironment;
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  const WxmpLoginPage({
    super.key,
    this.webViewEnvironment,
    this.launchUrlOverride,
  });

  @override
  State<WxmpLoginPage> createState() => _WxmpLoginPageState();
}

class _WxmpLoginPageState extends State<WxmpLoginPage> {
  InAppWebViewController? _controller;
  bool _isReady = false;
  bool _initFailed = false;
  String _initError = '请检查网络连接和 WebView 运行时后重试。';
  String _title = '公众号平台登录';
  bool _extracting = false;
  bool _pageTokenCheckScheduled = false;
  bool _openingExternal = false;
  bool _refreshing = false;
  int _pageGeneration = 0;
  _LoginResult? _result;

  /// 监听 URL 变化，检测登录成功
  /// 登录成功后 URL 形如:
  /// https://mp.weixin.qq.com/cgi-bin/home?t=home/index&token=123456789&lang=zh_CN
  void _checkLoginSuccess(String url) {
    if (_extracting || _result != null) return;

    if (!url.contains('mp.weixin.qq.com')) return;
    final urlToken = _extractTokenFromText(url);
    if (urlToken != null) {
      _extractCookieAndSave(urlToken, url);
      return;
    }

    _schedulePageTokenCheck(url);
  }

  /// URL 不含 token 时，从页面脚本变量和当前地址中补充识别登录态。
  void _schedulePageTokenCheck(String pageUrl) {
    if (_pageTokenCheckScheduled) return;
    _pageTokenCheckScheduled = true;
    final generation = _pageGeneration;
    Future<void>(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (generation != _pageGeneration) return;
      _pageTokenCheckScheduled = false;
      if (!mounted || _extracting || _result != null) return;

      final pageToken = await _readTokenFromPage();
      if (pageToken != null) {
        _extractCookieAndSave(pageToken, pageUrl);
      }
    });
  }

  String? _extractTokenFromText(String text) {
    final tokenMatch = RegExp(
      r'''(?:[?&]token=|["']token["']\s*:\s*["']?)(\d+)''',
    ).firstMatch(text);
    return tokenMatch?.group(1);
  }

  Future<String?> _readTokenFromPage() async {
    final controller = _controller;
    if (controller == null) return null;
    try {
      final tokenText = await controller.evaluateJavascript(
        source: '''
(() => {
  const candidates = [
    window.location.href,
    document.documentElement ? document.documentElement.innerHTML : '',
    document.body ? document.body.innerText : ''
  ];
  for (const candidate of candidates) {
    const match = String(candidate).match(/(?:[?&]token=|["']token["']\\s*:\\s*["']?)(\\d+)/);
    if (match) return match[1];
  }
  return '';
})()
''',
      );
      final token = tokenText?.toString() ?? '';
      return RegExp(r'^\d+$').hasMatch(token) ? token : null;
    } catch (error) {
      debugPrint('[WxmpLogin] 页面 token 读取失败: $error');
      return null;
    }
  }

  /// 提取 Cookie 并与 Token 一起保存
  Future<void> _extractCookieAndSave(String token, String successUrl) async {
    if (_extracting) return;
    setState(() => _extracting = true);

    final authService = WxmpAuthService.instance;
    WxmpAuthSnapshot? previousAuth;
    var candidateWriteStarted = false;
    try {
      previousAuth = await authService.captureAuth();
      _CookieReadResult? lastCookieReadResult;
      WxmpAuthValidationResult? lastValidation;

      for (var attempt = 0; attempt < 4; attempt++) {
        await Future.delayed(Duration(milliseconds: 500 + attempt * 500));
        lastCookieReadResult = await _readWxmpCookies(successUrl);
        if (lastCookieReadResult.cookieMap.isEmpty) continue;

        final cookieStr = lastCookieReadResult.cookieMap.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('; ');

        candidateWriteStarted = true;
        await authService.saveAuth(cookieStr, token);
        lastValidation = await WxmpArticleService.instance.validateAuth();
        if (lastValidation.isValid) {
          debugPrint(
            '[WxmpLogin] 认证保存成功, Cookie 数量: '
            '${lastCookieReadResult.cookieMap.length}, Cookie 键名: '
            '${lastCookieReadResult.cookieNames.toList()..sort()}',
          );

          if (mounted) {
            setState(() {
              _extracting = false;
              _initFailed = false;
              _result = _LoginResult(
                success: true,
                message: '登录成功，Token 和 Cookie 已保存',
              );
            });
          }
          return;
        }
      }

      final cookieCount = lastCookieReadResult?.cookieMap.length ?? 0;
      final cookieNames = lastCookieReadResult?.cookieNames ?? <String>{};
      if (cookieCount == 0) {
        if (mounted) {
          setState(() {
            _extracting = false;
            _result = _LoginResult(
              success: false,
              message: '未获取到 Cookie，请确认已完成扫码',
            );
          });
        }
        return;
      }

      debugPrint(
        '[WxmpLogin] 认证保存后校验失败: ${lastValidation?.message}, Cookie 数量: $cookieCount, Cookie 键名: '
        '${cookieNames.toList()..sort()}',
      );
      final restoreMessage = await _restorePreviousAuth(
        authService,
        previousAuth,
        candidateWriteStarted: candidateWriteStarted,
      );
      if (mounted) {
        setState(() {
          _extracting = false;
          _result = _LoginResult(
            success: false,
            message:
                '认证校验失败：${lastValidation?.message ?? 'Cookie 不完整'}；$restoreMessage',
          );
        });
      }
    } catch (error) {
      final restoreMessage = await _restorePreviousAuth(
        authService,
        previousAuth,
        candidateWriteStarted: candidateWriteStarted,
      );
      if (mounted) {
        setState(() {
          _extracting = false;
          _result = _LoginResult(
            success: false,
            message: '提取失败：$error；$restoreMessage',
          );
        });
      }
    }
  }

  Future<String> _restorePreviousAuth(
    WxmpAuthService authService,
    WxmpAuthSnapshot? snapshot, {
    required bool candidateWriteStarted,
  }) async {
    if (!candidateWriteStarted) return '没有写入新的认证信息';
    if (snapshot == null) return '无法确认原连接状态';
    try {
      await authService.restoreAuth(snapshot);
      final hadPreviousAuth =
          (snapshot.cookie?.trim().isNotEmpty ?? false) &&
          (snapshot.token?.trim().isNotEmpty ?? false);
      return hadPreviousAuth ? '已恢复原连接' : '未保留无效候选凭据';
    } catch (error) {
      debugPrint('[WxmpLogin] 原认证恢复失败: $error');
      return '原连接恢复失败，请返回认证设置检查状态';
    }
  }

  Future<_CookieReadResult> _readWxmpCookies(String successUrl) async {
    final cookieManager = _createWxmpCookieManager(widget.webViewEnvironment);
    final cookieMap = <String, String>{};
    final cookieNames = <String>{};
    final currentUrl = await _controller?.getUrl();
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
        webViewController: _controller,
      );
      for (final cookie in cookies) {
        final cookieValue = cookie.value?.toString() ?? '';
        if (cookie.name.isEmpty || cookieValue.isEmpty) continue;
        cookieMap[cookie.name] = cookieValue;
        cookieNames.add(cookie.name);
      }
    }

    final documentCookie = await _readDocumentCookie();
    for (final cookiePart in documentCookie.split(';')) {
      final separatorIndex = cookiePart.indexOf('=');
      if (separatorIndex <= 0) continue;
      final cookieName = cookiePart.substring(0, separatorIndex).trim();
      final cookieValue = cookiePart.substring(separatorIndex + 1).trim();
      if (cookieName.isEmpty || cookieValue.isEmpty) continue;
      cookieMap[cookieName] = cookieValue;
      cookieNames.add(cookieName);
    }

    return _CookieReadResult(cookieMap: cookieMap, cookieNames: cookieNames);
  }

  Future<String> _readDocumentCookie() async {
    final controller = _controller;
    if (controller == null) return '';
    try {
      final cookieText = await controller.evaluateJavascript(
        source: 'document.cookie',
      );
      return cookieText?.toString() ?? '';
    } catch (error) {
      debugPrint('[WxmpLogin] document.cookie 读取失败: $error');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return PopScope(
      canPop: !_extracting,
      child: YhPageScaffold(
        body: Column(
          children: [
            WebViewCompactToolbar(
              title: _title,
              backSemanticLabel: _extracting
                  ? '正在保存认证，暂不能返回'
                  : _result?.success == true
                  ? '完成'
                  : '返回',
              onBackPressed: _extracting
                  ? null
                  : () => Navigator.of(context).pop(_result?.success ?? false),
              actions: [
                YhIconButton(
                  icon: YhIcons.refresh,
                  semanticLabel: '刷新微信登录页',
                  variant: YhIconButtonVariant.ghost,
                  onTap:
                      _extracting ||
                          _openingExternal ||
                          _refreshing ||
                          _result?.success == true
                      ? null
                      : _refreshLoginPage,
                ),
                YhIconButton(
                  icon: YhIcons.open,
                  semanticLabel: '在系统浏览器打开微信登录页',
                  variant: YhIconButtonVariant.ghost,
                  onTap:
                      _extracting ||
                          _openingExternal ||
                          _refreshing ||
                          _result?.success == true
                      ? null
                      : _openLoginInBrowser,
                ),
                if (_extracting)
                  SizedBox.square(
                    dimension: theme.control.minimumTarget,
                    child: Center(
                      child: SizedBox(
                        width: theme.spacing.xl,
                        child: const YhProgress(
                          value: null,
                          showPercent: false,
                          semanticLabel: '正在提取登录凭据',
                        ),
                      ),
                    ),
                  ),
                if (_result != null)
                  SizedBox.square(
                    dimension: theme.control.minimumTarget,
                    child: Center(
                      child: Icon(
                        _result!.success ? YhIcons.check : YhIcons.warning,
                        size: theme.spacing.l,
                        color: _result!.success
                            ? theme.color.success
                            : theme.color.danger,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.yhTheme;

    if (_initFailed) {
      return YhEmptyState(
        icon: YhIcons.warning,
        title: '无法打开微信登录页',
        message: _initError,
        action: YhButton(label: '重新打开登录页', onTap: _refreshLoginPage),
      );
    }

    return Column(
      children: [
        if (_result != null) _WxmpLoginInlineStatus(result: _result!),
        if (_extracting && _result == null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              theme.spacing.l,
              theme.spacing.s,
              theme.spacing.l,
              theme.spacing.xs,
            ),
            child: const YhBanner(
              text: '正在保存并校验认证信息；完成前暂不能返回或再次开始登录。',
              kind: YhBannerKind.warn,
            ),
          ),
        if (!_isReady && _result == null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              theme.spacing.l,
              theme.spacing.s,
              theme.spacing.l,
              theme.spacing.xs,
            ),
            child: const YhBanner(
              text: '请使用拥有公众号的微信账号扫码登录。个人订阅号即可（mp.weixin.qq.com 免费注册）。',
            ),
          ),
        Expanded(
          child: InAppWebView(
            webViewEnvironment: widget.webViewEnvironment,
            initialUrlRequest: URLRequest(url: WebUri(_wxmpLoginUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              isInspectable: kDebugMode,
              // UA-POLICY-ALLOW: 微信公众号扫码登录页依赖浏览器 UA 展示桌面登录流程，不能使用 OA/CAS 应用 UA。
              userAgent:
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              if (mounted) setState(() => _isReady = true);
            },
            onTitleChanged: (controller, title) {
              if (mounted && title != null && title.isNotEmpty) {
                setState(() => _title = title);
              }
            },
            onUpdateVisitedHistory: (controller, url, isReload) {
              if (url != null && mounted) {
                _checkLoginSuccess(url.toString());
              }
            },
            onLoadStop: (controller, url) {
              if (url != null && mounted) {
                _checkLoginSuccess(url.toString());
              }
            },
            onReceivedError: (controller, request, error) {
              debugPrint('[WxmpLogin] WebView 错误: ${error.description}');
              if (request.isForMainFrame == true &&
                  mounted &&
                  !_extracting &&
                  _result == null) {
                setState(() {
                  _initFailed = true;
                  _initError =
                      '微信登录页加载失败：${error.description}。请检查网络连接后重试；桌面端还需确认 WebView 运行时可用。';
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _refreshLoginPage() async {
    if (_extracting ||
        _openingExternal ||
        _refreshing ||
        _result?.success == true) {
      return;
    }
    setState(() {
      _refreshing = true;
      _pageGeneration += 1;
      _result = null;
      _initFailed = false;
      _initError = '请检查网络连接和 WebView 运行时后重试。';
      _pageTokenCheckScheduled = false;
    });
    try {
      await _controller?.reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initFailed = true;
        _initError = '重新加载微信登录页失败：$error';
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openLoginInBrowser() async {
    if (_extracting ||
        _openingExternal ||
        _refreshing ||
        _result?.success == true) {
      return;
    }
    final confirmed = await YhDialog.confirm(
      context,
      title: '在系统浏览器打开微信登录页',
      message:
          '系统浏览器不与应用内登录页共享认证结果。离开应用后，浏览器页面不再受本应用的本地保护。'
          '若要让本应用读取授权信息，仍需回到这里完成扫码。',
      confirmText: '继续打开',
    );
    if (!confirmed || !mounted) return;
    setState(() => _openingExternal = true);
    try {
      final uri = Uri.parse(_wxmpLoginUrl);
      final opened = await (widget.launchUrlOverride ?? _launchExternal)(uri);
      if (!opened && mounted) {
        setState(() {
          _result = _LoginResult(
            success: false,
            message: '系统浏览器未能打开微信登录页，请检查默认浏览器设置后重试。',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _result = _LoginResult(
            success: false,
            message: '系统浏览器未能打开微信登录页，请检查默认浏览器设置后重试。',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _openingExternal = false);
    }
  }

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// 公众号平台登录结果的内联短状态。
class _WxmpLoginInlineStatus extends StatelessWidget {
  const _WxmpLoginInlineStatus({required this.result});

  /// 登录结果。
  final _LoginResult result;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        key: const Key('wxmp-login-inline-status'),
        padding: EdgeInsetsDirectional.fromSTEB(
          theme.spacing.l,
          theme.spacing.s,
          theme.spacing.l,
          theme.spacing.xs,
        ),
        child: YhBanner(
          text: result.message,
          kind: result.success ? YhBannerKind.success : YhBannerKind.danger,
        ),
      ),
    );
  }
}

/// 登录结果
class _LoginResult {
  final bool success;
  final String message;
  _LoginResult({required this.success, required this.message});
}

class _CookieReadResult {
  final Map<String, String> cookieMap;
  final Set<String> cookieNames;

  _CookieReadResult({required this.cookieMap, required this.cookieNames});
}
