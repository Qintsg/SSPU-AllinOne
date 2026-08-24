/* 清源主导航 — 底栏与导航轨共享同一语义条目。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

class YhNavigationItem {
  const YhNavigationItem({
    required this.icon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final int badge;
}

class YhBottomNav extends StatelessWidget {
  const YhBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<YhNavigationItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border(top: BorderSide(color: theme.color.border)),
      ),
      child: SizedBox(
        height: theme.layout.bottomNavigationHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
          child: Row(
            children: [
              for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
                Expanded(
                  child: _YhNavigationButton(
                    item: items[itemIndex],
                    selected: itemIndex == index,
                    onPressed: () => onChanged(itemIndex),
                    horizontal: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class YhNavRail extends StatelessWidget {
  const YhNavRail({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.extended = false,
    this.header,
    this.footer,
  });

  final List<YhNavigationItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool extended;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border(right: BorderSide(color: theme.color.border)),
      ),
      child: SizedBox(
        width: extended
            ? theme.layout.navRailExpandedWidth
            : theme.layout.navRailCompactWidth,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
          child: Column(
            children: [
              ?header,
              if (header != null)
                SizedBox(height: theme.spacing.l - theme.spacing.xs),
              for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.s,
                    vertical: theme.spacing.xs,
                  ),
                  child: _YhNavigationButton(
                    item: items[itemIndex],
                    selected: itemIndex == index,
                    onPressed: () => onChanged(itemIndex),
                    horizontal: extended,
                  ),
                ),
              const Spacer(),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _YhNavigationButton extends StatelessWidget {
  const _YhNavigationButton({
    required this.item,
    required this.selected,
    required this.onPressed,
    required this.horizontal,
  });

  final YhNavigationItem item;
  final bool selected;
  final VoidCallback onPressed;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = selected ? theme.color.brandStrong : theme.color.muted;
    final label = item.badge > 0
        ? '${item.label}，${item.badge} 条未读'
        : item.label;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onPressed,
      container: true,
      child: ExcludeSemantics(
        child: YhPressable(
          semanticLabel: label,
          onPressed: onPressed,
          builder: (context, state, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? theme.color.brandTint
                  : state.hovered
                  ? theme.color.sunken
                  : theme.color.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(
                theme.radius.m + theme.focus.ringWidth,
              ),
            ),
            child: SizedBox(
              width: horizontal
                  ? double.infinity
                  : theme.control.regular + theme.spacing.m + theme.spacing.xs,
              height: theme.control.regular + theme.spacing.s,
              child: child,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.s,
              vertical: theme.spacing.xs,
            ),
            child: horizontal
                ? Row(
                    children: [
                      Icon(
                        item.icon,
                        size: theme.spacing.l - theme.layout.divider * 3,
                        color: foreground,
                      ),
                      SizedBox(width: theme.spacing.m),
                      Expanded(
                        child: Text(
                          item.label,
                          style: theme.typography.small.copyWith(
                            color: foreground,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: theme.spacing.l - theme.layout.divider * 3,
                        color: foreground,
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
