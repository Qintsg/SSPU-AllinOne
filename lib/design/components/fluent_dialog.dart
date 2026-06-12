/*
 * Fluent 对话框兼容层 — 包装外部 fluent_ui ContentDialog
 * @Project : SSPU-AllinOne
 * @File : fluent_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

import '../fluent/fluent_context_ext.dart';

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
    final spacing = context.fluentSpacing;
    final radii = context.fluentRadii;
    final type = context.fluentType;
    final colors = context.fluentColors;
    final theme = FluentTheme.of(context);
    final resources = theme.resources;

    return ContentDialog(
      constraints: constraints,
      style: ContentDialogThemeData(
        padding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        actionsDecoration: const BoxDecoration(),
        decoration: BoxDecoration(
          color: theme.menuColor,
          borderRadius: radii.xLargeBorder,
          border: Border.all(color: resources.controlStrokeColorDefault),
        ),
        titleStyle: type.title2,
        bodyStyle: type.body1.copyWith(color: colors.neutralForeground2),
      ),
      content: Padding(
        padding: EdgeInsetsDirectional.all(spacing.xxl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final body = _FluentDialogScrollableContent(child: content);
            final children = <Widget>[
              if (title != null) ...[
                DefaultTextStyle.merge(style: type.title2, child: title!),
                SizedBox(height: spacing.l),
              ],
              if (constraints.hasBoundedHeight) Flexible(child: body) else body,
              if (actions != null && actions!.isNotEmpty) ...[
                SizedBox(height: spacing.xxl),
                _FluentDialogActions(actions: actions!),
              ],
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

/// 对话框底部按钮区。
class _FluentDialogActions extends StatelessWidget {
  const _FluentDialogActions({required this.actions});

  /// 操作按钮。
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = actions.length - 1; index >= 0; index--) ...[
                _expandedAction(actions[index]),
                if (index > 0) SizedBox(height: spacing.s),
              ],
            ],
          );
        }

        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: spacing.s,
            runSpacing: spacing.s,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        );
      },
    );
  }

  Widget _expandedAction(Widget child) {
    return SizedBox(width: double.infinity, child: child);
  }
}

/// 带标题图标和说明的确认弹窗内容。
class FluentDialogMessage extends StatelessWidget {
  const FluentDialogMessage({
    super.key,
    required this.message,
    this.icon,
    this.tone = FluentDialogMessageTone.neutral,
    this.details,
  });

  /// 主说明。
  final String message;

  /// 可选图标。
  final IconData? icon;

  /// 语义色调。
  final FluentDialogMessageTone tone;

  /// 辅助说明。
  final String? details;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    final colors = context.fluentColors;
    final type = context.fluentType;
    final foreground = switch (tone) {
      FluentDialogMessageTone.neutral => colors.brandForeground1,
      FluentDialogMessageTone.warning => colors.statusWarningForeground,
      FluentDialogMessageTone.danger => colors.statusDangerForeground,
    };
    final background = switch (tone) {
      FluentDialogMessageTone.neutral => colors.neutralBackground2,
      FluentDialogMessageTone.warning => colors.statusWarningBackground,
      FluentDialogMessageTone.danger => colors.statusDangerBackground,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Card(
            padding: EdgeInsets.zero,
            borderRadius: context.fluentRadii.mediumBorder,
            backgroundColor: background,
            child: SizedBox.square(
              dimension: 36,
              child: Icon(icon, color: foreground, size: 18),
            ),
          ),
          SizedBox(width: spacing.m),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: type.body1.copyWith(color: colors.neutralForeground1),
              ),
              if (details != null) ...[
                SizedBox(height: spacing.xs),
                Text(
                  details!,
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 确认弹窗说明色调。
enum FluentDialogMessageTone {
  /// 常规说明。
  neutral,

  /// 警告说明。
  warning,

  /// 危险操作说明。
  danger,
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
