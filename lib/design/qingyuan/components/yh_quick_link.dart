/* 清源快捷入口磁贴。 */

import 'package:flutter/widgets.dart';

import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_card.dart';
import 'yh_icon_button.dart';

class YhQuickLink extends StatelessWidget {
  const YhQuickLink({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.favorite = false,
    this.onToggleFavorite,
    this.width,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool favorite;
  final VoidCallback? onToggleFavorite;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          YhCard(
            semanticLabel: '$label，外部链接，将打开外部应用',
            onTap: onTap,
            padding: EdgeInsets.all(theme.spacing.m),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: theme.control.regular * 2 + theme.spacing.s,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        color.withValues(alpha: theme.opacity.domainTint),
                        theme.color.surface,
                      ),
                      borderRadius: BorderRadius.circular(theme.radius.input),
                    ),
                    child: SizedBox.square(
                      dimension: theme.control.regular,
                      child: Icon(icon, size: theme.spacing.l, color: color),
                    ),
                  ),
                  SizedBox(height: theme.spacing.s),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: subtitle == null ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.copyWith(
                      color: theme.color.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onToggleFavorite != null)
            PositionedDirectional(
              top: theme.spacing.xs,
              end: theme.spacing.xs,
              child: YhIconButton(
                icon: favorite ? YhIcons.favoriteFilled : YhIcons.favorite,
                semanticLabel: favorite ? '取消常用入口' : '标记为常用入口',
                variant: YhIconButtonVariant.ghost,
                onTap: onToggleFavorite,
              ),
            ),
        ],
      ),
    );
  }
}
