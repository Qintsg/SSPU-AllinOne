/*
 * 资讯页面高级筛选、刷新反馈与消息列表视图
 * @Project : SSPU-AllinOne
 * @File : info_page_filter_view.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'info_page.dart';

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
    if (state._filteredMessages.isEmpty || state.widget.filterEmptyOverride) {
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          height: theme.layout.popoverWidth + theme.spacing.xl,
          child: YhCard(
            key: const Key('info-filter-empty'),
            child: _InfoEmptyState(
              icon: YhIcons.search,
              title: '当前筛选没有结果',
              message: '更换来源或清除搜索词后，可恢复显示全部校园资讯。',
              action: YhButton(
                label: '清除筛选',
                variant: YhButtonVariant.secondary,
                onTap: () => _clearInfoFilters(state),
              ),
            ),
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
