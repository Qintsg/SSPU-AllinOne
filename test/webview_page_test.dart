/*
 * WebView 页面测试 — 校验紧凑工具栏与返回/退出行为
 * @Project : SSPU-AllinOne
 * @File : webview_page_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';
import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart' as qingyuan;
import 'package:sspu_allinone/pages/wxmp_login_cookie_reader.dart';
import 'package:sspu_allinone/pages/webview_page.dart';
import 'package:sspu_allinone/pages/wxmp_login_page.dart';
import 'package:sspu_allinone/pages/wxmp_login_test_hooks.dart';
import 'package:sspu_allinone/services/wxmp_article_service.dart';
import 'package:sspu_allinone/services/wxmp_auth_service.dart';

part 'webview_page_test_platform.dart';

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
        const YhApp(
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
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
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
      const YhApp(
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

  testWidgets('WebView 快速重复返回只执行一次网页后退', (tester) async {
    testPlatform.controller.canGoBackValue = true;
    testPlatform.controller.goBackCompletion = Completer<void>();

    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '网页标题',
        ),
      ),
    );
    await tester.pump();

    final back = find.byKey(const Key('webview-back-close-button'));
    await tester.tap(back);
    await tester.tap(back);
    await tester.pump();

    expect(testPlatform.controller.goBackCount, 1);
    testPlatform.controller.goBackCompletion!.complete();
    await tester.pump();
  });

  testWidgets('WebView 系统返回与工具栏协同并优先后退网页历史', (tester) async {
    testPlatform.controller.canGoBackValue = true;

    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '网页标题',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(testPlatform.controller.goBackCount, 1);
    expect(find.byType(WebViewPage), findsOneWidget);
  });

  testWidgets('WebView 主文档失败时不虚报已外部打开并提供原地恢复', (tester) async {
    testPlatform.controller.mainFrameErrorDescription = 'network unavailable';

    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('网页加载失败'), findsOneWidget);
    expect(find.textContaining('network unavailable'), findsOneWidget);
    expect(find.textContaining('已在默认浏览器中打开'), findsNothing);
    expect(find.text('重新加载'), findsOneWidget);
    expect(find.text('在浏览器中打开'), findsOneWidget);

    await tester.tap(find.text('重新加载'));
    await tester.pump();

    expect(testPlatform.widgetCreationCount, 2);
    expect(testPlatform.controller.reloadCount, 0);
    expect(find.text('网页加载失败'), findsNothing);
  });

  testWidgets('WebView 重定向失败时原地重试失败请求地址', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
        ),
      ),
    );
    await tester.pump();

    await testPlatform.controller.failMainFrame(
      'https://example.com/next',
      'network unavailable',
    );
    await tester.pump();
    await tester.tap(find.text('重新加载'));
    await tester.pump();

    expect(testPlatform.createdUrls.last, 'https://example.com/next');
  });

  testWidgets('WebView 运行时未创建时转入可恢复错误而不是永久等待', (tester) async {
    testPlatform.dispatchCallbacks = false;

    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
          initializationTimeout: Duration(milliseconds: 20),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('网页加载失败'), findsOneWidget);
    expect(find.textContaining('WebView 运行时未响应'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
  });

  testWidgets('WebView 外部打开单飞且失败后保留当前网页与重试入口', (tester) async {
    final completion = Completer<bool>();
    var launchCount = 0;

    await tester.pumpWidget(
      YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
          launchUrlOverride: (_) {
            launchCount++;
            return completion.future;
          },
        ),
      ),
    );
    await tester.pump();

    final externalAction = find.bySemanticsLabel('在浏览器中打开');
    await tester.tap(externalAction);
    await tester.pumpAndSettle();

    expect(find.text('在系统浏览器中打开？'), findsOneWidget);
    expect(find.textContaining('example.com'), findsOneWidget);
    expect(find.textContaining('不再受本应用的本地保护'), findsOneWidget);
    expect(launchCount, 0);

    await tester.tap(find.text('继续打开'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('刷新'));
    await tester.pump();

    expect(launchCount, 1);
    expect(testPlatform.controller.reloadCount, 0);
    expect(find.textContaining('正在交给系统浏览器'), findsOneWidget);
    expect(find.byKey(const Key('fake-in-app-webview')), findsOneWidget);

    completion.complete(false);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('系统浏览器未能打开校园网页'), findsOneWidget);
    expect(find.byKey(const Key('fake-in-app-webview')), findsOneWidget);

    await tester.tap(externalAction);
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pump();
    expect(launchCount, 2);
  });

  testWidgets('WebView 导航后丢弃旧 URL 的外部打开失败结果', (tester) async {
    final completion = Completer<bool>();
    await tester.pumpWidget(
      YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
          launchUrlOverride: (_) => completion.future,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('在浏览器中打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pump();

    await testPlatform.controller.visit('https://example.com/next');
    await tester.pump();
    completion.complete(false);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('系统浏览器未能打开校园网页'), findsNothing);
    expect(find.byKey(const Key('fake-in-app-webview')), findsOneWidget);
  });

  testWidgets('WebView 导航到新地址时清除旧页面的外部打开失败', (tester) async {
    await tester.pumpWidget(
      YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
          launchUrlOverride: (_) async => false,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('在浏览器中打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续打开'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('系统浏览器未能打开校园网页'), findsOneWidget);

    await testPlatform.controller.visit('https://example.com/next');
    await tester.pump();

    expect(find.textContaining('系统浏览器未能打开校园网页'), findsNothing);
    expect(find.byKey(const Key('fake-in-app-webview')), findsOneWidget);
  });

  testWidgets('WebView 取消外部打开时保留网页且不启动系统浏览器', (tester) async {
    var launchCount = 0;
    await tester.pumpWidget(
      YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '校园网页',
          launchUrlOverride: (_) async {
            launchCount++;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('在浏览器中打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(launchCount, 0);
    expect(find.byKey(const Key('fake-in-app-webview')), findsOneWidget);
    expect(find.byType(WebViewPage), findsOneWidget);
  });

  testWidgets('WebView 无效链接仍保留刷新与外部打开工具栏动作', (tester) async {
    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(url: 'invalid-url', initialTitle: '校园服务'),
      ),
    );

    expect(find.text('链接无效，无法打开'), findsOneWidget);
    expect(find.bySemanticsLabel('刷新'), findsOneWidget);
    expect(find.bySemanticsLabel('在浏览器中打开'), findsOneWidget);
  });

  testWidgets('WebView 返回按钮无网页历史时退出当前路由', (tester) async {
    testPlatform.controller.canGoBackValue = false;

    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开 WebView',
            onTap: () {
              Navigator.of(context).push(
                YhPageRoute(
                  builder: (_) => const WebViewPage(
                    url: 'https://example.com/news',
                    initialTitle: '网页标题',
                  ),
                ),
              );
            },
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

  testWidgets('WebView 历史能力异常时返回仍安全退出当前路由', (tester) async {
    testPlatform.controller.canGoBackError = StateError('controller disposed');

    await tester.pumpWidget(
      YhApp(
        home: Builder(
          builder: (context) => YhButton(
            label: '打开异常 WebView',
            onTap: () => Navigator.of(context).push(
              YhPageRoute(
                builder: (_) => const WebViewPage(
                  url: 'https://example.com/news',
                  initialTitle: '网页标题',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开异常 WebView'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('webview-back-close-button')));
    await tester.pumpAndSettle();

    expect(find.text('打开异常 WebView'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WebView 根路由无法退出后下一次系统返回仍重新检查网页历史', (tester) async {
    testPlatform.controller.canGoBackValue = false;
    await tester.pumpWidget(
      const YhApp(
        home: WebViewPage(
          url: 'https://example.com/news',
          initialTitle: '网页标题',
        ),
      ),
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();

    testPlatform.controller.canGoBackValue = true;
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(testPlatform.controller.goBackCount, 1);
  });

  testWidgets('WebView 无效链接状态页也保留顶部退出入口', (tester) async {
    await tester.pumpWidget(
      const YhApp(
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
      await tester.pumpWidget(const qingyuan.YhApp(home: WxmpLoginPage()));
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

  testWidgets('公众号登录加载期间显示进度并锁定刷新和外部打开', (tester) async {
    testPlatform.dispatchCallbacks = false;
    await tester.pumpWidget(const qingyuan.YhApp(home: WxmpLoginPage()));
    await tester.pump();

    expect(find.text('正在打开微信登录页'), findsOneWidget);
    final toolbar = find.byKey(const Key('webview-compact-toolbar'));
    final buttons = find.descendant(
      of: toolbar,
      matching: find.byType(qingyuan.YhIconButton),
    );
    expect(tester.widget<qingyuan.YhIconButton>(buttons.at(1)).onTap, isNull);
    expect(tester.widget<qingyuan.YhIconButton>(buttons.at(2)).onTap, isNull);
  });

  testWidgets('公众号登录 WebView 就绪后显示认证接力条与保存边界', (tester) async {
    await tester.pumpWidget(const qingyuan.YhApp(home: WxmpLoginPage()));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('请使用拥有公众号的微信账号扫码登录'), findsOneWidget);
    expect(find.textContaining('连接信息只在校验通过后保存到本机'), findsOneWidget);
  });

  testWidgets('刷新后旧 WebView token 回调不会越过当前页面闸门', (tester) async {
    var detectedTokens = 0;
    await tester.pumpWidget(
      qingyuan.YhApp(
        home: WxmpLoginPage(
          onTokenDetectedForTesting: (_) => detectedTokens += 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final oldLoadStop = testPlatform.controller.onLoadStop;
    expect(oldLoadStop, isNotNull);
    await tester.tap(find.bySemanticsLabel('刷新微信登录页'));
    await tester.pump();
    oldLoadStop?.call(
      testPlatform.controller.appController!,
      WebUri('https://mp.weixin.qq.com/cgi-bin/home?token=123'),
    );
    await tester.pump();

    expect(detectedTokens, 0);
  });

  testWidgets('候选 Cookie 写入后后续空读取会先恢复原连接', (tester) async {
    var readCount = 0;
    var saveCount = 0;
    var restoreCount = 0;
    await tester.pumpWidget(
      qingyuan.YhApp(
        home: WxmpLoginPage(
          testOverrides: WxmpLoginTestOverrides(
            captureAuth: () async => const WxmpAuthSnapshot(
              cookie: 'old-cookie',
              token: '123456',
              lastUpdate: null,
            ),
            readCookies:
                ({
                  required successUrl,
                  required controller,
                  webViewEnvironment,
                }) async {
                  readCount++;
                  if (readCount == 1) {
                    return const WxmpCookieReadResult(
                      cookieMap: {'candidate': 'cookie'},
                      cookieNames: {'candidate'},
                    );
                  }
                  return const WxmpCookieReadResult(
                    cookieMap: {},
                    cookieNames: {},
                  );
                },
            saveAuth: (cookie, token) async {
              saveCount++;
            },
            validateAuth: () async => const WxmpAuthValidationResult(
              isValid: false,
              message: '候选认证无效',
            ),
            restoreAuth: (snapshot) async {
              restoreCount++;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final onLoadStop = testPlatform.controller.onLoadStop;
    final controller = testPlatform.controller.appController;
    expect(onLoadStop, isNotNull);
    expect(controller, isNotNull);
    onLoadStop!(
      controller!,
      WebUri('https://mp.weixin.qq.com/cgi-bin/home?token=123456'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(saveCount, 1);
    expect(restoreCount, 1);
    expect(find.textContaining('未再次获取到 Cookie；已恢复原连接'), findsOneWidget);
  });

  testWidgets('公众号登录主页面加载失败时提供明确重试入口', (tester) async {
    testPlatform.controller.mainFrameErrorDescription = 'network unavailable';
    await tester.pumpWidget(const qingyuan.YhApp(home: WxmpLoginPage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('无法打开微信登录页'), findsOneWidget);
    expect(find.textContaining('network unavailable'), findsOneWidget);
    expect(find.text('重新打开登录页'), findsOneWidget);
  });

  testWidgets('公众号登录工具栏可刷新过期二维码', (tester) async {
    await tester.pumpWidget(const qingyuan.YhApp(home: WxmpLoginPage()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('刷新微信登录页'));
    await tester.pump();

    expect(testPlatform.controller.reloadCount, 1);
  });

  testWidgets('系统浏览器打开失败时说明认证不会自动回写', (tester) async {
    await tester.pumpWidget(
      qingyuan.YhApp(
        home: WxmpLoginPage(launchUrlOverride: (_) async => false),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('在系统浏览器打开微信登录页'));
    await tester.pumpAndSettle();
    expect(find.textContaining('不与应用内登录页共享认证结果'), findsOneWidget);
    await tester.tap(find.text('继续打开'));
    await tester.pumpAndSettle();

    expect(find.textContaining('系统浏览器未能打开微信登录页'), findsOneWidget);
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
