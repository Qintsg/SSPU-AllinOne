/* 清源快捷入口磁贴。 */

import 'package:flutter/widgets.dart';

import '../icons/yh_icons.dart';
import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';
import 'yh_card.dart';
import 'yh_icon_button.dart';

enum YhQuickLinkVariant { tile, compact, row }

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
    this.variant = YhQuickLinkVariant.tile,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool favorite;
  final VoidCallback? onToggleFavorite;
  final double? width;
  final YhQuickLinkVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (variant == YhQuickLinkVariant.row) {
      return SizedBox(
        width: width,
        child: YhPressable(
          semanticLabel: '$label，外部链接，将打开外部应用',
          onPressed: onTap,
          builder: (context, state, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: state.hovered
                  ? theme.color.brandTint
                  : theme.color.brandTint.withValues(
                      alpha: theme.opacity.contentMuted,
                    ),
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
              child: child,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: theme.spacing.l, color: color),
              SizedBox(width: theme.spacing.s),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.copyWith(
                        color: theme.color.brandInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (variant == YhQuickLinkVariant.compact) {
      return SizedBox(
        width: width,
        child: YhPressable(
          semanticLabel: '$label，外部链接，将打开外部应用',
          onPressed: onTap,
          builder: (context, state, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: state.hovered
                  ? theme.color.brandTint
                  : theme.color.surface,
              border: Border.all(
                color: state.hovered ? theme.color.brand : theme.color.border,
                width: theme.layout.divider,
              ),
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: theme.control.regular,
                minWidth: theme.control.minimumTarget,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
                child: child,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: theme.spacing.l - theme.spacing.xs,
                color: theme.color.foreground,
              ),
              SizedBox(width: theme.spacing.s),
              Text(label, style: theme.typography.body),
              SizedBox(width: theme.spacing.s),
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
      );
    }
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
