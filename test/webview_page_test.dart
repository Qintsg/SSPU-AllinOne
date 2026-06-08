/*
 * WebView 页面测试 — 校验紧凑工具栏与返回/退出行为
 * @Project : SSPU-AllinOne
 * @File : webview_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/pages/wxmp_login_page.dart';

void main() {
  late InAppWebViewPlatform? previousPlatform;
  late _TestInAppWebViewPlatform testPlatform;

  setUp(() {
    previousPlatform = InAppWebViewPlatform.instance;
    testPlatform = _TestInAppWebViewPlatform();
    InAppWebViewPlatform.instance = testPlatform;
  });

  tearDown(() {
    if (previousPlatform != null) {
      InAppWebViewPlatform.instance = previousPlatform!;
    }
  });

  testWidgets('WebView 紧凑工具栏始终显示可点击退出入口并约束长标题', (tester) async {
    final semantics = tester.ensureSemantics();
    await _configureMobileView(tester);

    try {
      await tester.pumpWidget(
        const FluentApp(
          home: WebViewPage(
            url: 'https://example.com/news',
            initialTitle: '这是一条非常非常非常长的网页标题用于验证标题栏不会换行撑高或挤压右侧操作按钮',
          ),
        ),
      );
      await tester.pump();

      final toolbar = find.byKey(const Key('webview-compact-toolbar'));
      final backCloseButton = find.byKey(
        const Key('webview-back-close-button'),
      );

      expect(toolbar, findsOneWidget);
      expect(backCloseButton, findsOneWidget);
      expect(find.bySemanticsLabel('返回'), findsWidgets);
      expect(
        tester.getSemantics(find.bySemanticsLabel('返回').first),
        matchesSemantics(
          label: '返回',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(tester.getSize(toolbar).height, lessThanOrEqualTo(56));
      expect(
        tester.takeException(),
        isNull,
        reason: '紧凑标题栏不应在移动窄屏产生 overflow 异常',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _resetMobileView(tester);
      semantics.dispose();
    }
  });

  testWidgets('WebView 返回按钮有网页历史时优先后退网页', (tester) async {
    testPlatform.controller.canGoBackValue = true;

    await tester.pumpWidget(
      const FluentApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '网页标题',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('webview-back-close-button')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(testPlatform.controller.goBackCount, 1);
  });

  testWidgets('WebView 返回按钮无网页历史时退出当前路由', (tester) async {
    testPlatform.controller.canGoBackValue = false;

    await tester.pumpWidget(
      FluentApp(
        home: Builder(
          builder: (context) => FluentButton(
            onPressed: () {
              Navigator.of(context).push(
                FluentPageRoute(
                  builder: (_) => const WebViewPage(
                    url: 'https://example.com/news',
                    initialTitle: '网页标题',
                  ),
                ),
              );
            },
            child: const Text('打开 WebView'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开 WebView'));
    await tester.pumpAndSettle();
    expect(find.text('网页标题'), findsOneWidget);

    await tester.tap(find.byKey(const Key('webview-back-close-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 120));

    expect(testPlatform.controller.goBackCount, 0);
    expect(find.text('打开 WebView'), findsOneWidget);
    expect(find.text('网页标题'), findsNothing);
  });

  testWidgets('WebView 无效链接状态页也保留顶部退出入口', (tester) async {
    await tester.pumpWidget(
      const FluentApp(
        home: WebViewPage(
          url: 'https://wywh.sspu.edu.cnjavascript:void(0);',
          initialTitle: '无效链接',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('链接无效，无法打开'), findsOneWidget);
    expect(find.byKey(const Key('webview-compact-toolbar')), findsOneWidget);
    expect(find.byKey(const Key('webview-back-close-button')), findsOneWidget);
  });

  testWidgets('公众号登录 WebView 使用紧凑工具栏且标题单行', (tester) async {
    await _configureMobileView(tester);

    try {
      await tester.pumpWidget(const FluentApp(home: WxmpLoginPage()));
      await tester.pump();

      final toolbar = find.byKey(const Key('webview-compact-toolbar'));
      final backCloseButton = find.byKey(
        const Key('webview-back-close-button'),
      );

      expect(toolbar, findsOneWidget);
      expect(backCloseButton, findsOneWidget);
      expect(tester.getSize(toolbar).height, lessThanOrEqualTo(56));
      expect(
        tester.takeException(),
        isNull,
        reason: '公众号登录页工具栏不应在移动窄屏产生 overflow 异常',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _resetMobileView(tester);
    }
  });
}

/// 配置移动端窄屏视口。
Future<void> _configureMobileView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(const Size(390, 844));
}

/// 恢复测试视口。
Future<void> _resetMobileView(WidgetTester tester) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.binding.setSurfaceSize(null);
}

class _TestInAppWebViewPlatform extends InAppWebViewPlatform {
  final _TestPlatformInAppWebViewController controller =
      _TestPlatformInAppWebViewController();

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
    return _TestPlatformInAppWebViewWidget(params, controller);
  }
}

class _TestPlatformInAppWebViewWidget extends PlatformInAppWebViewWidget {
  _TestPlatformInAppWebViewWidget(super.params, this.controller)
    : super.implementation();

  final _TestPlatformInAppWebViewController controller;

  @override
  Widget build(BuildContext context) {
    final appController = params.controllerFromPlatform?.call(controller);
    if (appController is InAppWebViewController &&
        !controller.callbacksDispatched) {
      controller.callbacksDispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        params.onWebViewCreated?.call(appController);
        params.onTitleChanged?.call(appController, '网页标题');
        params.onLoadStop?.call(appController, WebUri('https://example.com'));
      });
    }
    return const ColoredBox(
      key: Key('fake-in-app-webview'),
      color: Color(0xFFEFEFEF),
      child: SizedBox.expand(),
    );
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    return params.controllerFromPlatform!.call(controller) as T;
  }

  @override
  void dispose() {}
}

class _TestPlatformInAppWebViewController
    extends PlatformInAppWebViewController {
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

  @override
  Future<bool> canGoBack() async => canGoBackValue;

  @override
  Future<void> goBack() async {
    goBackCount++;
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

  @override
  Future<WebUri?> getUrl() async => WebUri('https://example.com');
}
