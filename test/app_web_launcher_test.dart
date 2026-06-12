/*
 * 应用网页打开工具测试 — 校验 iOS Safari View Controller 与跨平台 WebView 分流
 * @Project : SSPU-AllinOne
 * @File : app_web_launcher_test.dart
 * @Author : KsuserKqy
 * @Date : 2026-06-10
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/design/fluent_ui.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/utils/app_web_launcher.dart';

void main() {
  late InAppWebViewPlatform? previousWebViewPlatform;
  late _TestInAppWebViewPlatform testWebViewPlatform;

  setUp(() {
    previousWebViewPlatform = InAppWebViewPlatform.instance;
    testWebViewPlatform = _TestInAppWebViewPlatform();
    InAppWebViewPlatform.instance = testWebViewPlatform;
  });

  tearDown(() {
    if (previousWebViewPlatform != null) {
      InAppWebViewPlatform.instance = previousWebViewPlatform!;
    }
  });

  testWidgets('iOS 普通网页使用 Safari View Controller 打开', (tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    try {
      await tester.pumpWidget(
        FluentApp(
          home: Builder(
            builder: (context) => FluentButton(
              onPressed: () => openAppWebUrl(
                context,
                url: 'https://example.com/news',
                title: '网页标题',
              ),
              child: const Text('打开网页'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开网页'));
      await tester.pump();

      expect(
        testWebViewPlatform.chromeSafariBrowser.openedUrl?.toString(),
        'https://example.com/news',
      );
      expect(
        testWebViewPlatform.chromeSafariBrowser.openSettings?.presentationStyle,
        ModalPresentationStyle.PAGE_SHEET,
      );
      expect(
        testWebViewPlatform.chromeSafariBrowser.openSettings?.transitionStyle,
        ModalTransitionStyle.COVER_VERTICAL,
      );
      expect(find.byType(WebViewPage), findsNothing);
    } finally {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
    }
  });

  testWidgets('非 iOS 普通网页继续进入 WebViewPage', (tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      await tester.pumpWidget(
        FluentApp(
          home: Builder(
            builder: (context) => FluentButton(
              onPressed: () => openAppWebUrl(
                context,
                url: 'https://example.com/news',
                title: '网页标题',
              ),
              child: const Text('打开网页'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开网页'));
      await tester.pumpAndSettle();

      expect(testWebViewPlatform.chromeSafariBrowser.openedUrl, isNull);
      expect(find.byType(WebViewPage), findsOneWidget);
      expect(
        find.byKey(const Key('fake-app-web-launcher-webview')),
        findsOneWidget,
      );
    } finally {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
    }
  });

  testWidgets('iOS Safari View Controller 打开失败时不进入 WebViewPage', (
    tester,
  ) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    testWebViewPlatform.chromeSafariBrowser.shouldThrowOnOpen = true;

    try {
      await tester.pumpWidget(
        FluentApp(
          home: Builder(
            builder: (context) => FluentButton(
              onPressed: () => openAppWebUrl(
                context,
                url: 'https://example.com/news',
                title: '网页标题',
              ),
              child: const Text('打开网页'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开网页'));
      await tester.pumpAndSettle();

      expect(
        testWebViewPlatform.chromeSafariBrowser.openedUrl?.toString(),
        'https://example.com/news',
      );
      expect(
        testWebViewPlatform.chromeSafariBrowser.openSettings?.presentationStyle,
        ModalPresentationStyle.PAGE_SHEET,
      );
      expect(find.byType(WebViewPage), findsNothing);
      expect(find.text('无法打开链接'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    } finally {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
    }
  });

  testWidgets('iOS 无效网页链接留在原页面并显示反馈', (tester) async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    try {
      await tester.pumpWidget(
        FluentApp(
          home: Builder(
            builder: (context) => FluentButton(
              onPressed: () => openAppWebUrl(
                context,
                url: 'https://wywh.sspu.edu.cnjavascript:void(0);',
                title: '无效链接',
              ),
              child: const Text('打开网页'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开网页'));
      await tester.pumpAndSettle();

      expect(testWebViewPlatform.chromeSafariBrowser.openedUrl, isNull);
      expect(find.byType(WebViewPage), findsNothing);
      expect(find.text('链接无效，无法打开'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    } finally {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
    }
  });
}

class _TestInAppWebViewPlatform extends InAppWebViewPlatform {
  final _TestPlatformInAppWebViewController controller =
      _TestPlatformInAppWebViewController();
  final _TestPlatformChromeSafariBrowser chromeSafariBrowser =
      _TestPlatformChromeSafariBrowser();

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

  @override
  PlatformChromeSafariBrowser createPlatformChromeSafariBrowser(
    PlatformChromeSafariBrowserCreationParams params,
  ) {
    return chromeSafariBrowser;
  }

  @override
  PlatformChromeSafariBrowser createPlatformChromeSafariBrowserStatic() {
    return chromeSafariBrowser;
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
    return const SizedBox.expand(key: Key('fake-app-web-launcher-webview'));
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

  bool callbacksDispatched = false;

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<WebUri?> getUrl() async => WebUri('https://example.com');
}

class _TestPlatformChromeSafariBrowser extends PlatformChromeSafariBrowser {
  _TestPlatformChromeSafariBrowser()
    : super.implementation(const PlatformChromeSafariBrowserCreationParams());

  WebUri? openedUrl;
  ChromeSafariBrowserSettings? openSettings;
  bool shouldThrowOnOpen = false;

  @override
  String get id => 'test-chrome-safari-browser';

  @override
  Future<void> open({
    WebUri? url,
    Map<String, String>? headers,
    List<WebUri>? otherLikelyURLs,
    WebUri? referrer,
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    ChromeSafariBrowserClassOptions? options,
    ChromeSafariBrowserSettings? settings,
  }) async {
    openedUrl = url;
    openSettings = settings;
    if (shouldThrowOnOpen) {
      throw Exception('open failed');
    }
  }

  @override
  bool isOpened() => openedUrl != null && !shouldThrowOnOpen;
}
