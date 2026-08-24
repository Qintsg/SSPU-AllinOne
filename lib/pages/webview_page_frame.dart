/*
 * WebView 页面框架与失败恢复区 — 纯展示，生产插件与视觉 fixture 共用
 * @Project : SSPU-AllinOne
 * @File : webview_page_frame.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

import '../design/qingyuan/qingyuan_ui.dart';

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
