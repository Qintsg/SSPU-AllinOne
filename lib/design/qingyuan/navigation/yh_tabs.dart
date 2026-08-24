/* 清源页签导航。 */

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

@immutable
class YhTab<T> {
  const YhTab({
    required this.value,
    required this.label,
    this.semanticLabel,
    this.icon,
  });

  final T value;
  final String label;
  final String? semanticLabel;
  final IconData? icon;
}

class YhTabs<T> extends StatefulWidget {
  const YhTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.distributeEvenly = false,
  });

  final List<YhTab<T>> tabs;
  final T value;
  final ValueChanged<T>? onChanged;

  /// 固定数量页签可选择等宽完整呈现，避免紧凑端露出半个标签。
  final bool distributeEvenly;

  @override
  State<YhTabs<T>> createState() => _YhTabsState<T>();
}

class _YhTabsState<T> extends State<YhTabs<T>> {
  late List<GlobalKey> _tabKeys;
  final GlobalKey _viewportKey = GlobalKey(debugLabel: 'YhTabsViewport');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabKeys = List<GlobalKey>.generate(
      widget.tabs.length,
      (index) => GlobalKey(debugLabel: 'YhTab-$index'),
    );
    _scheduleSelectedTabReveal();
  }

  @override
  void didUpdateWidget(covariant YhTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabKeys = List<GlobalKey>.generate(
        widget.tabs.length,
        (index) => GlobalKey(debugLabel: 'YhTab-$index'),
      );
    }
    if (oldWidget.value != widget.value || oldWidget.tabs != widget.tabs) {
      _scheduleSelectedTabReveal();
    }
  }

  void _scheduleSelectedTabReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.tabs.indexWhere((tab) => tab.value == widget.value);
      if (index < 0 || index >= _tabKeys.length) return;
      final targetContext = _tabKeys[index].currentContext;
      final viewportContext = _viewportKey.currentContext;
      if (targetContext == null || viewportContext == null) return;
      final targetBox = targetContext.findRenderObject() as RenderBox?;
      final viewportBox = viewportContext.findRenderObject() as RenderBox?;
      if (targetBox == null ||
          viewportBox == null ||
          !_scrollController.hasClients) {
        return;
      }
      final targetLeft = targetBox.localToGlobal(Offset.zero).dx;
      final targetRight = targetLeft + targetBox.size.width;
      final viewportLeft = viewportBox.localToGlobal(Offset.zero).dx;
      final viewportRight = viewportLeft + viewportBox.size.width;
      var offset = _scrollController.offset;
      if (targetLeft < viewportLeft) {
        offset -= viewportLeft - targetLeft;
      } else if (targetRight > viewportRight) {
        offset += targetRight - viewportRight;
      } else {
        return;
      }
      _scrollController.jumpTo(
        offset.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final tabBar = widget.distributeEvenly
        ? _buildDistributedTabBar(theme)
        : _buildScrollableTabBar();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Focus(
        onKeyEvent: _handleDirectionalKey,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.color.border)),
          ),
          child: tabBar,
        ),
      ),
    );
  }

  /// 构建常规可横向滚动的页签栏。
  Widget _buildScrollableTabBar() {
    return SingleChildScrollView(
      key: _viewportKey,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      primary: false,
      child: Row(children: _buildTabs()),
    );
  }

  /// 构建七天等固定项等场景使用的完整日期带。
  Widget _buildDistributedTabBar(YhTheme theme) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: theme.control.regular,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumRailWidth =
              theme.control.minimumTarget * widget.tabs.length;
          final railWidth = constraints.maxWidth < minimumRailWidth
              ? minimumRailWidth
              : constraints.maxWidth;
          return OverflowBox(
            alignment: Alignment.center,
            minWidth: railWidth,
            maxWidth: railWidth,
            minHeight: theme.control.regular,
            maxHeight: theme.control.regular,
            child: Row(
              children: [for (final tab in _buildTabs()) Expanded(child: tab)],
            ),
          );
        },
      ),
    );
  }

  /// 构建单个页签，确保滚动和等宽两种布局共享交互语义。
  List<Widget> _buildTabs() {
    final theme = context.yhTheme;
    final padding = widget.distributeEvenly
        ? EdgeInsets.symmetric(
            horizontal: theme.spacing.xs,
            vertical: theme.spacing.s,
          )
        : EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          );
    final textStyle = widget.distributeEvenly
        ? theme.typography.small
        : theme.typography.body;
    return [
      for (var index = 0; index < widget.tabs.length; index++)
        KeyedSubtree(
          key: _tabKeys[index],
          child: YhPressable(
            semanticLabel:
                widget.tabs[index].semanticLabel ?? widget.tabs[index].label,
            selected: widget.tabs[index].value == widget.value,
            inMutuallyExclusiveGroup: true,
            onPressed: widget.onChanged == null
                ? null
                : () => widget.onChanged!(widget.tabs[index].value),
            builder: (context, state, child) {
              final selected = widget.tabs[index].value == widget.value;
              final foreground = selected
                  ? theme.color.brandStrong
                  : state.hovered
                  ? theme.color.foreground
                  : theme.color.muted;
              return SizedBox(
                height: theme.control.regular,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? theme.color.brandStrong
                            : theme.color.surface.withValues(alpha: 0),
                        width: theme.focus.ringWidth,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.tabs[index].icon != null) ...[
                          Icon(
                            widget.tabs[index].icon,
                            size: theme.spacing.l,
                            color: foreground,
                          ),
                          SizedBox(width: theme.spacing.s),
                        ],
                        Text(
                          widget.tabs[index].label,
                          style: textStyle.copyWith(
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
              );
            },
            child: const SizedBox.shrink(),
          ),
        ),
    ];
  }

  KeyEventResult _handleDirectionalKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    if (delta == 0 || widget.tabs.isEmpty) return KeyEventResult.ignored;
    final current = widget.tabs.indexWhere((tab) => tab.value == widget.value);
    if (current < 0) return KeyEventResult.ignored;
    final next = (current + delta).clamp(0, widget.tabs.length - 1);
    if (next == current) return KeyEventResult.handled;
    widget.onChanged!(widget.tabs[next].value);
    return KeyEventResult.handled;
  }
}
