/*
 * 清源五平台原生能力集成冒烟
 * @Project : SSPU-AllinOne
 * @File : qingyuan_platform_smoke_test.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sspu_allinone/services/system_auth_service.dart';
import 'package:sspu_allinone/utils/webview_env.dart';
import 'package:window_manager/window_manager.dart';

const _minimalPdfBase64 =
    'JVBERi0xLjQKMSAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgMiAwIFI+PgplbmRvYmoK'
    'MiAwIG9iago8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PgplbmRvYmoKMyAw'
    'IG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDIgMCBSL01lZGlhQm94WzAgMCAyMDAgMjAwXT4+'
    'CmVuZG9iagp4cmVmCjAgNAowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwMDkgMDAwMDAg'
    'biAKMDAwMDAwMDA1OCAwMDAwMCBuIAowMDAwMDAwMTE1IDAwMDAwIG4gCnRyYWlsZXIKPDwv'
    'U2l6ZSA0L1Jvb3QgMSAwIFI+PgpzdGFydHhyZWYKMTkwCiUlRU9GCg==';

/// 注册五个平台真实 runner 的原生能力冒烟。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('平台目录与安全存储插件完成可逆读写', (tester) async {
    final temporaryDirectory = await getTemporaryDirectory();
    expect(await temporaryDirectory.exists(), isTrue);

    const storage = FlutterSecureStorage();
    const key = 'qingyuan_platform_smoke';
    try {
      await storage.delete(key: key);
      await storage.write(key: key, value: 'ready');
      expect(await storage.read(key: key), 'ready');
    } on MissingPluginException catch (error) {
      fail('flutter_secure_storage 未注册：$error');
    } on PlatformException {
      if (!Platform.isLinux) rethrow;
      // 无桌面密钥环的 Linux CI 会拒绝存储；插件已注册且应用应走凭据不可用降级。
    } finally {
      try {
        await storage.delete(key: key);
      } on PlatformException {
        if (!Platform.isLinux) rethrow;
      }
    }
  });

  testWidgets('系统认证插件可探测并在不支持平台安全降级', (tester) async {
    final service = SystemAuthService.instance;
    if (Platform.isLinux) {
      expect(service.isPlatformSupported, isFalse);
      expect(await service.isAvailable(), isFalse);
      return;
    }

    expect(service.isPlatformSupported, isTrue);
    try {
      final pluginAvailable = await LocalAuthentication().isDeviceSupported();
      expect(await service.isAvailable(), pluginAvailable);
      if (!pluginAvailable) {
        expect(
          await service.authenticate(localizedReason: '验证清源系统认证降级路径'),
          SystemAuthResult.unavailable,
        );
      }
    } on MissingPluginException catch (error) {
      fail('local_auth 未注册：$error');
    } on PlatformException {
      expect(await service.isAvailable(), isFalse);
    }
  });

  testWidgets('PDF 引擎可打开并释放确定性单页文档', (tester) async {
    await pdfrxFlutterInitialize();
    final document = await PdfDocument.openData(
      base64Decode(_minimalPdfBase64),
      sourceName: 'qingyuan-platform-smoke.pdf',
    );
    try {
      expect(document.pages.length, 1);
    } finally {
      await document.dispose();
    }
  });

  testWidgets('内嵌网页完成打开、刷新与返回生命周期', (tester) async {
    if (Platform.isLinux) {
      expect(await ensureGlobalWebViewEnvironment(), isNull);
      return;
    }

    final environment = Platform.isWindows
        ? await ensureGlobalWebViewEnvironment()
        : null;
    final loads = StreamController<void>.broadcast();
    final webView = HeadlessInAppWebView(
      webViewEnvironment: environment,
      initialUrlRequest: URLRequest(url: _dataUrl('清源插件冒烟 · 首页', 'first')),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: false,
      ),
      onLoadStop: (controller, url) => loads.add(null),
    );

    /// 执行一次 WebView 动作并等待对应加载完成事件。
    ///
    /// :param action: 会触发新一轮文档加载的异步动作。
    /// :returns: 动作及对应加载事件均完成时结束。
    Future<void> runAndWait(Future<void> Function() action) async {
      final loaded = loads.stream.first.timeout(const Duration(seconds: 30));
      await action();
      await loaded;
    }

    try {
      await runAndWait(webView.run);
      final controller = webView.webViewController;
      expect(controller, isNotNull);
      expect(await _documentTitle(controller!), '清源插件冒烟 · 首页');

      await runAndWait(controller.reload);
      await runAndWait(
        () => controller.loadUrl(
          urlRequest: URLRequest(url: _dataUrl('清源插件冒烟 · 次页', 'second')),
        ),
      );
      expect(await _documentTitle(controller), '清源插件冒烟 · 次页');
      expect(await controller.canGoBack(), isTrue);

      await runAndWait(controller.goBack);
      expect(await _documentTitle(controller), '清源插件冒烟 · 首页');
    } finally {
      await webView.dispose();
      await loads.close();
      if (Platform.isWindows) await disposeGlobalWebViewEnvironment();
    }
  });

  testWidgets('桌面窗口插件可读取真实 runner 状态', (tester) async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

    await windowManager.ensureInitialized();
    final size = await windowManager.getSize();
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
    await windowManager.isMaximized();
    final originalPreventClose = await windowManager.isPreventClose();
    try {
      await windowManager.setPreventClose(!originalPreventClose);
      expect(await windowManager.isPreventClose(), !originalPreventClose);
    } finally {
      await windowManager.setPreventClose(originalPreventClose);
    }
  });
}

/// 构造无需网络的确定性 WebView 文档。
///
/// :param title: 页面标题。
/// :param marker: 正文标记。
/// :returns: 可由平台 WebView 打开的 data URL。
WebUri _dataUrl(String title, String marker) {
  final html =
      '<!doctype html><html><head><title>$title</title></head>'
      '<body data-marker="$marker">$marker</body></html>';
  return WebUri('data:text/html;charset=utf-8,${Uri.encodeComponent(html)}');
}

/// 读取 WebView 当前文档标题。
///
/// :param controller: 已完成加载的 WebView 控制器。
/// :returns: 当前文档标题；脚本未返回值时为空字符串。
Future<String> _documentTitle(InAppWebViewController controller) async {
  final value = await controller.evaluateJavascript(source: 'document.title');
  return value?.toString() ?? '';
}
