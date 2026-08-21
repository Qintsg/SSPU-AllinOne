/*
 * 资讯页面状态面板 — 初始、加载、未认证与错误恢复
 * @Project : SSPU-AllinOne
 * @File : info_page_state_panel.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'info_page.dart';

class _InfoStatePanel extends StatelessWidget {
  const _InfoStatePanel({
    required this.state,
    required this.onReadOrRetry,
    required this.onOpenSettings,
  });

  final InfoPageDisplayState state;
  final VoidCallback onReadOrRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final horizontal =
        MediaQuery.sizeOf(context).width >= theme.breakpoint.medium;
    final (icon, title, message, actionLabel, action) = switch (state) {
      InfoPageDisplayState.initial => (
        YhIcons.info,
        '尚未读取校园资讯',
        '先从本机缓存读取；只有手动刷新时才访问已启用的校园来源。',
        '读取校园资讯',
        onReadOrRetry,
      ),
      InfoPageDisplayState.loading => (
        YhIcons.refresh,
        '正在读取校园资讯',
        '正在载入固定的脱敏资讯数据。',
        null,
        null,
      ),
      InfoPageDisplayState.empty => (
        YhIcons.info,
        '尚未认证可用的资讯来源',
        '请先在设置中完成来源认证；当前没有可展示的本地缓存。',
        '来源与认证设置',
        onOpenSettings,
      ),
      InfoPageDisplayState.error => (
        YhIcons.info,
        '无法刷新校园资讯',
        '请检查网络与来源认证后重试；已有本地缓存不会被删除。',
        '重试',
        onReadOrRetry,
      ),
      _ => throw StateError('内容状态不应使用状态面板'),
    };
    return YhCard(
      key: ValueKey('info-state-${state.name}'),
      child: Center(
        child: state == InfoPageDisplayState.loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YhRing.activity(
                    label: '正在读取校园资讯',
                    size: theme.control.compact,
                  ),
                  SizedBox(width: theme.spacing.m),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.typography.h3),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          message,
                          style: theme.typography.small.copyWith(
                            color: theme.color.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _InfoEmptyState(
                icon: icon,
                title: title,
                message: message,
                horizontal: horizontal,
                action: actionLabel == null
                    ? null
                    : YhButton(
                        label: actionLabel,
                        variant: state == InfoPageDisplayState.empty
                            ? YhButtonVariant.secondary
                            : YhButtonVariant.primary,
                        onTap: action,
                      ),
              ),
      ),
    );
  }
}

class _InfoEmptyState extends StatelessWidget {
  const _InfoEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.horizontal = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool horizontal;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final iconWidget = DecoratedBox(
      key: const Key('info-state-icon'),
      decoration: BoxDecoration(
        color: theme.color.brandTint,
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: SizedBox.square(
        dimension: theme.control.regular,
        child: Icon(
          icon,
          size: theme.spacing.l,
          color: theme.color.brandStrong,
        ),
      ),
    );
    final titleWidget = Semantics(
      header: true,
      child: Text(
        title,
        textAlign: horizontal ? TextAlign.start : TextAlign.center,
        style: theme.typography.h3.copyWith(
          color: theme.color.foreground,
          fontWeight: theme.typography.semibold,
        ),
      ),
    );
    final messageWidget = Text(
      message,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: theme.typography.small.copyWith(
        color: theme.color.muted,
        height: theme.typography.body.height,
      ),
    );
    if (horizontal) {
      return Row(
        children: [
          iconWidget,
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                SizedBox(height: theme.spacing.xs),
                messageWidget,
              ],
            ),
          ),
          if (action != null) ...[SizedBox(width: theme.spacing.m), action!],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        SizedBox(height: theme.spacing.s),
        titleWidget,
        SizedBox(height: theme.spacing.xs),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: theme.layout.statusProgressWidth,
          ),
          child: messageWidget,
        ),
        if (action != null) ...[
          SizedBox(height: theme.spacing.s + theme.spacing.xs),
          action!,
        ],
      ],
    );
  }
}

KeyEventResult _handleInfoPaginationKey(_InfoPageState state, KeyEvent event) {
  if (event is! KeyDownEvent || state._filteredMessages.isEmpty) {
    return KeyEventResult.ignored;
  }
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
      state._currentPage > 0) {
    state._setCurrentPage(state._currentPage - 1);
    return KeyEventResult.handled;
  }
  if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
      state._currentPage < state._totalPages - 1) {
    state._setCurrentPage(state._currentPage + 1);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
