/* 清源信息中心展示层。 */

part of 'info_page.dart';

Widget _buildInfoPageView(_InfoPageState state, BuildContext context) {
  final theme = context.yhTheme;
  return YhPageScaffold(
    appBar: null,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoint.medium;
        final displayState = state._displayState;
        final pagePadding = _infoPagePadding(
          theme,
          MediaQuery.sizeOf(context).width,
        );
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleInfoPaginationKey(state, event),
          child: Padding(
            padding: pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      theme.layout.pageContentWidth - pagePadding.horizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoHeader(state: state, compact: compact),
                    SizedBox(height: theme.spacing.l),
                    if (displayState == InfoPageDisplayState.content ||
                        displayState == InfoPageDisplayState.stale)
                      Expanded(
                        child: _InfoContent(
                          state: state,
                          compact: compact,
                          stale: displayState == InfoPageDisplayState.stale,
                        ),
                      )
                    else
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: double.infinity,
                            height:
                                theme.layout.popoverWidth + theme.spacing.xl,
                            child: _InfoStatePanel(
                              state: displayState,
                              onReadOrRetry: state._refreshSchoolWebsite,
                              onOpenSettings:
                                  state.widget.onOpenSourceSettings ?? () {},
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

EdgeInsets _infoPagePadding(YhTheme theme, double viewportWidth) {
  if (viewportWidth < theme.breakpoint.medium) {
    return EdgeInsets.fromLTRB(
      theme.spacing.m,
      theme.spacing.l + theme.spacing.s,
      theme.spacing.m,
      0,
    );
  }
  final progress =
      ((viewportWidth - theme.breakpoint.medium) /
              (theme.breakpoint.expanded - theme.breakpoint.medium))
          .clamp(0.0, 1.0);
  final horizontal =
      theme.spacing.xl + (theme.spacing.xl2 - theme.spacing.xl) * progress;
  return EdgeInsets.symmetric(
    horizontal: horizontal,
    vertical: theme.spacing.xl + theme.spacing.s,
  );
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({required this.state, required this.compact});

  final _InfoPageState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      key: Key(compact ? 'info-mobile-controls' : 'info-regular-controls'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '校园信息',
                style: theme.typography.caption.copyWith(
                  color: theme.color.brandInk,
                  fontWeight: theme.typography.semibold,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Semantics(
                header: true,
                child: Text('校园资讯', style: theme.typography.h1),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                '先说明来源与更新时间，再提供标题和两行摘要；刷新时保留已有内容。',
                style:
                    (compact
                            ? theme.typography.supporting
                            : theme.typography.body)
                        .copyWith(color: theme.color.muted),
              ),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.s),
        YhIconButton(
          key: const Key('info-refresh-button'),
          icon: YhIcons.refresh,
          semanticLabel: '刷新校园资讯',
          onTap: state._refreshService.isRefreshing
              ? null
              : state._refreshSchoolWebsite,
        ),
      ],
    );
  }
}

class _InfoContent extends StatelessWidget {
  const _InfoContent({
    required this.state,
    required this.compact,
    required this.stale,
  });

  final _InfoPageState state;
  final bool compact;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoStatusRow(state: state),
        if (stale) ...[
          SizedBox(height: theme.spacing.m),
          const YhBanner(
            key: Key('info-stale-banner'),
            kind: YhBannerKind.warn,
            text: '当前显示 09:30 的本地资讯缓存；网络恢复后可手动刷新。',
          ),
        ],
        if (state._refreshService.snapshot.isRefreshing) ...[
          SizedBox(height: theme.spacing.m),
          _InfoRefreshProgress(state: state),
        ],
        SizedBox(height: theme.spacing.m),
        _InfoSearchField(state: state),
        SizedBox(height: theme.spacing.m),
        Expanded(
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoCompactSourceStrip(state: state),
                    SizedBox(height: theme.spacing.m),
                    Expanded(child: _InfoMessagePanel(state: state)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: theme.layout.popoverWidth - theme.spacing.l,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _InfoSourcePanel(state: state),
                      ),
                    ),
                    SizedBox(width: theme.spacing.m),
                    Expanded(child: _InfoMessagePanel(state: state)),
                  ],
                ),
        ),
        if (state._totalPages > 1 &&
            state.widget.messageRenderLimitOverride == null) ...[
          SizedBox(height: theme.spacing.s),
          SizedBox(
            key: Key(
              compact ? 'info-mobile-pagination' : 'info-regular-pagination',
            ),
            height: theme.control.minimumTarget,
            child: Align(
              alignment: Alignment.center,
              child: YhPagination(
                page: state._currentPage + 1,
                pageCount: state._totalPages,
                simple: compact,
                onChanged: (page) => state._setCurrentPage(page - 1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoStatusRow extends StatelessWidget {
  const _InfoStatusRow({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final sourceCount = _infoEnabledPrimarySourceCount(state);
    final updated = state._lastLoadedAt ?? state._now;
    final time =
        '${updated.hour.toString().padLeft(2, '0')}:'
        '${updated.minute.toString().padLeft(2, '0')} 更新';
    return Wrap(
      key: const Key('info-status-row'),
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
      children: [
        YhStatusPill(label: '$sourceCount 个来源', kind: YhStatusKind.info),
        YhStatusPill(
          label: '${state._allMessages.length} 条资讯',
          kind: YhStatusKind.info,
        ),
        YhStatusPill(label: time),
      ],
    );
  }
}

class _InfoSearchField extends StatelessWidget {
  const _InfoSearchField({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) => YhSearch(
    key: const Key('info-search-field'),
    controller: state._searchController,
    hint: '搜索标题、摘要或来源',
    onChanged: (value) {
      state._searchQuery = value;
      state._applyFilters();
    },
  );
}

class _InfoCompactSourceStrip extends StatelessWidget {
  const _InfoCompactSourceStrip({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('info-compact-source-strip'),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        ..._infoSourceButtons(context, state),
        SizedBox(width: context.yhTheme.spacing.xs),
        _InfoSourceButton(
          key: const Key('info-mobile-filter-button'),
          label: '更多筛选',
          selected: _hasInfoFilters(state),
          onTap: () => _showInfoFilterDrawer(context, state),
        ),
      ],
    ),
  );
}

class _InfoSourcePanel extends StatelessWidget {
  const _InfoSourcePanel({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('info-source-panel'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('来源', style: theme.typography.h3),
          SizedBox(height: theme.spacing.xs),
          Text(
            '${_infoEnabledPrimarySourceCount(state)} 个来源已启用',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          ..._infoSourceButtons(context, state, vertical: true),
          SizedBox(height: theme.spacing.s),
          YhButton(
            key: const Key('info-regular-filter-button'),
            label: '更多筛选与操作',
            variant: YhButtonVariant.text,
            onTap: () => _showInfoFilterDrawer(context, state),
          ),
        ],
      ),
    );
  }
}

List<Widget> _infoSourceButtons(
  BuildContext context,
  _InfoPageState state, {
  bool vertical = false,
}) {
  final theme = context.yhTheme;
  final options = <(_InfoPrimarySource, String, int)>[
    (_InfoPrimarySource.all, '全部信息', state._allMessages.length),
    (
      _InfoPrimarySource.schoolWebsite,
      '学校官网',
      state._allMessages
          .where(
            (message) =>
                message.sourceType == MessageSourceType.schoolWebsite &&
                message.sourceName != MessageSourceName.jwc,
          )
          .length,
    ),
    (
      _InfoPrimarySource.academicOffice,
      '教务处',
      state._allMessages
          .where((message) => message.sourceName == MessageSourceName.jwc)
          .length,
    ),
    (
      _InfoPrimarySource.wechat,
      '微信公众号',
      state._allMessages
          .where(
            (message) =>
                message.sourceType == MessageSourceType.wechatPublic ||
                message.sourceType == MessageSourceType.wechatService,
          )
          .length,
    ),
  ];
  return [
    for (var index = 0; index < options.length; index++) ...[
      if (index > 0)
        SizedBox(
          width: vertical ? 0 : theme.spacing.xs,
          height: vertical ? theme.spacing.xs : 0,
        ),
      _InfoSourceButton(
        label: '${options[index].$2} · ${options[index].$3}',
        selected: state._primarySource == options[index].$1,
        onTap: () {
          state._primarySource = options[index].$1;
          state._applyFilters();
        },
      ),
    ],
  ];
}

class _InfoSourceButton extends StatelessWidget {
  const _InfoSourceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: label,
      selected: selected,
      onPressed: onTap,
      builder: (context, pressState, child) => AnimatedContainer(
        duration: theme.motion.fast,
        curve: theme.motion.curve,
        constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
        decoration: BoxDecoration(
          color: selected
              ? theme.color.brandTint
              : pressState.hovered
              ? theme.color.sunken
              : null,
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: Text(
          label,
          style: theme.typography.body.copyWith(
            color: selected ? theme.color.brandInk : theme.color.muted,
            fontWeight: selected ? theme.typography.semibold : null,
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

int _infoEnabledPrimarySourceCount(_InfoPageState state) =>
    [
          _InfoPrimarySource.schoolWebsite,
          _InfoPrimarySource.academicOffice,
          _InfoPrimarySource.wechat,
        ]
        .where(
          (source) => state._allMessages.any(
            (message) => _matchesInfoPrimarySource(message, source),
          ),
        )
        .length;

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
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
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
            ),
            SizedBox(height: theme.spacing.s),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.typography.h3.copyWith(
                  color: theme.color.foreground,
                  fontWeight: theme.typography.semibold,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: theme.layout.statusProgressWidth,
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                  height: theme.typography.body.height,
                ),
              ),
            ),
            if (action != null) ...[
              SizedBox(height: theme.spacing.s + theme.spacing.xs),
              action!,
            ],
          ],
        ),
      ),
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

class _InfoFilterFields extends StatelessWidget {
  const _InfoFilterFields({required this.state, this.onUpdated});

  final _InfoPageState state;
  final VoidCallback? onUpdated;

  void _updated() {
    state._applyFilters();
    onUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final sourceNames = state._getAvailableSourceNames();
    final wechatNames = state._getAvailableWechatMpNames();
    final categories = state._getAvailableCategories();
    return Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: theme.spacing.xl2 * 4,
          child: _infoSelect<MessageSourceType>(
            label: '来源类型',
            value: state._filterSourceType,
            items: const [
              MessageSourceType.schoolWebsite,
              MessageSourceType.wechatPublic,
            ],
            itemLabel: (item) => item.label,
            onChanged: (value) {
              state._filterSourceType = value;
              state._filterSourceName = null;
              state._filterWechatMpName = null;
              state._filterCategory = null;
              _updated();
            },
          ),
        ),
        SizedBox(
          width: theme.spacing.xl2 * 5,
          child: state._filterSourceType == MessageSourceType.wechatPublic
              ? _infoSelect<String>(
                  label: '公众号名称',
                  value: state._filterWechatMpName,
                  items: wechatNames,
                  itemLabel: (item) => item,
                  enabled: state._filterSourceType != null,
                  onChanged: (value) {
                    state._filterWechatMpName = value;
                    state._filterCategory = null;
                    _updated();
                  },
                )
              : _infoSelect<MessageSourceName>(
                  label: '来源名称',
                  value: state._filterSourceName,
                  items: sourceNames,
                  itemLabel: (item) => item.label,
                  enabled: state._filterSourceType != null,
                  onChanged: (value) {
                    state._filterSourceName = value;
                    state._filterCategory = null;
                    _updated();
                  },
                ),
        ),
        SizedBox(
          width: theme.spacing.xl2 * 4,
          child: _infoSelect<MessageCategory>(
            label: '内容分类',
            value: state._filterCategory,
            items: categories,
            itemLabel: (item) => item.label,
            enabled:
                state._filterSourceType != MessageSourceType.wechatPublic &&
                state._filterSourceName != null,
            onChanged: (value) {
              state._filterCategory = value;
              _updated();
            },
          ),
        ),
        SizedBox(
          height:
              theme.control.regular +
              theme.typography.small.fontSize! +
              theme.spacing.xs,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              YhSwitch(
                value: state._filterUnreadOnly,
                semanticLabel: '仅显示未读消息',
                onChanged: (value) {
                  state._filterUnreadOnly = value;
                  _updated();
                },
              ),
              SizedBox(width: theme.spacing.xs),
              Text('仅未读', style: theme.typography.small),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _infoSelect<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) itemLabel,
  required ValueChanged<T?> onChanged,
  bool enabled = true,
}) {
  return YhSelect<T?>(
    label: label,
    value: value,
    enabled: enabled,
    options: [
      YhSelectOption<T?>(value: null, label: '全部$label'),
      for (final item in items)
        YhSelectOption<T?>(value: item, label: itemLabel(item)),
    ],
    onChanged: onChanged,
  );
}

class _InfoActiveFilters extends StatelessWidget {
  const _InfoActiveFilters({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final chips = <Widget>[
      if (state._searchQuery.trim().isNotEmpty)
        YhChip(
          label: '搜索：${state._searchQuery.trim()}',
          onDeleted: () {
            state._searchController.clear();
            state._searchQuery = '';
            state._applyFilters();
          },
        ),
      if (state._filterSourceType != null)
        YhChip(
          label: state._filterSourceType!.label,
          onDeleted: () {
            state._filterSourceType = null;
            state._filterSourceName = null;
            state._filterWechatMpName = null;
            state._filterCategory = null;
            state._applyFilters();
          },
        ),
      if (state._filterWechatMpName != null)
        YhChip(
          label: state._filterWechatMpName!,
          onDeleted: () {
            state._filterWechatMpName = null;
            state._applyFilters();
          },
        )
      else if (state._filterSourceName != null)
        YhChip(
          label: state._filterSourceName!.label,
          onDeleted: () {
            state._filterSourceName = null;
            state._filterCategory = null;
            state._applyFilters();
          },
        ),
      if (state._filterCategory != null)
        YhChip(
          label: state._filterCategory!.label,
          onDeleted: () {
            state._filterCategory = null;
            state._applyFilters();
          },
        ),
      if (state._filterUnreadOnly)
        YhChip(
          label: '仅未读',
          selected: true,
          onDeleted: () {
            state._filterUnreadOnly = false;
            state._applyFilters();
          },
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: theme.spacing.s),
      child: Wrap(
        spacing: theme.spacing.s,
        runSpacing: theme.spacing.xs,
        children: chips,
      ),
    );
  }
}

class _InfoRefreshProgress extends StatelessWidget {
  const _InfoRefreshProgress({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = state._refreshService.snapshot;
    final progress = snapshot.total <= 0
        ? null
        : (snapshot.completed / snapshot.total).clamp(0.0, 1.0);
    return YhCard(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Row(
        children: [
          SizedBox(
            width: theme.spacing.xl2 * 3,
            child: YhProgress(value: progress, showPercent: false),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Text(
              snapshot.text.isEmpty ? '正在刷新…' : snapshot.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMessagePanel extends StatelessWidget {
  const _InfoMessagePanel({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (state._filteredMessages.isEmpty) {
      return YhCard(
        key: const Key('info-filter-empty'),
        child: YhEmptyState(
          icon: YhIcons.search,
          title: '当前筛选没有结果',
          message: '更换来源或清除搜索词后，可恢复显示全部校园资讯。',
          action: YhButton(
            label: '清除筛选',
            variant: YhButtonVariant.secondary,
            onTap: () => _clearInfoFilters(state),
          ),
        ),
      );
    }

    final messages = state._pagedMessages;
    return ListView.separated(
      key: const Key('info-message-list'),
      controller: state._messageListController,
      primary: false,
      itemCount: messages.length,
      separatorBuilder: (_, _) => SizedBox(height: theme.spacing.s),
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageTile(
          message: message,
          isRead: state._stateService.isRead(message.id),
          nowOverride: state._now,
          onTap: () => state._openMessage(message),
        );
      },
    );
  }
}

bool _hasInfoFilters(_InfoPageState state) =>
    state._primarySource != _InfoPrimarySource.all ||
    state._filterSourceType != null ||
    state._filterSourceName != null ||
    state._filterWechatMpName != null ||
    state._filterCategory != null ||
    state._filterUnreadOnly;

void _clearInfoFilters(_InfoPageState state) {
  state._primarySource = _InfoPrimarySource.all;
  state._searchController.clear();
  state._searchQuery = '';
  state._filterSourceType = null;
  state._filterSourceName = null;
  state._filterWechatMpName = null;
  state._filterCategory = null;
  state._filterUnreadOnly = false;
  state._applyFilters();
}

Future<void> _showInfoFilterDrawer(BuildContext context, _InfoPageState state) {
  return YhBottomDrawer.show<void>(
    context,
    title: '筛选消息',
    builder: (drawerContext) => StatefulBuilder(
      builder: (context, setDrawerState) {
        final theme = context.yhTheme;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height - theme.spacing.xl2 * 2,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoFilterFields(
                  state: state,
                  onUpdated: () => setDrawerState(() {}),
                ),
                _InfoActiveFilters(state: state),
                SizedBox(height: theme.spacing.m),
                Wrap(
                  spacing: theme.spacing.s,
                  runSpacing: theme.spacing.s,
                  children: [
                    YhButton(
                      label: '全部标为已读',
                      leadingIcon: YhIcons.check,
                      onTap: state._filteredMessages.isEmpty
                          ? null
                          : state._markAllRead,
                    ),
                    YhButton(
                      label: '刷新官网消息',
                      leadingIcon: YhIcons.refresh,
                      variant: YhButtonVariant.secondary,
                      onTap: state._refreshService.isRefreshing
                          ? null
                          : state._refreshSchoolWebsite,
                    ),
                    YhButton(
                      label: '刷新微信推文',
                      leadingIcon: YhIcons.sync,
                      variant: YhButtonVariant.secondary,
                      onTap:
                          state._refreshService.isRefreshing ||
                              !state._wechatSourceConfigured
                          ? null
                          : state._refreshWechatArticles,
                    ),
                    YhButton(
                      label: '重置筛选',
                      variant: YhButtonVariant.secondary,
                      onTap: () {
                        _clearInfoFilters(state);
                        setDrawerState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
