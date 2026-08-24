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
import 'wxmp_login_cookie_reader.dart';
import 'wxmp_login_preview.dart';
import 'wxmp_login_test_hooks.dart';
export 'wxmp_login_preview.dart' show WxmpLoginPreviewState;

part 'wxmp_login_auth_transaction.dart';

/// 公众号平台登录 URL
const String _wxmpLoginUrl = 'https://mp.weixin.qq.com/';

/// 测试入口：创建与登录 WebView 绑定到同一存储环境的 CookieManager。
///
/// :param webViewEnvironment: Windows 自定义 WebView2 环境；其它平台可为空。
/// :returns: 与登录 WebView 共享环境的 CookieManager。
@visibleForTesting
CookieManager debugCreateWxmpCookieManager(
  WebViewEnvironment? webViewEnvironment,
) {
  return _createWxmpCookieManager(webViewEnvironment);
}

/// Windows 自定义 WebView2 用户数据目录时，CookieManager 也必须使用同一环境。
///
/// :param webViewEnvironment: Windows 自定义 WebView2 环境；其它平台可为空。
/// :returns: 绑定指定环境的 CookieManager。
CookieManager _createWxmpCookieManager(WebViewEnvironment? webViewEnvironment) {
  return CookieManager.instance(webViewEnvironment: webViewEnvironment);
}

/// 微信公众号平台扫码登录页
/// 加载 mp.weixin.qq.com，用户扫码后从 URL 提取 token，从 CookieManager 提取 Cookie
class WxmpLoginPage extends StatefulWidget {
  /// Windows 平台需要的 WebViewEnvironment（由外部传入）。
  final WebViewEnvironment? webViewEnvironment;

  /// 打开系统浏览器的可替换入口；为空时使用平台默认实现。
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  /// 视觉 fixture 使用的确定性状态；生产调用保持 null。
  final WxmpLoginPreviewState? previewState;

  /// 测试用 token 闸门观察器；生产调用保持 null，不改变认证服务。
  @visibleForTesting
  final void Function(String token)? onTokenDetectedForTesting;

  /// 测试用登录事务替换器；生产调用保持 null。
  @visibleForTesting
  final WxmpLoginTestOverrides? testOverrides;

