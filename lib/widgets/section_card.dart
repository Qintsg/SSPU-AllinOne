/*
 * Fluent 2 通用分区卡片 — 统一页面分区容器样式
 * @Project : SSPU-AllinOne
 * @File : section_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import '../design/fluent_ui.dart';

import '../theme/app_spacing.dart';

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
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = AppSpacing.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasHeader = title != null || subtitle != null || trailing != null;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Semantics(
                            header: true,
                            child: Text(title!, style: textTheme.titleMedium),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
