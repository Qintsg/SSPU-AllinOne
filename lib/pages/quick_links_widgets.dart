/*
 * 快速跳转组件 — 链接磁贴与配色角色
 * @Project : SSPU-AllinOne
 * @File : quick_links_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'quick_links_page.dart';

enum _QuickLinkColorRole {
  brand,
  brandAlt,
  info,
  success,
  caution,
  neutral,
  critical,
}

/// 快捷链接砖块组件。
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final String url;
  final Future<void> Function(String) onTap;
  final bool favorite;
  final VoidCallback onToggleFavorite;

  /// 磁贴宽度（响应式调整）。
  final double width;

  const _LinkTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.url,
    required this.onTap,
    required this.favorite,
    required this.onToggleFavorite,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Stack(
      children: [
        FluentSurface(
          width: width,
          minHeight: 122,
          accentColor: color,
          padding: const EdgeInsets.all(FluentSpacing.l),
          onPressed: () => onTap(url),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: context.fluentRadii.mediumBorder,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: FluentSpacing.s),
              Text(
                label,
                style: theme.typography.body?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: subtitle == null ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: FluentSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        PositionedDirectional(
          top: FluentSpacing.xs,
          end: FluentSpacing.xs,
          child: Tooltip(
            message: favorite ? '取消常用入口' : '标记为常用入口',
            child: IconButton(
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                iconSize: const WidgetStatePropertyAll(14),
                backgroundColor: WidgetStatePropertyAll(
                  theme.cardColor.withValues(alpha: 0.82),
                ),
                foregroundColor: WidgetStatePropertyAll(color),
              ),
              onPressed: onToggleFavorite,
              icon: Icon(
                favorite ? FluentIcons.favoriteFilled : FluentIcons.favorite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
