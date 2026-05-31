/*
 * 应用导航项 — 自定义 Fluent 2 底部 / 侧边导航交互项
 * @Project : SSPU-AllinOne
 * @File : app_navigation_items.dart
 * @Author : Qintsg
 * @Date : 2026-05-31
 */

part of 'app.dart';

class _FluentBottomNavigationItem extends StatefulWidget {
  const _FluentBottomNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FluentBottomNavigationItem> createState() =>
      _FluentBottomNavigationItemState();
}

class _FluentBottomNavigationItemState
    extends State<_FluentBottomNavigationItem> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final radii = context.fluentRadii;
    final motion = context.fluentMotion;
    final stroke = context.fluentStroke;
    final foreground = widget.selected
        ? colors.neutralForegroundOnBrand
        : colors.neutralForeground2;
    final background = widget.selected
        ? colors.brandBackgroundSelected
        : _pressed
        ? colors.subtleBackgroundPressed
        : _hovered
        ? colors.subtleBackgroundHover
        : Colors.transparent;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.destination.title,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        onShowHoverHighlight: (hovered) => setState(() {
          _hovered = hovered;
          if (!hovered) _pressed = false;
        }),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: motion.durationFaster,
            curve: motion.curveEasyEase,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: radii.largeBorder,
              border: _focused
                  ? Border.all(color: colors.brandStroke1, width: stroke.thick)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.selected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  color: foreground,
                  size: 20,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.destination.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.caption1.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FluentSideNavigationItem extends StatefulWidget {
  const _FluentSideNavigationItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final _AppDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  State<_FluentSideNavigationItem> createState() =>
      _FluentSideNavigationItemState();
}

class _FluentSideNavigationItemState extends State<_FluentSideNavigationItem> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final radii = context.fluentRadii;
    final motion = context.fluentMotion;
    final stroke = context.fluentStroke;
    final foreground = widget.selected
        ? colors.neutralForegroundOnBrand
        : colors.neutralForeground2;
    final background = widget.selected
        ? colors.brandBackgroundSelected
        : _pressed
        ? colors.subtleBackgroundPressed
        : _hovered
        ? colors.subtleBackgroundHover
        : Colors.transparent;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.destination.title,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        onShowHoverHighlight: (hovered) => setState(() {
          _hovered = hovered;
          if (!hovered) _pressed = false;
        }),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: motion.durationFaster,
            curve: motion.curveEasyEase,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: radii.largeBorder,
              border: _focused
                  ? Border.all(color: colors.brandStroke1, width: stroke.thick)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  widget.selected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  color: foreground,
                  size: 20,
                ),
                if (widget.extended) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.destination.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.body1.copyWith(color: foreground),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
