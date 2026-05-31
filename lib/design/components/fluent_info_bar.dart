/*
 * Fluent 2 信息条 — 状态语义 + 图标，不以颜色为唯一信息
 * @Project : SSPU-AllinOne
 * @File : fluent_info_bar.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * DESIGN.md §3.2.4 / §7：状态色只表达状态语义，并同时辅以图标。
 */

import 'package:flutter/material.dart';

import '../fluent/fluent_context_ext.dart';

/// 信息条严重级别。
enum FluentInfoSeverity { info, success, warning, error }

/// Fluent 2 信息条。
class FluentInfoBar extends StatelessWidget {
  const FluentInfoBar({
    super.key,
    required this.title,
    this.content,
    this.severity = FluentInfoSeverity.info,
    this.action,
  });

  /// 标题。
  final Widget title;

  /// 详情内容。
  final Widget? content;

  /// 严重级别。
  final FluentInfoSeverity severity;

  /// 右侧操作。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final type = context.fluentType;

    final (Color fg, Color bg, IconData icon) = switch (severity) {
      FluentInfoSeverity.info => (
          colors.brandForeground1,
          colors.neutralBackground3,
          Icons.info_outline,
        ),
      FluentInfoSeverity.success => (
          colors.statusSuccessForeground,
          colors.statusSuccessBackground,
          Icons.check_circle_outline,
        ),
      FluentInfoSeverity.warning => (
          colors.statusWarningForeground,
          colors.statusWarningBackground,
          Icons.warning_amber_outlined,
        ),
      FluentInfoSeverity.error => (
          colors.statusDangerForeground,
          colors.statusDangerBackground,
          Icons.error_outline,
        ),
    };

    return Container(
      padding: EdgeInsets.all(spacing.m),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radii.mediumBorder,
        border: Border.all(color: fg, width: stroke.thin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 18),
          SizedBox(width: spacing.s),
          Expanded(
            child: DefaultTextStyle.merge(
              style: type.body1.copyWith(color: colors.neutralForeground1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: type.body1Strong.copyWith(color: fg),
                    child: title,
                  ),
                  if (content != null) ...[
                    SizedBox(height: spacing.xxs),
                    content!,
                  ],
                ],
              ),
            ),
          ),
          if (action != null) ...[
            SizedBox(width: spacing.s),
            action!,
          ],
        ],
      ),
    );
  }
}
