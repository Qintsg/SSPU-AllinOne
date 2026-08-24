/*
 * WebView 页面测试平台 adapter — 可控回调与生命周期
 * @Project : SSPU-AllinOne
 * @File : webview_page_test_platform.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'webview_page_test.dart';

/// 提供可控 InAppWebView platform adapter 的测试平台。
class _TestInAppWebViewPlatform extends InAppWebViewPlatform {
  final _TestPlatformInAppWebViewController controller =
      _TestPlatformInAppWebViewController();
  bool dispatchCallbacks = true;
  int widgetCreationCount = 0;
  final List<String?> createdUrls = [];

  @override
  PlatformInAppWebViewController createPlatformInAppWebViewController(
    PlatformInAppWebViewControllerCreationParams params,
  ) {
    return controller;
  }

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    widgetCreationCount++;
    createdUrls.add(params.initialUrlRequest?.url.toString());
    return _TestPlatformInAppWebViewWidget(
      params,
      controller,
      dispatchCallbacks: dispatchCallbacks,
    );
  }
}

/// 模拟生产 WebView widget，并按测试开关派发生命周期回调。
class _TestPlatformInAppWebViewWidget extends PlatformInAppWebViewWidget {
  /// 创建可控 callback 派发策略的 WebView widget adapter。
  ///
  /// :param params: Flutter WebView platform 参数。
  /// :param controller: 共享测试控制器。
  /// :param dispatchCallbacks: 是否自动派发生命周期回调。
  _TestPlatformInAppWebViewWidget(
    super.params,
    this.controller, {
    required this.dispatchCallbacks,
  }) : super.implementation();

  final _TestPlatformInAppWebViewController controller;
  final bool dispatchCallbacks;

  /// 构建可触发生产 WebView 回调的确定性占位。
  ///
  /// :param context: 当前测试构建上下文。
  /// :returns: 可控的 WebView 占位 widget。
  @override
  Widget build(BuildContext context) {
    final appController = params.controllerFromPlatform?.call(controller);
    if (appController is InAppWebViewController) {
      controller.appController = appController;
      controller.onUpdateVisitedHistory = params.onUpdateVisitedHistory;
      controller.onLoadStop = params.onLoadStop;
      controller.onReceivedError = params.onReceivedError;
    }
    if (dispatchCallbacks &&
        appController is InAppWebViewController &&
        !controller.callbacksDispatched) {
      controller.callbacksDispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        params.onWebViewCreated?.call(appController);
        params.onTitleChanged?.call(appController, '网页标题');
        params.onLoadStop?.call(appController, WebUri('https://example.com'));
        final errorDescription = controller.mainFrameErrorDescription;
        if (errorDescription != null) {
          params.onReceivedError?.call(
            appController,
            WebResourceRequest(
              url: WebUri('https://mp.weixin.qq.com/'),
              isForMainFrame: true,
            ),
            WebResourceError(
              description: errorDescription,
              type: WebResourceErrorType.UNKNOWN,
            ),
          );
        }
      });
    }
    return const ColoredBox(
      key: Key('fake-in-app-webview'),
      color: Color(0xFFEFEFEF),
      child: SizedBox.expand(),
    );
  }

  /// 将底层测试控制器适配为插件公开控制器。
  ///
  /// :param controller: 底层 platform 控制器。
  /// :returns: 对应类型的测试控制器。
  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    return params.controllerFromPlatform!.call(controller) as T;
  }

  /// 释放测试 widget 的 platform 资源。
  ///
  /// :returns: 无返回值。
  @override
  void dispose() {}
}

/// 提供 WebView 历史、刷新、错误和回调控制的测试控制器。
class _TestPlatformInAppWebViewController
    extends PlatformInAppWebViewController {
  /// 创建可控制历史、刷新和错误回调的测试控制器。
  _TestPlatformInAppWebViewController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'test-webview'),
      );

  bool canGoBackValue = false;
  bool canGoForwardValue = false;
  int goBackCount = 0;
  int goForwardCount = 0;
  int reloadCount = 0;
  bool callbacksDispatched = false;
  String? mainFrameErrorDescription;
  Object? canGoBackError;
  Completer<void>? goBackCompletion;
  InAppWebViewController? appController;
  void Function(InAppWebViewController, WebUri?, bool?)? onUpdateVisitedHistory;
  void Function(InAppWebViewController, WebUri?)? onLoadStop;
  void Function(InAppWebViewController, WebResourceRequest, WebResourceError)?
  onReceivedError;

  @override
  Future<bool> canGoBack() async {
    final error = canGoBackError;
    if (error != null) throw error;
    return canGoBackValue;
  }

  @override
  Future<void> goBack() async {
    goBackCount++;
    await goBackCompletion?.future;
  }

  @override
  Future<bool> canGoForward() async => canGoForwardValue;

  @override
  Future<void> goForward() async {
    goForwardCount++;
  }

  @override
  Future<void> reload() async {
    reloadCount++;
  }

  /// 派发一个导航到指定 URL 的回调。
  ///
  /// :param url: 新页面 URL。
  /// :returns: 回调派发完成时结束。
  Future<void> visit(String url) async {
    final controller = appController;
    if (controller == null) throw StateError('WebView controller not ready');
    onUpdateVisitedHistory?.call(controller, WebUri(url), false);
  }

  /// 派发一个主文档加载失败回调。
  ///
  /// :param url: 失败文档 URL。
  /// :param description: 可见错误描述。
  /// :returns: 回调派发完成时结束。
  Future<void> failMainFrame(String url, String description) async {
    final controller = appController;
    if (controller == null) throw StateError('WebView controller not ready');
    onReceivedError?.call(
      controller,
      WebResourceRequest(url: WebUri(url), isForMainFrame: true),
      WebResourceError(
        description: description,
        type: WebResourceErrorType.UNKNOWN,
      ),
    );
  }

  @override
  Future<WebUri?> getUrl() async => WebUri('https://example.com');
}
