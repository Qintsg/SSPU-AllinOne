/*
 * Fluent 2 选择器 — 使用自绘浮层菜单，避免 Material 下拉外观
 * @Project : SSPU-AllinOne
 * @File : fluent_select.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 选择器选项。
class FluentSelectItem<T> {
  const FluentSelectItem({required this.value, required this.child});

  /// 选项值。
  final T value;

  /// 选项内容。
  final Widget child;
}

class _FluentSelectMoveIntent extends Intent {
  const _FluentSelectMoveIntent(this.direction);

  final int direction;
}

class _FluentSelectDismissIntent extends Intent {
  const _FluentSelectDismissIntent();
}

/// Fluent 2 选择器。
class FluentSelect<T> extends StatefulWidget {
  const FluentSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.placeholder,
    this.isExpanded = false,
  });

  /// 当前值。
  final T? value;

  /// 可选项。
  final List<FluentSelectItem<T>> items;

  /// 选中项变化回调；为空时禁用。
  final ValueChanged<T?>? onChanged;

  /// 未选择时的占位内容。
  final Widget? placeholder;

  /// 是否占满可用宽度。
  final bool isExpanded;

  @override
  State<FluentSelect<T>> createState() => _FluentSelectState<T>();
}

class _FluentSelectState<T> extends State<FluentSelect<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _targetKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _hovered = false;
  bool _focused = false;
  int? _highlightedIndex;
  Size _targetSize = Size.zero;

  bool get _enabled => widget.onChanged != null;
  bool get _open => _overlayEntry != null;

  @override
  void dispose() {
    _removeOverlay(notify: false);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FluentSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _removeOverlay();
      return;
    }
    if (_open) {
      _syncHighlightedIndex();
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final type = context.fluentType;
    final motion = context.fluentMotion;
    final selectedItem = _selectedItem;
    final foreground = _enabled
        ? colors.neutralForeground1
        : colors.neutralForegroundDisabled;

    final visual = AnimatedContainer(
      key: _targetKey,
      duration: motion.durationFaster,
      curve: motion.curveEasyEase,
      constraints: const BoxConstraints(minHeight: 32, minWidth: 96),
      padding: EdgeInsetsDirectional.only(
        start: spacing.m,
        end: spacing.s,
        top: spacing.s,
        bottom: spacing.s,
      ),
      decoration: BoxDecoration(
        color: _enabled
            ? (_hovered || _open
                  ? colors.neutralBackground1Hover
                  : colors.neutralBackground1)
            : colors.neutralBackground3,
        borderRadius: radii.mediumBorder,
        border: Border.all(
          color: _focused || _open
              ? colors.brandStroke1
              : colors.neutralStroke1,
          width: _focused || _open ? stroke.thick : stroke.thin,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: type.body1.copyWith(color: foreground),
        child: Row(
          mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              fit: widget.isExpanded ? FlexFit.tight : FlexFit.loose,
              child:
                  selectedItem?.child ??
                  DefaultTextStyle.merge(
                    style: type.body1.copyWith(
                      color: colors.neutralForeground3,
                    ),
                    child: widget.placeholder ?? const SizedBox.shrink(),
                  ),
            ),
            SizedBox(width: spacing.s),
            Icon(
              _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: _enabled
                  ? colors.neutralForeground2
                  : colors.neutralForegroundDisabled,
            ),
          ],
        ),
      ),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        button: true,
        enabled: _enabled,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown):
                _FluentSelectMoveIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp):
                _FluentSelectMoveIntent(-1),
            SingleActivator(LogicalKeyboardKey.escape):
                _FluentSelectDismissIntent(),
          },
          child: FocusableActionDetector(
            enabled: _enabled,
            mouseCursor: _enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onShowFocusHighlight: (focused) =>
                setState(() => _focused = focused),
            onShowHoverHighlight: (hovered) =>
                setState(() => _hovered = hovered),
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _activateSelection();
                  return null;
                },
              ),
              _FluentSelectMoveIntent: CallbackAction<_FluentSelectMoveIntent>(
                onInvoke: (intent) {
                  _moveHighlight(intent.direction);
                  return null;
                },
              ),
              _FluentSelectDismissIntent:
                  CallbackAction<_FluentSelectDismissIntent>(
                    onInvoke: (_) {
                      _removeOverlay();
                      return null;
                    },
                  ),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _enabled ? _toggleOverlay : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: widget.isExpanded ? null : 1,
                  child: visual,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  FluentSelectItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  void _toggleOverlay() {
    if (_open) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay({bool highlightLast = false}) {
    if (_open) return;
    final renderBox =
        _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    _targetSize = renderBox.size;
    _syncHighlightedIndex(preferLast: highlightLast);
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final elevation = context.fluentElevation;
    final width = math.max(_targetSize.width, 180.0);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, spacing.xs),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: width,
                maxWidth: math.max(width, 280),
                maxHeight: 280,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.neutralBackground1,
                  borderRadius: radii.xLargeBorder,
                  border: Border.all(
                    color: colors.neutralStroke1,
                    width: stroke.thin,
                  ),
                  boxShadow: elevation.shadow16,
                ),
                child: ClipRRect(
                  borderRadius: radii.xLargeBorder,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: spacing.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < widget.items.length;
                          index++
                        )
                          _FluentSelectMenuItem<T>(
                            item: widget.items[index],
                            selected: widget.items[index].value == widget.value,
                            highlighted: index == _highlightedIndex,
                            onHighlighted: () => _setHighlightedIndex(index),
                            onSelected: _selectItem,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectItem(T value) {
    _removeOverlay();
    widget.onChanged?.call(value);
  }

  void _activateSelection() {
    if (!_enabled) return;
    if (!_open) {
      _showOverlay();
      return;
    }

    final index = _highlightedIndex;
    if (index == null || index < 0 || index >= widget.items.length) {
      _removeOverlay();
      return;
    }
    _selectItem(widget.items[index].value);
  }

  void _moveHighlight(int direction) {
    if (!_enabled || widget.items.isEmpty) return;
    if (!_open) {
      _showOverlay(highlightLast: direction < 0);
      return;
    }

    final current =
        _highlightedIndex ?? (direction < 0 ? widget.items.length : -1);
    final next = math.max(
      0,
      math.min(widget.items.length - 1, current + direction),
    );
    _setHighlightedIndex(next);
  }

  void _syncHighlightedIndex({bool preferLast = false}) {
    if (widget.items.isEmpty) {
      _highlightedIndex = null;
      return;
    }

    final selectedIndex = widget.items.indexWhere(
      (item) => item.value == widget.value,
    );
    final fallbackIndex = preferLast ? widget.items.length - 1 : 0;
    final candidate = selectedIndex >= 0
        ? selectedIndex
        : (_highlightedIndex ?? fallbackIndex);
    _highlightedIndex = math.max(
      0,
      math.min(widget.items.length - 1, candidate),
    );
  }

  void _setHighlightedIndex(int index) {
    if (_highlightedIndex == index) return;
    setState(() => _highlightedIndex = index);
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay({bool notify = true}) {
    final overlay = _overlayEntry;
    if (overlay == null) return;
    overlay.remove();
    _overlayEntry = null;
    if (notify && mounted) setState(() {});
  }
}

class _FluentSelectMenuItem<T> extends StatefulWidget {
  const _FluentSelectMenuItem({
    required this.item,
    required this.selected,
    required this.highlighted,
    required this.onHighlighted,
    required this.onSelected,
  });

  final FluentSelectItem<T> item;
  final bool selected;
  final bool highlighted;
  final VoidCallback onHighlighted;
  final ValueChanged<T> onSelected;

  @override
  State<_FluentSelectMenuItem<T>> createState() =>
      _FluentSelectMenuItemState<T>();
}

class _FluentSelectMenuItemState<T> extends State<_FluentSelectMenuItem<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          widget.onHighlighted();
        },
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelected(widget.item.value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.s,
            ),
            color: widget.selected
                ? colors.brandBackgroundSelected.withValues(alpha: 0.14)
                : (_hovered || widget.highlighted)
                ? colors.neutralBackground1Hover
                : Colors.transparent,
            child: DefaultTextStyle.merge(
              style: type.body1.copyWith(color: colors.neutralForeground1),
              child: Row(
                children: [
                  Expanded(child: widget.item.child),
                  if (widget.selected) ...[
                    SizedBox(width: spacing.s),
                    Icon(Icons.check, size: 16, color: colors.brandForeground1),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
