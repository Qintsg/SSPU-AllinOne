/* 清源容器与反馈扩展。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';
import 'yh_disclosure.dart';

class YhTile extends StatelessWidget {
  const YhTile({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: semanticLabel ?? '打开项目',
      selected: selected,
      onPressed: onTap,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? theme.color.brandTint
              : state.hovered
              ? theme.color.sunken
              : theme.color.surface,
          border: Border.all(
            color: selected ? theme.color.brand : theme.color.border,
          ),
          borderRadius: BorderRadius.circular(theme.radius.tile),
        ),
        child: Padding(padding: EdgeInsets.all(theme.spacing.m), child: child),
      ),
      child: child,
    );
  }
}

class YhListItem extends StatelessWidget {
  const YhListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhTile(
      semanticLabel: title,
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: theme.spacing.m)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.body.copyWith(
                    color: theme.color.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    subtitle!,
                    style: theme.typography.small.copyWith(
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
    );
  }
}

class YhAccordion extends StatelessWidget {
  const YhAccordion({
    super.key,
    required this.title,
    required this.content,
    this.leadingIcon,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget content;
  final IconData? leadingIcon;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => YhDisclosure(
    title: title,
    content: content,
    leadingIcon: leadingIcon,
    initiallyExpanded: initiallyExpanded,
  );
}

class YhToast extends StatelessWidget {
  const YhToast({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.structural,
          borderRadius: BorderRadius.circular(theme.radius.m),
          boxShadow: theme.elevation.e2,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  message,
                  style: theme.typography.body.copyWith(
                    color: theme.color.onStructural,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                SizedBox(width: theme.spacing.m),
                YhPressable(
                  semanticLabel: actionLabel!,
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: theme.typography.body.copyWith(
                      color: theme.color.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class YhSkeleton extends StatelessWidget {
  const YhSkeleton({
    super.key,
    this.width = double.infinity,
    this.height,
    this.semanticLabel = '内容加载中',
  });

  final double width;
  final double? height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height ?? theme.control.compact,
          decoration: BoxDecoration(
            color: theme.color.border.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(theme.radius.s),
          ),
        ),
      ),
    );
  }
}
