/*
 * 应用导航项 — 移动端底部导航项兼容层
 * @Project : SSPU-AllinOne
 * @File : app_navigation_items.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

part of 'app.dart';

class _FluentBottomNavigationItem extends StatelessWidget {
  const _FluentBottomNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final type = context.fluentType;
    final radii = context.fluentRadii;
    final foreground = selected
        ? theme.activeColor
        : resources.textFillColorSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.title,
      onTap: onTap,
      child: ExcludeSemantics(
        child: HoverButton(
          onPressed: onTap,
          builder: (context, states) {
            final background = selected
                ? theme.accentColor.defaultBrushFor(theme.brightness)
                : states.isPressed
                ? resources.subtleFillColorTertiary
                : states.isHovered || states.isFocused
                ? resources.subtleFillColorSecondary
                : Colors.transparent;

            return Card(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              borderRadius: radii.largeBorder,
              backgroundColor: background,
              borderColor: states.isFocused
                  ? theme.accentColor.defaultBrushFor(theme.brightness)
                  : Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: foreground,
                    size: 20,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    destination.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption1.copyWith(color: foreground),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
