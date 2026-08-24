/*
 * 清源通用分区卡片 — 统一页面分区容器样式
 * @Project : SSPU-AllinOne
 * @File : section_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import '../design/qingyuan/qingyuan_ui.dart';

/// 页面通用分区卡片。
class SectionCard extends StatelessWidget {
  /// 标题文本。
  final String? title;

  /// 副标题或辅助说明。
  final String? subtitle;

  /// 标题前图标。
  final IconData? icon;

  /// 右上角操作区。
  final Widget? trailing;

  /// 卡片主体。
  final Widget child;

  /// 卡片内边距。
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final hasHeader = title != null || subtitle != null || trailing != null;

    return YhCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: theme.color.brandStrong),
                  SizedBox(width: theme.spacing.s),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: theme.typography.h3.copyWith(
                              color: theme.color.foreground,
                            ),
                          ),
                        ),
                      if (subtitle != null) ...[
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          subtitle!,
                          style: theme.typography.caption.copyWith(
                            color: theme.color.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: theme.spacing.m),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: theme.spacing.m),
          ],
          child,
        ],
      ),
    );
  }
}
