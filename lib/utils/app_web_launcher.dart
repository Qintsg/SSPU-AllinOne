/*
 * 应用网页打开工具 — iOS 普通网页优先使用系统 Safari View Controller
 * @Project : SSPU-AllinOne
 * @File : app_web_launcher.dart
 * @Author : KsuserKqy
 * @Date : 2026-06-10
 */

import '../design/fluent_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../pages/webview_page.dart';
import '../widgets/app_feedback.dart';
import 'webview_env.dart';

/// 应用内普通网页入口。
///
/// iOS 使用系统 SFSafariViewController（通过 flutter_inappwebview 的
/// ChromeSafariBrowser），并以 page sheet 从当前页面底部拉起，避免为只读文章页
/// 加载完整 Flutter WebView。
/// iOS 打开失败时仅在当前页提示，不 push Flutter 新页面。
/// 需要读取 Cookie / 注入 JS 的流程仍应直接使用 WebViewPage 或专用 WebView 页面。
Future<void> openAppWebUrl(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.tryParse(url.trim());
  final isSupportedWebUrl =
      uri != null &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'http' || uri.scheme == 'https');

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      isSupportedWebUrl) {
    try {
      await ChromeSafariBrowser().open(
        url: WebUri(uri.toString()),
        settings: ChromeSafariBrowserSettings(
          dismissButtonStyle: DismissButtonStyle.CLOSE,
          presentationStyle: ModalPresentationStyle.PAGE_SHEET,
          transitionStyle: ModalTransitionStyle.COVER_VERTICAL,
        ),
      );
      return;
    } catch (error) {
      debugPrint('[AppWebLauncher] Safari View Controller 打开失败: $error');
    }
    if (!context.mounted) return;
    showAppFeedback(
      context,
      message: '无法打开链接',
      severity: AppFeedbackSeverity.warning,
    );
    return;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    if (!context.mounted) return;
    showAppFeedback(
      context,
      message: '链接无效，无法打开',
      severity: AppFeedbackSeverity.warning,
    );
    return;
  }

  final webViewEnvironment = await ensureGlobalWebViewEnvironment();
  if (!context.mounted) return;
  Navigator.of(context).push(
    FluentPageRoute(
      builder: (_) => WebViewPage(
        url: url,
        initialTitle: title,
        webViewEnvironment: webViewEnvironment,
      ),
    ),
  );
}
