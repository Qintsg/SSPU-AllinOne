/*
 * Fluent 选择器兼容层 — 安全区感知的 Fluent 下拉选择器
 * @Project : SSPU-AllinOne
 * @File : fluent_select.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' as fluent hide FluentIcons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../fluent/fluent_context_ext.dart';

const double _kSelectButtonMinHeight = 32;
const double _kSelectOuterMinHeight = 48;
const double _kSelectItemHeight = 40;
const double _kSelectPopupPadding = 4;
const double _kSelectViewportMargin = 6;

/// Fluent 选择器选项。
class FluentSelectItem<T> {
  const FluentSelectItem({required this.value, required this.child});

  /// 选项值。
  final T value;

  /// 选项内容。
  final Widget child;
}

/// Fluent 选择器。
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
  final FocusNode _focusNode = FocusNode(debugLabel: 'FluentSelect');

  int? get _selectedIndex {
    for (var index = 0; index < widget.items.length; index++) {
      if (widget.items[index].value == widget.value) return index;
    }
    return null;
  }

  bool get _isEnabled => widget.items.isNotEmpty && widget.onChanged != null;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey != LogicalKeyboardKey.arrowDown &&
        event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }

    if (!_isEnabled) return KeyEventResult.ignored;
    _openPopup();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openPopup() async {
    if (!_isEnabled) return;

    final navigator = Navigator.of(context);
    final renderBox = context.findRenderObject()! as RenderBox;
    final navigatorBox = navigator.context.findRenderObject()! as RenderBox;
    final buttonRect =
        renderBox.localToGlobal(Offset.zero, ancestor: navigatorBox) &
        renderBox.size;
    final selected = _selectedIndex ?? 0;
    final result = await navigator.push<_FluentSelectRouteResult<T>>(
      _FluentSelectPopupRoute<T>(
        items: widget.items,
        buttonRect: buttonRect,
        selectedIndex: selected.clamp(0, widget.items.length - 1),
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        barrierLabel: fluent.FluentLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );

    if (!mounted || result == null) return;
    widget.onChanged?.call(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final selectedIndex = _selectedIndex;
    final selectedChild = selectedIndex == null
        ? widget.placeholder
        : widget.items[selectedIndex].child;

    return Focus(
      canRequestFocus: false,
      onKeyEvent: _handleKeyEvent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _kSelectOuterMinHeight),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widget.isExpanded ? null : 1,
          child: fluent.Button(
            onPressed: _isEnabled ? _openPopup : null,
            focusNode: _focusNode,
            style: const fluent.ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: _kSelectButtonMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 11, end: 15),
                child: Row(
                  mainAxisSize: widget.isExpanded
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.isExpanded)
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: _contentStyle(context, selectedIndex != null),
                          overflow: TextOverflow.ellipsis,
                          child: selectedChild ?? const SizedBox.shrink(),
                        ),
                      )
                    else
                      DefaultTextStyle.merge(
                        style: _contentStyle(context, selectedIndex != null),
                        overflow: TextOverflow.ellipsis,
                        child: selectedChild ?? const SizedBox.shrink(),
                      ),
                    const SizedBox(width: 8),
                    IconTheme.merge(
                      data: IconThemeData(
                        color: _isEnabled
                            ? theme.resources.textFillColorSecondary
                            : theme.resources.textFillColorDisabled,
                        size: 8,
                      ),
                      child: const fluent.WindowsIcon(
                        fluent.WindowsIcons.chevron_down,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _contentStyle(BuildContext context, bool hasSelectedValue) {
    final theme = fluent.FluentTheme.of(context);
    final base = theme.typography.body ?? const TextStyle();
    if (!_isEnabled || !hasSelectedValue) {
      return base.copyWith(color: theme.resources.textFillColorDisabled);
    }
    return base.copyWith(color: theme.resources.textFillColorPrimary);
  }
}

@immutable
class _FluentSelectRouteResult<T> {
  const _FluentSelectRouteResult(this.value);

  final T? value;
}

class _FluentSelectPopupRoute<T>
    extends PopupRoute<_FluentSelectRouteResult<T>> {
  _FluentSelectPopupRoute({
    required this.items,
    required this.buttonRect,
    required this.selectedIndex,
    required this.capturedThemes,
    required this.barrierLabel,
  });

  final List<FluentSelectItem<T>> items;
  final Rect buttonRect;
  final int selectedIndex;
  final CapturedThemes capturedThemes;

  @override
  final String? barrierLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _FluentSelectPopupPage<T>(
      route: this,
      animation: animation,
      child: capturedThemes.wrap(
        _FluentSelectPopupMenu<T>(items: items, selectedIndex: selectedIndex),
      ),
    );
  }
}

class _FluentSelectPopupPage<T> extends StatelessWidget {
  const _FluentSelectPopupPage({
    required this.route,
    required this.animation,
    required this.child,
  });

  final _FluentSelectPopupRoute<T> route;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final motion = context.fluentMotion;
    final curved = CurvedAnimation(
      parent: animation,
      curve: motion.curveDecelerateMid,
      reverseCurve: motion.curveAccelerateMid,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final delegate = _FluentSelectPopupLayout(
          buttonRect: route.buttonRect,
          itemCount: route.items.length,
          selectedIndex: route.selectedIndex,
          viewPadding: media.viewPadding,
          textDirection: Directionality.of(context),
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Navigator.of(context).maybePop(),
          child: CustomSingleChildLayout(
            delegate: delegate,
            child: FadeTransition(
              opacity: curved,
              child: _FluentSelectInitialScroll(
                buttonRect: route.buttonRect,
                delegate: delegate,
                viewportSize: constraints.biggest,
                selectedIndex: route.selectedIndex,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FluentSelectInitialScroll extends StatefulWidget {
  const _FluentSelectInitialScroll({
    required this.buttonRect,
    required this.delegate,
    required this.viewportSize,
    required this.selectedIndex,
    required this.child,
  });

  final Rect buttonRect;
  final _FluentSelectPopupLayout delegate;
  final Size viewportSize;
  final int selectedIndex;
  final Widget child;

  @override
  State<_FluentSelectInitialScroll> createState() =>
      _FluentSelectInitialScrollState();
}

class _FluentSelectInitialScrollState
    extends State<_FluentSelectInitialScroll> {
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _initialScrollOffset(),
    keepScrollOffset: false,
  );

  double _initialScrollOffset() {
    final menuTop = widget.delegate.menuTop(widget.viewportSize);
    final menuHeight = widget.delegate.menuHeight(widget.viewportSize);
    final preferredHeight = widget.delegate.preferredHeight;
    if (preferredHeight <= menuHeight) return 0;

    final selectedCenter =
        _kSelectPopupPadding +
        widget.selectedIndex * _kSelectItemHeight +
        _kSelectItemHeight / 2;
    final targetCenter = widget.buttonRect.center.dy - menuTop;
    return (selectedCenter - targetCenter).clamp(
      0.0,
      preferredHeight - menuHeight,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _scrollController,
      child: widget.child,
    );
  }
}

class _FluentSelectPopupLayout extends SingleChildLayoutDelegate {
  const _FluentSelectPopupLayout({
    required this.buttonRect,
    required this.itemCount,
    required this.selectedIndex,
    required this.viewPadding,
    required this.textDirection,
  });

  final Rect buttonRect;
  final int itemCount;
  final int selectedIndex;
  final EdgeInsets viewPadding;
  final TextDirection textDirection;

  double get preferredHeight =>
      _kSelectPopupPadding * 2 + itemCount * _kSelectItemHeight;

  Rect _safeRect(Size size) {
    final left = viewPadding.left + _kSelectViewportMargin;
    final top = viewPadding.top + _kSelectViewportMargin;
    final right = math.max(
      left,
      size.width - viewPadding.right - _kSelectViewportMargin,
    );
    final bottom = math.max(
      top,
      size.height - viewPadding.bottom - _kSelectViewportMargin,
    );
    return Rect.fromLTRB(left, top, right, bottom);
  }

  double menuHeight(Size size) {
    final safe = _safeRect(size);
    return math.min(preferredHeight, safe.height);
  }

  double menuTop(Size size) {
    final safe = _safeRect(size);
    final height = menuHeight(size);
    final selectedOffset =
        _kSelectPopupPadding +
        selectedIndex * _kSelectItemHeight +
        _kSelectItemHeight / 2;
    final preferredTop = buttonRect.center.dy - selectedOffset;
    return preferredTop.clamp(safe.top, safe.bottom - height);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final safe = _safeRect(size);
    final width = math.min(buttonRect.width, safe.width);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: menuHeight(size),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final safe = _safeRect(size);
    final left = switch (textDirection) {
      TextDirection.rtl => (buttonRect.right - childSize.width).clamp(
        safe.left,
        safe.right - childSize.width,
      ),
      TextDirection.ltr => buttonRect.left.clamp(
        safe.left,
        safe.right - childSize.width,
      ),
    };
    return Offset(left, menuTop(size));
  }

  @override
  bool shouldRelayout(_FluentSelectPopupLayout oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        itemCount != oldDelegate.itemCount ||
        selectedIndex != oldDelegate.selectedIndex ||
        viewPadding != oldDelegate.viewPadding ||
        textDirection != oldDelegate.textDirection;
  }
}

class _FluentSelectPopupMenu<T> extends StatefulWidget {
  const _FluentSelectPopupMenu({
    required this.items,
    required this.selectedIndex,
  });

  final List<FluentSelectItem<T>> items;
  final int selectedIndex;

  @override
  State<_FluentSelectPopupMenu<T>> createState() =>
      _FluentSelectPopupMenuState<T>();
}

class _FluentSelectPopupMenuState<T> extends State<_FluentSelectPopupMenu<T>> {
  late int _activeIndex = widget.selectedIndex;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _select(_activeIndex);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveActiveIndex(1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveActiveIndex(-1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveActiveIndex(int delta) {
    final next = (_activeIndex + delta).clamp(0, widget.items.length - 1);
    if (next == _activeIndex) return;
    setState(() => _activeIndex = next);
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    final top = next * _kSelectItemHeight;
    final bottom = top + _kSelectItemHeight;
    final position = controller.position;
    if (top < position.pixels) {
      controller.animateTo(
        top,
        duration: context.fluentMotion.durationFaster,
        curve: context.fluentMotion.curveEasyEase,
      );
    } else if (bottom > position.pixels + position.viewportDimension) {
      controller.animateTo(
        bottom - position.viewportDimension,
        duration: context.fluentMotion.durationFaster,
        curve: context.fluentMotion.curveEasyEase,
      );
    }
  }

  void _select(int index) {
    Navigator.of(
      context,
    ).pop(_FluentSelectRouteResult<T>(widget.items[index].value));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final theme = fluent.FluentTheme.of(context);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.neutralBackground1,
            border: Border.all(color: colors.neutralStroke2),
            borderRadius: radii.mediumBorder,
            boxShadow: context.fluentElevation.shadow16,
          ),
          child: ClipRRect(
            borderRadius: radii.mediumBorder,
            child: ListView.builder(
              primary: true,
              padding: const EdgeInsets.symmetric(
                vertical: _kSelectPopupPadding,
              ),
              itemExtent: _kSelectItemHeight,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final selected = index == widget.selectedIndex;
                final active = index == _activeIndex;
                return fluent.HoverButton(
                  onPressed: () => _select(index),
                  builder: (context, states) {
                    final hovered = states.contains(WidgetState.hovered);
                    final pressed = states.contains(WidgetState.pressed);
                    final background = pressed
                        ? colors.neutralBackground1Pressed
                        : hovered || active
                        ? colors.neutralBackground1Hover
                        : fluent.Colors.transparent;
                    return Container(
                      key: ValueKey('fluent-select-popup-option-$index'),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsetsDirectional.only(
                        start: 8,
                        end: 12,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: radii.mediumBorder,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 3,
                            height: 18,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: selected || active
                                    ? theme.accentColor.defaultBrushFor(
                                        theme.brightness,
                                      )
                                    : fluent.Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  radii.circular,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DefaultTextStyle.merge(
                              style:
                                  theme.typography.body?.copyWith(
                                    color: colors.neutralForeground1,
                                  ) ??
                                  TextStyle(color: colors.neutralForeground1),
                              overflow: TextOverflow.ellipsis,
                              child: widget.items[index].child,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
