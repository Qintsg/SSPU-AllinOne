/*
 * 快捷入口目录行 — 外部打开与独立收藏操作
 * @Project : SSPU-AllinOne
 * @File : quick_links_row.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'quick_links_page.dart';

class _QuickLinkDirectoryRow extends StatelessWidget {
  const _QuickLinkDirectoryRow({
    required this.item,
    required this.icon,
    required this.color,
    required this.description,
    required this.favorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  final QuickLinkItemConfig item;
  final IconData icon;
  final Color color;
  final String description;
  final bool favorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        Expanded(
          child: YhPressable(
            semanticLabel: item.kind == QuickLinkKind.app
                ? '${item.name}，应用链接，将打开目标应用'
                : '${item.name}，外部链接，将打开外部应用',
            onPressed: onOpen,
            builder: (context, state, child) => Container(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.s,
                theme.spacing.s,
                0,
                theme.spacing.s,
              ),
              decoration: BoxDecoration(
                color: state.hovered || state.focused
                    ? theme.color.sunken
                    : null,
                borderRadius: BorderRadius.circular(theme.radius.input),
              ),
              child: Row(
                children: [
                  Container(
                    width: theme.control.regular - theme.spacing.xs,
                    height: theme.control.regular - theme.spacing.xs,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        color.withValues(alpha: theme.opacity.domainTint),
                        theme.color.surface,
                      ),
                      borderRadius: BorderRadius.circular(theme.radius.input),
                    ),
                    child: Icon(icon, size: theme.spacing.l, color: color),
                  ),
                  SizedBox(width: theme.spacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.copyWith(
                            fontWeight: theme.typography.semibold,
                          ),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.caption.copyWith(
                            color: theme.color.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    YhIcons.externalIndicator,
                    style: theme.typography.body.copyWith(
                      color: theme.color.muted,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                    ),
                  ),
                ],
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
        YhIconButton(
          icon: favorite ? YhIcons.favoriteFilled : YhIcons.favorite,
          semanticLabel: favorite ? '取消收藏${item.name}' : '收藏${item.name}',
          variant: YhIconButtonVariant.ghost,
          onTap: onToggleFavorite,
        ),
      ],
    );
  }
}
