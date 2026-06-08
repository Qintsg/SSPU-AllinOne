/*
 * Fluent 对话框兼容层 — 包装外部 fluent_ui ContentDialog
 * @Project : SSPU-AllinOne
 * @File : fluent_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

/// Fluent 对话框容器。
class FluentDialog extends StatelessWidget {
  const FluentDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.constraints = const BoxConstraints(maxWidth: 480),
  });

  /// 标题内容。
  final Widget? title;

  /// 主体内容。
  final Widget content;

  /// 底部操作按钮。
  final List<Widget>? actions;

  /// 尺寸约束。
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: constraints,
      child: ContentDialog(
        title: title,
        content: _FluentDialogScrollableContent(child: content),
        actions: actions,
      ),
    );
  }
}

/// 对话框内容滚动区，显式共享控制器给滚动视图和滚动条。
class _FluentDialogScrollableContent extends StatefulWidget {
  const _FluentDialogScrollableContent({required this.child});

  /// 主体内容。
  final Widget child;

  @override
  State<_FluentDialogScrollableContent> createState() =>
      _FluentDialogScrollableContentState();
}

class _FluentDialogScrollableContentState
    extends State<_FluentDialogScrollableContent> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        primary: false,
        child: widget.child,
      ),
    );
  }
}

/// 以 Fluent 视觉弹出对话框。
Future<T?> showFluentDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
