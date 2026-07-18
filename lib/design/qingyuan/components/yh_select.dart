/* 清源下拉选择 — 自绘触发器与 Overlay 菜单。 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';

class YhSelectOption<T> {
  const YhSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

class YhSelect<T> extends StatefulWidget {
  const YhSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = '请选择',
    this.enabled = true,
    this.showLabel = true,
  });

  final String label;
  final List<YhSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final bool enabled;
  final bool showLabel;

  @override
  State<YhSelect<T>> createState() => _YhSelectState<T>();
}

class _YhSelectState<T> extends State<YhSelect<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _menuFocusNode = FocusNode(debugLabel: 'YhSelect menu');
  OverlayEntry? _entry;
  int _highlighted = 0;
  double _triggerWidth = 0;

  bool get _open => _entry != null;
  bool get _enabled => widget.enabled && widget.onChanged != null;

  YhSelectOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  void _toggle() {
    if (!_enabled) return;
    _open ? _close() : _show();
  }

  void _show() {
    final renderBox = context.findRenderObject() as RenderBox?;
    _triggerWidth = renderBox?.size.width ?? 0;
    final selectedIndex = widget.options.indexWhere(
      (option) => option.value == widget.value,
    );
    _highlighted = selectedIndex < 0 ? 0 : selectedIndex;
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_open) _menuFocusNode.requestFocus();
    });
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _select(YhSelectOption<T> option) {
    widget.onChanged?.call(option.value);
    _close();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.options.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _highlighted = (_highlighted + 1) % widget.options.length;
      _entry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _highlighted =
          (_highlighted - 1 + widget.options.length) % widget.options.length;
      _entry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _select(widget.options[_highlighted]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final theme = overlayContext.yhTheme;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, theme.spacing.xs),
          child: Focus(
            focusNode: _menuFocusNode,
            onKeyEvent: _handleKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: _triggerWidth,
                maxWidth: _triggerWidth,
                maxHeight: theme.control.regular * 6,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.color.surface,
                  border: Border.all(color: theme.color.border),
                  borderRadius: BorderRadius.circular(theme.radius.input),
                  boxShadow: theme.elevation.e2,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (
                        var index = 0;
                        index < widget.options.length;
                        index += 1
                      )
                        _SelectMenuItem<T>(
                          option: widget.options[index],
                          selected: widget.options[index].value == widget.value,
                          highlighted: index == _highlighted,
                          onTap: () => _select(widget.options[index]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _menuFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final selected = _selected;
    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLabel) ...[
            Text(
              widget.label,
              style: theme.typography.small.copyWith(
                color: theme.color.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
          ],
          CompositedTransformTarget(
            link: _layerLink,
            child: YhPressable(
              semanticLabel:
                  '${widget.label}：${selected?.label ?? widget.hint}',
              onPressed: _enabled ? _toggle : null,
              builder: (context, state, child) => DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.color.surface,
                  border: Border.all(
                    color: _open || state.focused
                        ? theme.color.brandStrong
                        : state.hovered
                        ? theme.color.brand
                        : theme.color.border,
                    width: _open || state.focused ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(theme.radius.input),
                ),
                child: child,
              ),
              child: SizedBox(
                height: theme.control.regular,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected?.label ?? widget.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.copyWith(
                            color: selected == null
                                ? theme.color.muted
                                : theme.color.foreground,
                          ),
                        ),
                      ),
                      SizedBox(width: theme.spacing.s),
                      AnimatedRotation(
                        duration: theme.motion.base,
                        curve: theme.motion.curve,
                        turns: _open ? 0.25 : 0,
                        child: Icon(
                          YhIcons.chevronRight,
                          size: theme.spacing.l,
                          color: _open
                              ? theme.color.brandStrong
                              : theme.color.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectMenuItem<T> extends StatelessWidget {
  const _SelectMenuItem({
    required this.option,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  final YhSelectOption<T> option;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: option.label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onPressed: onTap,
      builder: (context, state, child) => ColoredBox(
        color: highlighted || state.hovered
            ? theme.color.sunken
            : theme.color.surface,
        child: child,
      ),
      child: SizedBox(
        height: theme.control.regular,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: theme.typography.body.copyWith(
                    color: selected
                        ? theme.color.brandInk
                        : theme.color.foreground,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  YhIcons.check,
                  size: theme.spacing.l,
                  color: theme.color.brandStrong,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
