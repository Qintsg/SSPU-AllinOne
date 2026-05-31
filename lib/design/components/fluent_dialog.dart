/*
 * Fluent 2 对话框 — radiusXLarge + shadow28，令牌驱动
 * @Project : SSPU-AllinOne
 * @File : fluent_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * DESIGN.md §6.4：FluentDialog（radiusXLarge + shadow28）。
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 对话框容器。
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
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final elevation = context.fluentElevation;
    final type = context.fluentType;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: constraints,
          child: Container(
            margin: EdgeInsets.all(spacing.xxl),
            decoration: BoxDecoration(
              color: colors.neutralBackground1,
              borderRadius: radii.xLargeBorder,
              boxShadow: elevation.shadow28,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    DefaultTextStyle.merge(
                      style: type.subtitle1.copyWith(
                        color: colors.neutralForeground1,
                      ),
                      child: title!,
                    ),
                    SizedBox(height: spacing.m),
                  ],
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: type.body1.copyWith(
                        color: colors.neutralForeground2,
                      ),
                      child: SingleChildScrollView(child: content),
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty) ...[
                    SizedBox(height: spacing.xxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < actions!.length; i++) ...[
                          if (i > 0) SizedBox(width: spacing.s),
                          actions![i],
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
    barrierColor: const Color(0x99000000),
    builder: builder,
  );
}
