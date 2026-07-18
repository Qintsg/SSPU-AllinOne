/* 清源信息中心展示层。 */

part of 'info_page.dart';

Widget _buildInfoPageView(_InfoPageState state, BuildContext context) {
  final theme = context.yhTheme;
  return YhPageScaffold(
    appBar: const YhAppBar(title: '信息中心'),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoint.medium;
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleInfoPaginationKey(state, event),
          child: Padding(
            padding: EdgeInsets.all(
              compact ? theme.spacing.s : theme.spacing.m,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.breakpoint.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (compact)
                      _InfoMobileControls(state: state)
                    else
                      _InfoRegularControls(state: state),
                    if (state._refreshService.snapshot.isRefreshing) ...[
                      SizedBox(height: theme.spacing.s),
                      _InfoRefreshProgress(state: state),
                    ],
                    SizedBox(height: theme.spacing.s),
                    Expanded(child: _InfoMessagePanel(state: state)),
                    if (state._filteredMessages.isNotEmpty) ...[
                      SizedBox(height: theme.spacing.s),
                      SizedBox(
                        key: Key(
                          compact
                              ? 'info-mobile-pagination'
                              : 'info-regular-pagination',
                        ),
                        height: theme.control.minimumTarget,
                        child: Align(
                          alignment: Alignment.center,
                          child: YhPagination(
                            page: state._currentPage + 1,
                            pageCount: state._totalPages,
                            simple: compact,
                            onChanged: (page) =>
                                state._setCurrentPage(page - 1),
                          ),
                        ),
                      ),
                    ],
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

class _InfoMobileControls extends StatelessWidget {
  const _InfoMobileControls({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      key: const Key('info-mobile-controls'),
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _InfoSearchField(state: state)),
          SizedBox(width: theme.spacing.xs),
          YhTooltip(
            message: '筛选消息',
            child: YhIconButton(
              key: const Key('info-mobile-filter-button'),
              icon: YhIcons.filter,
              semanticLabel: '筛选消息',
              selected: _hasInfoFilters(state),
              onTap: () => _showInfoFilterDrawer(context, state),
            ),
          ),
          YhTooltip(
            message: '全部标为已读',
            child: YhIconButton(
              icon: YhIcons.check,
              semanticLabel: '全部标为已读',
              onTap: state._filteredMessages.isEmpty
                  ? null
                  : state._markAllRead,
            ),
          ),
          YhTooltip(
            message: '刷新官网消息',
            child: YhIconButton(
              icon: YhIcons.refresh,
              semanticLabel: '刷新官网消息',
              onTap: state._refreshService.isRefreshing
                  ? null
                  : state._refreshSchoolWebsite,
            ),
          ),
          YhTooltip(
            message: '刷新微信推文',
            child: YhIconButton(
              icon: YhIcons.sync,
              semanticLabel: '刷新微信推文',
              onTap:
                  state._refreshService.isRefreshing ||
                      !state._wechatSourceConfigured
                  ? null
                  : state._refreshWechatArticles,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRegularControls extends StatelessWidget {
  const _InfoRegularControls({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final unreadCount = state._stateService.countUnread(
      state._filteredMessages.map((message) => message.id).toList(),
    );
    return Column(
      key: const Key('info-regular-controls'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _InfoSearchField(state: state)),
            SizedBox(width: theme.spacing.s),
            YhButton(
              label: '全部标为已读${unreadCount > 0 ? ' ($unreadCount)' : ''}',
              leadingIcon: YhIcons.check,
              onTap: state._filteredMessages.isEmpty
                  ? null
                  : state._markAllRead,
            ),
            SizedBox(width: theme.spacing.s),
            YhButton(
              label: '刷新官网消息',
              leadingIcon: YhIcons.refresh,
              variant: YhButtonVariant.secondary,
              onTap: state._refreshService.isRefreshing
                  ? null
                  : state._refreshSchoolWebsite,
            ),
            SizedBox(width: theme.spacing.s),
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
          ],
        ),
        SizedBox(height: theme.spacing.s),
        _InfoFilterFields(state: state),
        _InfoActiveFilters(state: state),
      ],
    );
  }
}

class _InfoSearchField extends StatelessWidget {
  const _InfoSearchField({required this.state});

  final _InfoPageState state;

  @override
  Widget build(BuildContext context) {
    return YhTextField(
      label: '搜索',
      controller: state._searchController,
      hint: '搜索消息标题…',
      prefixIcon: YhIcons.search,
      suffix: state._searchQuery.isEmpty
          ? null
          : YhIconButton(
              icon: YhIcons.close,
              semanticLabel: '清空搜索',
              variant: YhIconButtonVariant.ghost,
              onTap: () {
                state._searchController.clear();
                state._searchQuery = '';
                state._applyFilters();
              },
            ),
      onChanged: (value) {
        state._searchQuery = value;
        state._applyFilters();
      },
    );
  }
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
    if (state._refreshService.snapshot.isRefreshing &&
        state._filteredMessages.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.spacing.xl2 * 5),
          child: const YhProgress(value: null, semanticLabel: '正在刷新消息'),
        ),
      );
    }
    if (state._filteredMessages.isEmpty) {
      return const YhEmptyState(
        icon: YhIcons.mail,
        title: '暂无消息',
        message: '点击刷新按钮获取最新消息。',
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
          isDark: false,
          onTap: () => state._openMessage(message),
          onMarkRead: () async {
            await state._stateService.markAsRead(message.id);
            state._refreshView();
          },
        );
      },
    );
  }
}

bool _hasInfoFilters(_InfoPageState state) =>
    state._filterSourceType != null ||
    state._filterSourceName != null ||
    state._filterWechatMpName != null ||
    state._filterCategory != null ||
    state._filterUnreadOnly;

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
                SizedBox(height: theme.spacing.m),
                YhButton(
                  label: '重置筛选',
                  variant: YhButtonVariant.secondary,
                  onTap: () {
                    state._filterSourceType = null;
                    state._filterSourceName = null;
                    state._filterWechatMpName = null;
                    state._filterCategory = null;
                    state._filterUnreadOnly = false;
                    state._applyFilters();
                    setDrawerState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