  /// 创建公众号平台扫码登录页。
  /// :param key: 页面状态键。
  /// :param webViewEnvironment: Windows 自定义 WebView2 环境。
  /// :param launchUrlOverride: 测试或平台适配使用的外部打开入口。
  /// :param previewState: 视觉 fixture 使用的确定性状态。
  /// :param onTokenDetectedForTesting: 测试用 token 观察器。
  /// :param testOverrides: 测试用 Cookie、认证事务和校验替换器。
  const WxmpLoginPage({
    super.key,
    this.webViewEnvironment,
    this.launchUrlOverride,
    this.previewState,
    this.onTokenDetectedForTesting,
    this.testOverrides,
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
  _LoginFailureKind? _failureKind;

  /// 将内部认证结果映射为冻结设计使用的展示状态。
  ///
  /// :returns: 当前生产或 fixture 的可见状态。
  WxmpLoginPreviewState get _displayState {
    final preview = widget.previewState;
    if (preview != null) return preview;
    if (_initFailed) return WxmpLoginPreviewState.error;
    if (_extracting) return WxmpLoginPreviewState.operationLocked;
    if (!_isReady) return WxmpLoginPreviewState.loading;
    if (_result?.success == true) return WxmpLoginPreviewState.content;
    if (_result != null) {
      return _failureKind == _LoginFailureKind.externalOpen
          ? WxmpLoginPreviewState.externalError
          : WxmpLoginPreviewState.partialError;
    }
    return WxmpLoginPreviewState.initial;
  }

  /// 判断顶部重复行动是否因加载、失败、锁定或完成而不可用。
  ///
  /// :returns: 刷新与外部打开是否必须锁定。
  bool get _toolbarActionsLocked =>
      !_isReady ||
      _initFailed ||
      _extracting ||
      _openingExternal ||
      _refreshing ||
      _result?.success == true;

  /// 解析工具栏标题，成功态不再继续显示网页标题。
  ///
  /// :returns: 当前工具栏可见标题。
  String get _toolbarTitle => _result?.success == true ? '登录已完成' : _title;

  /// 将视觉 fixture 状态映射为生产页面已有的展示字段。
  ///
  /// :returns: 无返回值；字段更新后由当前 build 读取。
  void _configurePreviewState() {
    final state = widget.previewState;
    if (state == null) return;
    _isReady = state != WxmpLoginPreviewState.loading;
    switch (state) {
      case WxmpLoginPreviewState.loading:
      case WxmpLoginPreviewState.initial:
      case WxmpLoginPreviewState.externalConfirmation:
        break;
      case WxmpLoginPreviewState.content:
        _result = _LoginResult(
          success: true,
          message: '登录成功，连接信息已保存在本机；返回后将刷新公众号内容。',
        );
      case WxmpLoginPreviewState.error:
        _initFailed = true;
        _initError = '请检查网络连接和 WebView 运行时后重试；当前没有写入新的认证信息。';
      case WxmpLoginPreviewState.partialError:
        _failureKind = _LoginFailureKind.candidateValidation;
        _result = _LoginResult(
          success: false,
          message: '候选认证校验失败，已恢复原连接；可刷新二维码后重新扫码。',
        );
      case WxmpLoginPreviewState.operationLocked:
        _extracting = true;
      case WxmpLoginPreviewState.externalError:
        _failureKind = _LoginFailureKind.externalOpen;
        _result = _LoginResult(
          success: false,
          message: '系统浏览器未能打开微信登录页；应用内扫码页和当前位置均已保留。',
        );
    }
  }

  /// 初始化页面状态与确定性视觉 fixture 字段。
  ///
  /// :returns: 无返回值。
  @override
  void initState() {
    super.initState();
    _configurePreviewState();
  }

  /// 在视觉矩阵切换状态时重置并重新应用确定性页面字段。
  ///
  /// :param oldWidget: 上一帧的页面配置。
  /// :returns: 无返回值。
  @override
  void didUpdateWidget(covariant WxmpLoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewState == widget.previewState) return;
    _isReady = false;
    _initFailed = false;
    _extracting = false;
    _result = null;
    _failureKind = null;
    _configurePreviewState();
  }

  /// 在页面仍挂载时提交认证事务发起的展示状态。
  ///
  /// :param update: 需要在同一帧中提交的状态变更。
  void _setLoginState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  /// 监听 URL 变化，检测登录成功
  /// 登录成功后 URL 形如:
  /// https://mp.weixin.qq.com/cgi-bin/home?t=home/index&token=123456789&lang=zh_CN
  void _checkLoginSuccess(String url, int generation) {
    final controller = _controller;
    if (!_isCurrentDocument(generation, controller)) return;
    if (_extracting || _result != null) return;

    if (!url.contains('mp.weixin.qq.com')) return;
    final urlToken = _extractTokenFromText(url);
    if (urlToken != null) {
      widget.onTokenDetectedForTesting?.call(urlToken);
      _extractCookieAndSave(
        urlToken,
        url,
        generation: generation,
        controller: controller!,
      );
      return;
    }

    _schedulePageTokenCheck(url, generation, controller!);
  }

  /// URL 不含 token 时，从页面脚本变量和当前地址中补充识别登录态。
  void _schedulePageTokenCheck(
    String pageUrl,
    int generation,
    InAppWebViewController controller,
  ) {
    if (_pageTokenCheckScheduled) return;
    _pageTokenCheckScheduled = true;
    Future<void>(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCurrentDocument(generation, controller)) return;
      _pageTokenCheckScheduled = false;
      if (!mounted || _extracting || _result != null) return;

      final pageToken = await _readTokenFromPage(controller);
      if (pageToken != null && _isCurrentDocument(generation, controller)) {
        _extractCookieAndSave(
          pageToken,
          pageUrl,
          generation: generation,
          controller: controller,
        );
      }
    });
  }

  String? _extractTokenFromText(String text) {
    final tokenMatch = RegExp(
      r'''(?:[?&]token=|["']token["']\s*:\s*["']?)(\d+)''',
    ).firstMatch(text);
    return tokenMatch?.group(1);
  }

  Future<String?> _readTokenFromPage(InAppWebViewController controller) async {
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

  /// 判断 WebView 回调是否仍属于当前页面换代。
  ///
  /// :param generation: 回调创建时捕获的页面换代号。
  /// :param controller: 回调所属的 WebView 控制器。
  /// :returns: 仍可安全写入当前页面状态时返回 true。
  bool _isCurrentDocument(int generation, InAppWebViewController? controller) {
    return mounted &&
        generation == _pageGeneration &&
        controller != null &&
        identical(controller, _controller);
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
              title: _toolbarTitle,
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
                  onTap: _toolbarActionsLocked ? null : _refreshLoginPage,
                ),
                YhIconButton(
                  icon: YhIcons.open,
                  semanticLabel: '在系统浏览器打开微信登录页',
                  variant: YhIconButtonVariant.ghost,
                  onTap: _toolbarActionsLocked ? null : _openLoginInBrowser,
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

  /// 构建应用自绘状态框架，并在唯一正文 seam 注入真实 WebView 或 fixture。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 共用认证接力条、恢复区与平台正文组成的页面主体。
  Widget _buildContent(BuildContext context) => WxmpLoginContentFrame(
    state: _displayState,
    errorMessage: _initError,
    resultMessage: _result?.message,
    onRetry: _refreshLoginPage,
    documentBuilder: _buildLoginDocument,
  );

  /// 构建唯一会随平台而变化的网页正文 seam。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 真实 InAppWebView 或确定性外部正文。
  Widget _buildLoginDocument(BuildContext context) {
    if (widget.previewState != null) {
      return const WxmpLoginPreviewDocument(
        key: Key('visual-wechat-login-document'),
      );
    }
    final generation = _pageGeneration;
    return KeyedSubtree(
      key: ValueKey('wxmp-login-webview-$generation'),
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
          if (!mounted || generation != _pageGeneration) return;
          _controller = controller;
          setState(() => _isReady = true);
        },
        onTitleChanged: (controller, title) {
          if (_isCurrentDocument(generation, controller) &&
              title != null &&
              title.isNotEmpty &&
              _result?.success != true) {
            setState(() => _title = title);
          }
        },
        onUpdateVisitedHistory: (controller, url, isReload) {
          if (url != null) _checkLoginSuccess(url.toString(), generation);
        },
        onLoadStop: (controller, url) {
          if (url != null) _checkLoginSuccess(url.toString(), generation);
        },
        onReceivedError: (controller, request, error) {
          debugPrint('[WxmpLogin] WebView 错误: ${error.description}');
          if (request.isForMainFrame == true &&
              _isCurrentDocument(generation, controller) &&
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
    );
  }

  Future<void> _refreshLoginPage() async {
    if (_extracting ||
        _openingExternal ||
        _refreshing ||
        _result?.success == true) {
      return;
    }
    final controller = _controller;
    setState(() {
      _refreshing = true;
      _pageGeneration += 1;
      _controller = null;
      _isReady = false;
      _result = null;
      _initFailed = false;
      _failureKind = null;
      _title = '公众号平台登录';
      _initError = '请检查网络连接和 WebView 运行时后重试。';
      _pageTokenCheckScheduled = false;
    });
    try {
      await controller?.reload();
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
          _failureKind = _LoginFailureKind.externalOpen;
          _result = _LoginResult(
            success: false,
            message: '系统浏览器未能打开微信登录页，请检查默认浏览器设置后重试。',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failureKind = _LoginFailureKind.externalOpen;
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

enum _LoginFailureKind { candidateValidation, externalOpen }

/// 登录结果
class _LoginResult {
  /// 创建成功或失败的登录结果。
  ///
  /// :param success: 是否已完成认证。
  /// :param message: 面向用户的结果说明。
  final bool success;
  final String message;

  /// 创建成功或失败的登录结果值。
  _LoginResult({required this.success, required this.message});
}
