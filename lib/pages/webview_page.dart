/*
 * 内嵌 WebView 页面 — 在应用内展示网页内容
 * 使用 flutter_inappwebview 实现跨平台内嵌浏览（Windows/macOS/Android/iOS/Linux）
 * @Project : SSPU-AllinOne
 * @File : webview_page.dart
 * @Author : Qintsg
 * @Date : 2026-04-19
 */

import '../design/fluent_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_spacing.dart';
import '../widgets/empty_state_view.dart';

/// 内嵌 WebView 页面。
/// 在应用内打开网页链接，提供导航栏（返回/前进/刷新/外部浏览器）。
class WebViewPage extends StatefulWidget {
  /// 要加载的目标 URL。
  final String url;

  /// 页面标题（WebView 加载完成前的临时标题）。
  final String initialTitle;

  /// Windows 平台需要的 WebViewEnvironment（可选，由外部传入）。
  final WebViewEnvironment? webViewEnvironment;

  const WebViewPage({
    super.key,
    required this.url,
    this.initialTitle = '加载中…',
    this.webViewEnvironment,
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

  /// 是否可后退。
  bool _canGoBack = false;

  /// 是否可前进。
  bool _canGoForward = false;

  /// WebView 是否已创建。
  bool _isReady = false;

  /// 初始化是否失败（触发 fallback）。
  bool _initFailed = false;

  /// 加载进度（0.0 ~ 1.0）。
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _currentUrl = widget.url;
  }

  /// 判断链接是否可由内嵌 WebView 安全加载。
  bool _isSupportedWebUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// 更新导航按钮状态（前进/后退可用性）。
  Future<void> _updateNavigationState() async {
    if (_controller == null) return;
    final canBack = await _controller!.canGoBack();
    final canForward = await _controller!.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    }
  }

  /// 使用系统默认浏览器打开当前 URL（fallback 方案）。
  Future<void> _fallbackToExternalBrowser() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return _buildStatePage(
        context,
        title: widget.initialTitle,
        child: EmptyStateView(
          icon: FluentIcons.warning,
          title: 'WebView 初始化失败',
          message: '已在默认浏览器中打开链接',
          action: FluentButton.primary(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回'),
          ),
        ),
      );
    }

    if (!_isSupportedWebUrl(_currentUrl)) {
      return _buildStatePage(
        context,
        title: widget.initialTitle,
        child: EmptyStateView(
          icon: FluentIcons.linkDismiss,
          title: '链接无效，无法打开',
          message: _currentUrl,
          action: FluentButton.primary(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回'),
          ),
        ),
      );
    }

    return FluentPage(
      header: FluentPageHeader(
        title: Text(_title, overflow: TextOverflow.ellipsis, maxLines: 1),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluentIconButton(
              tooltip: '后退',
              icon: const Icon(FluentIcons.back),
              onPressed: _canGoBack ? () => _controller?.goBack() : null,
            ),
            FluentIconButton(
              tooltip: '前进',
              icon: const Icon(FluentIcons.forward),
              onPressed: _canGoForward ? () => _controller?.goForward() : null,
            ),
            FluentIconButton(
              tooltip: '刷新',
              icon: const Icon(FluentIcons.refresh),
              onPressed: _isReady ? () => _controller?.reload() : null,
            ),
            FluentIconButton(
              tooltip: '在浏览器中打开',
              icon: const Icon(FluentIcons.openInNewWindow),
              onPressed: _fallbackToExternalBrowser,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
      content: Stack(
        children: [
          InAppWebView(
            webViewEnvironment: widget.webViewEnvironment,
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              isInspectable: kDebugMode,
              userAgent:
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              if (mounted) {
                setState(() => _isReady = true);
              }
            },
            onTitleChanged: (controller, title) {
              if (mounted && title != null && title.isNotEmpty) {
                setState(() => _title = title);
              }
            },
            onUpdateVisitedHistory: (controller, url, isReload) {
              if (url != null && mounted) {
                setState(() => _currentUrl = url.toString());
                _updateNavigationState();
              }
            },
            onLoadStop: (controller, url) {
              if (url != null && mounted) {
                setState(() => _currentUrl = url.toString());
                _updateNavigationState();
              }
            },
            onProgressChanged: (controller, progress) {
              if (mounted) {
                setState(() => _progress = progress / 100.0);
              }
            },
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame == true && mounted) {
                setState(() => _initFailed = true);
                _fallbackToExternalBrowser();
              }
            },
          ),
          if (_progress > 0 && _progress < 1.0)
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: FluentProgressBar(value: _progress),
            ),
        ],
      ),
    );
  }

  /// 构建异常状态页面外壳。
  Widget _buildStatePage(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return FluentPage(
      header: FluentPageHeader(title: Text(title)),
      content: child,
    );
  }
}
