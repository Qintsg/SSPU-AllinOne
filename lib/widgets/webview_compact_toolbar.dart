/*
 * WebView 紧凑工具栏 — 为内嵌网页页面提供稳定返回入口与低高度标题栏
 * @Project : SSPU-AllinOne
 * @File : webview_compact_toolbar.dart
 * @Author : Qintsg
 * @Date : 2026-06-07
 */

import '../design/qingyuan/qingyuan_ui.dart';

/// WebView 页面紧凑工具栏。
class WebViewCompactToolbar extends StatelessWidget {
  const WebViewCompactToolbar({
    super.key = const Key('webview-compact-toolbar'),
    required this.title,
    required this.onBackPressed,
    this.backSemanticLabel = '返回',
    this.actions = const [],
  });

  /// 当前页面标题。
  final String title;

  /// 返回或退出按钮回调。
  final VoidCallback onBackPressed;

  /// 返回按钮语义标签。
  final String backSemanticLabel;

  /// 右侧操作按钮。
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return YhAppBar(
      title: title,
      leading: YhIconButton(
        key: const Key('webview-back-close-button'),
        icon: YhIcons.back,
        semanticLabel: backSemanticLabel,
        variant: YhIconButtonVariant.ghost,
        onTap: onBackPressed,
      ),
      actions: actions,
    );
  }
}
