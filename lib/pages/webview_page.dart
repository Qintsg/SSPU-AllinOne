/*
 * 内嵌 WebView 页面 — 在应用内展示网页内容
 * 使用 flutter_inappwebview 实现跨平台内嵌浏览（Windows/macOS/Android/iOS/Linux）
 * @Project : SSPU-AllinOne
 * @File : webview_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-19
 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/webview_compact_toolbar.dart';

/// WebView 清源页面框架；生产插件与确定性外部区域 fixture 共享同一工具栏和进度布局。
class WebViewPageFrame extends StatelessWidget {
  const WebViewPageFrame({
    super.key,
    required this.title,
    required this.document,
    required this.onBackPressed,
    this.actions = const [],
    this.progress,
    this.statusBanner,
  });

  final String title;
  final Widget document;
  final VoidCallback onBackPressed;
  final List<Widget> actions;
  final double? progress;
  final Widget? statusBanner;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    return YhPageScaffold(
      body: Column(
        children: [
          WebViewCompactToolbar(
            title: title,
            onBackPressed: onBackPressed,
            actions: actions,
          ),
          if (statusBanner case final banner?)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                context.yhTheme.spacing.m,
                context.yhTheme.spacing.s,
                context.yhTheme.spacing.m,
                0,
              ),
              child: banner,
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: document),
                if (value != null && value > 0 && value < 1)
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    end: 0,
                    child: YhProgressBar(value: value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// WebView 主文档失败后的清源自绘恢复区；生产页与视觉 fixture 共用。
class WebViewFailureDocument extends StatelessWidget {
  const WebViewFailureDocument({
    super.key,
    required this.target,
    required this.loadError,
    required this.onRetry,
    required this.onOpenExternal,
    this.externalOpenError,
    this.openingExternal = false,
  });

  final String target;
  final String loadError;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenExternal;
  final String? externalOpenError;
  final bool openingExternal;

  @override
  Widget build(BuildContext context) {
    final externalFailed = externalOpenError != null;
    return YhEmptyState(
      icon: YhIcons.warning,
      title: externalFailed ? '外部打开未完成' : '网页加载失败',
      message: externalFailed
          ? '$externalOpenError 目标 $target 与当前页面均已保留。'
          : '无法加载 $target：$loadError。没有自动离开应用。',
      action: Wrap(
        spacing: context.yhTheme.spacing.s,
        runSpacing: context.yhTheme.spacing.s,
        alignment: WrapAlignment.center,
        children: [
          YhButton(label: '重新加载', onTap: openingExternal ? null : onRetry),
          YhButton(
            label: openingExternal ? '正在外部打开…' : '在浏览器中打开',
            variant: YhButtonVariant.secondary,
            onTap: openingExternal ? null : onOpenExternal,
          ),
        ],
      ),
    );
  }
}

/// 在离开应用前展示可信目标与本地保护边界。
Future<bool> confirmWebViewExternalOpen(BuildContext context, Uri uri) {
  return YhDialog.confirm(
    context,
    title: '在系统浏览器中打开？',
    message: '即将在系统浏览器打开 ${uri.host}。离开应用后，网页不再受本应用的本地保护。',
    confirmText: '继续打开',
  );
}

/// 内嵌 WebView 页面。
/// 在应用内打开网页链接，提供导航栏（返回/前进/刷新/外部浏览器）。
class WebViewPage extends StatefulWidget {
  /// 要加载的目标 URL。
  final String url;

  /// 页面标题（WebView 加载完成前的临时标题）。
  final String initialTitle;

  /// Windows 平台需要的 WebViewEnvironment（可选，由外部传入）。
  final WebViewEnvironment? webViewEnvironment;

  /// 系统浏览器启动 seam；测试可注入确定性 adapter。
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  /// WebView 运行时创建的最长等待时间；测试可缩短以验证降级路径。
  final Duration initializationTimeout;

  const WebViewPage({
    super.key,
    required this.url,
    this.initialTitle = '加载中…',
    this.webViewEnvironment,
    this.launchUrlOverride,
    this.initializationTimeout = const Duration(seconds: 12),
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  /// InAppWebView 控制器。
  InAppWebViewController? _controller;

  /// 当前页面标题。
  String _title = '';

  /// 当前加载的 URL。
  String _currentUrl = '';

  /// WebView 是否已创建。
  bool _isReady = false;

  /// 初始化是否失败（触发 fallback）。
  bool _initFailed = false;

  /// 主文档加载失败的可恢复原因。
  String? _loadErrorDescription;

  bool _isOpeningExternal = false;
  String? _externalOpenError;

  Timer? _initializationTimer;
  int _documentGeneration = 0;
  Future<void>? _backOperation;
  bool _routePopAllowed = false;

  /// 加载进度（0.0 ~ 1.0）。
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _currentUrl = widget.url;
    _startInitializationWatch();
  }

  @override
  void dispose() {
    _initializationTimer?.cancel();
    super.dispose();
  }

  /// 判断链接是否可由内嵌 WebView 安全加载。
  bool _isSupportedWebUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// 使用系统默认浏览器打开当前 URL（fallback 方案）。
  Future<void> _fallbackToExternalBrowser() async {
    if (_isOpeningExternal) return;
    final targetUrl = _currentUrl;
    final documentGeneration = _documentGeneration;
    final uri = Uri.tryParse(targetUrl);
    if (uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      final confirmed = await confirmWebViewExternalOpen(context, uri);
      if (!confirmed || !mounted || _isOpeningExternal) return;
      if (_currentUrl != targetUrl ||
          _documentGeneration != documentGeneration) {
        return;
      }
      setState(() {
        _isOpeningExternal = true;
        _externalOpenError = null;
      });
      try {
        final opened = widget.launchUrlOverride != null
            ? await widget.launchUrlOverride!(uri)
            : await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened &&
            mounted &&
            _currentUrl == targetUrl &&
            _documentGeneration == documentGeneration) {
          setState(() {
            _externalOpenError = '系统浏览器未能打开校园网页；仍停留在应用内，可检查默认浏览器设置后重试。';
          });
        }
      } on Object catch (error) {
        if (!mounted ||
            _currentUrl != targetUrl ||
            _documentGeneration != documentGeneration) {
          return;
        }
        setState(() {
          _externalOpenError = '系统浏览器未能打开校园网页：$error。仍停留在应用内，可稍后重试。';
        });
      } finally {
        if (mounted) setState(() => _isOpeningExternal = false);
      }
    }
  }

  Widget? _buildExternalStatusBanner() {
    if (_isOpeningExternal) {
      return const YhBanner(
        kind: YhBannerKind.info,
        text: '正在交给系统浏览器；完成前已锁定重复外部打开，网页和返回路径保持可用。',
      );
    }
    final error = _externalOpenError;
    if (error == null) return null;
    return YhBanner(kind: YhBannerKind.danger, text: error);
  }

  YhIconButton _buildExternalToolbarAction() => YhIconButton(
    semanticLabel: '在浏览器中打开',
    icon: YhIcons.open,
    onTap: _isOpeningExternal ? null : _fallbackToExternalBrowser,
  );

  /// 保留当前 URL，在原位置重新加载主文档。
  void _retryInApp() {
    if (!mounted) return;
    _initializationTimer?.cancel();
    setState(() {
      _documentGeneration++;
      _controller = null;
      _isReady = false;
      _initFailed = false;
      _loadErrorDescription = null;
      _externalOpenError = null;
      _progress = 0;
    });
    _startInitializationWatch();
  }

  /// WebView 返回按钮行为：有网页历史时后退网页，否则退出当前路由。
  Future<void> _handleBackOrClose() {
    final active = _backOperation;
    if (active != null) return active;
    final future = _performBackOrClose();
    _backOperation = future;
    return future.whenComplete(() {
      if (identical(_backOperation, future)) _backOperation = null;
    });
  }

  Future<void> _performBackOrClose() async {
    final controller = _controller;
    if (controller != null) {
      try {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return;
        }
      } on Object {
        await _requestRouteExit();
        return;
      }
    }
    await _requestRouteExit();
  }

  Future<void> _requestRouteExit() async {
    if (!mounted) return;
    if (!_routePopAllowed) setState(() => _routePopAllowed = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop && mounted) {
      setState(() => _routePopAllowed = false);
    }
  }

  void _startInitializationWatch() {
    _initializationTimer?.cancel();
    if (!_isSupportedWebUrl(_currentUrl)) return;
    final generation = _documentGeneration;
    _initializationTimer = Timer(widget.initializationTimeout, () {
      if (!mounted || generation != _documentGeneration || _isReady) return;
      setState(() {
        _initFailed = true;
        _loadErrorDescription = 'WebView 运行时未响应，请检查平台组件后重试';
      });
    });
  }

  bool _isCurrentDocument(int generation) =>
      mounted && generation == _documentGeneration && !_initFailed;

  void _recordVisitedUrl(int generation, WebUri? url) {
    if (url == null || !_isCurrentDocument(generation)) return;
    final nextUrl = url.toString();
    setState(() {
      if (_currentUrl != nextUrl) _externalOpenError = null;
      _currentUrl = nextUrl;
    });
  }

  Widget _coordinateSystemBack(Widget child) => PopScope(
    canPop: _routePopAllowed,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_handleBackOrClose());
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      final host = Uri.tryParse(_currentUrl)?.host;
      final target = host == null || host.isEmpty ? _currentUrl : host;
      return _coordinateSystemBack(
        _buildStatePage(
          context,
          title: widget.initialTitle,
          child: WebViewFailureDocument(
            target: target,
            loadError: _loadErrorDescription ?? '未知错误',
            externalOpenError: _externalOpenError,
            openingExternal: _isOpeningExternal,
            onRetry: _retryInApp,
            onOpenExternal: _fallbackToExternalBrowser,
          ),
        ),
      );
    }

    if (!_isSupportedWebUrl(_currentUrl)) {
      return _coordinateSystemBack(
        _buildStatePage(
          context,
          title: widget.initialTitle,
          child: YhEmptyState(
            icon: YhIcons.close,
            title: '链接无效，无法打开',
            message: _currentUrl,
            action: YhButton(
              label: '返回',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }

    final documentGeneration = _documentGeneration;
    return _coordinateSystemBack(
      WebViewPageFrame(
        title: _title,
        onBackPressed: _handleBackOrClose,
        actions: [
          YhIconButton(
            semanticLabel: '刷新',
            icon: YhIcons.refresh,
            onTap: _isReady && !_isOpeningExternal
                ? () => _controller?.reload()
                : null,
          ),
          _buildExternalToolbarAction(),
        ],
        statusBanner: _buildExternalStatusBanner(),
        progress: _progress,
        document: InAppWebView(
          key: ValueKey('webview-document-$documentGeneration'),
          webViewEnvironment: widget.webViewEnvironment,
          initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            isInspectable: kDebugMode,
            // UA-POLICY-ALLOW: 通用内嵌网页用于学校官网/外部文章展示，需要浏览器 UA 兼容页面渲染。
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          ),
          onWebViewCreated: (controller) {
            if (!_isCurrentDocument(documentGeneration)) return;
            _controller = controller;
            _initializationTimer?.cancel();
            if (mounted) {
              setState(() => _isReady = true);
            }
          },
          onTitleChanged: (controller, title) {
            if (_isCurrentDocument(documentGeneration) &&
                title != null &&
                title.isNotEmpty) {
              setState(() => _title = title);
            }
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            _recordVisitedUrl(documentGeneration, url);
          },
          onLoadStop: (controller, url) {
            _recordVisitedUrl(documentGeneration, url);
          },
          onProgressChanged: (controller, progress) {
            if (_isCurrentDocument(documentGeneration)) {
              setState(() => _progress = progress / 100.0);
            }
          },
          onReceivedError: (controller, request, error) {
            if (request.isForMainFrame == true &&
                _isCurrentDocument(documentGeneration)) {
              _initializationTimer?.cancel();
              final failedUrl = request.url.toString();
              setState(() {
                if (_currentUrl != failedUrl) _externalOpenError = null;
                _currentUrl = failedUrl;
                _initFailed = true;
                _loadErrorDescription = error.description;
              });
            }
          },
        ),
      ),
    );
  }

  /// 构建异常状态页面外壳。
  Widget _buildStatePage(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return WebViewPageFrame(
      title: title,
      onBackPressed: _handleBackOrClose,
      actions: [
        YhIconButton(
          semanticLabel: '刷新',
          icon: YhIcons.refresh,
          onTap: _isSupportedWebUrl(_currentUrl) && !_isOpeningExternal
              ? _retryInApp
              : null,
        ),
        if (_isSupportedWebUrl(_currentUrl))
          _buildExternalToolbarAction()
        else
          YhIconButton(
            semanticLabel: '在浏览器中打开',
            icon: YhIcons.open,
            onTap: null,
          ),
      ],
      statusBanner: _buildExternalStatusBanner(),
      document: child,
    );
  }
}
