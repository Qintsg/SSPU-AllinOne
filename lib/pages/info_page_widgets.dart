part of 'info_page.dart';

Widget _buildInfoPageView(_InfoPageState state, BuildContext context) {
  final theme = FluentTheme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return ResponsiveBuilder(
    builder: (context, deviceType, constraints) {
      if (deviceType == DeviceType.phone) {
        return FluentPage(
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.s),
            child: _buildInfoMobileBody(state, theme, isDark),
          ),
        );
      }

      return FluentPage(
        header: const FluentPageHeader(title: Text('信息中心')),
        content: Padding(
          padding: responsivePagePadding(deviceType),
          child: _buildInfoRegularBody(state, theme, isDark),
        ),
      );
    },
  );
}

Widget _buildInfoRegularBody(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final refreshSnapshot = state._refreshService.snapshot;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FluentSurface(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FluentSectionHeader(
              title: '消息操作',
              subtitle: '搜索、筛选和刷新聚合消息',
              icon: FluentIcons.filter,
            ),
            const SizedBox(height: FluentSpacing.m),
            state._buildActionBar(theme),
            if (refreshSnapshot.isRefreshing) ...[
              const SizedBox(height: FluentSpacing.s),
              state._buildRefreshProgress(theme),
            ],
            const SizedBox(height: FluentSpacing.m),
            state._buildSearchBar(theme),
            const SizedBox(height: FluentSpacing.s),
            state
                ._buildFilterBar(theme, isDark)
                .animate()
                .fadeIn(
                  duration: FluentDuration.slow,
                  curve: FluentEasing.decelerate,
                ),
          ],
        ),
      ),
      const SizedBox(height: FluentSpacing.m),
      Expanded(child: _buildInfoMessagePanel(state, theme, isDark)),
      if (state._filteredMessages.isNotEmpty) ...[
        const SizedBox(height: FluentSpacing.s),
        state._buildPagination(theme),
        const SizedBox(height: FluentSpacing.m),
      ],
    ],
  );
}

Widget _buildInfoMobileBody(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildInfoMobileControls(state, theme),
      const SizedBox(height: FluentSpacing.xs),
      Expanded(child: _buildInfoMessagePanel(state, theme, isDark)),
      if (state._filteredMessages.isNotEmpty) ...[
        const SizedBox(height: FluentSpacing.xs),
        _buildInfoMobilePagination(state, theme),
        const SizedBox(height: FluentSpacing.xs),
      ],
    ],
  );
}

Widget _buildInfoMessagePanel(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final refreshSnapshot = state._refreshService.snapshot;
  if (refreshSnapshot.isRefreshing && state._filteredMessages.isEmpty) {
    return const Center(child: FluentProgressRing());
  }

  if (state._filteredMessages.isEmpty) {
    return FluentSurface(
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.inbox,
              size: 48,
              color: theme.resources.textFillColorSecondary,
            ),
            const SizedBox(height: FluentSpacing.m),
            Text(
              '暂无消息',
              style: theme.typography.body?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: FluentSpacing.s),
            Text(
              '点击上方刷新按钮获取最新消息',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return state._buildMessageList(theme, isDark);
}

Widget _buildInfoActionBar(_InfoPageState state, FluentThemeData theme) {
  final unreadCount = state._stateService.countUnread(
    state._filteredMessages.map((msg) => msg.id).toList(),
  );

  return Wrap(
    spacing: FluentSpacing.s,
    runSpacing: FluentSpacing.s,
    children: [
      FluentButton.primary(
        onPressed: state._filteredMessages.isEmpty ? null : state._markAllRead,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.read, size: 14),
            const SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
            Text('全部标为已读${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
          ],
        ),
      ),
      FluentButton.outline(
        onPressed: state._refreshService.isRefreshing
            ? null
            : () => state._refreshSchoolWebsite(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state._refreshService.isRefreshingSchoolWebsite)
              const SizedBox(
                width: 14,
                height: 14,
                child: FluentProgressRing(strokeWidth: 2),
              )
            else
              const Icon(FluentIcons.refresh, size: 14),
            const SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
            const Text('刷新官网消息'),
          ],
        ),
      ),
      FluentButton.outline(
        onPressed:
            state._refreshService.isRefreshing || !state._wechatSourceConfigured
            ? null
            : state._refreshWechatArticles,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state._refreshService.isRefreshingWechat)
              const SizedBox(
                width: 14,
                height: 14,
                child: FluentProgressRing(strokeWidth: 2),
              )
            else
              const Icon(FluentIcons.refresh, size: 14),
            const SizedBox(width: FluentSpacing.xs + FluentSpacing.xxs),
            const Text('刷新最新微信推文'),
          ],
        ),
      ),
    ],
  );
}

Widget _buildInfoMobileControls(_InfoPageState state, FluentThemeData theme) {
  final unreadCount = state._stateService.countUnread(
    state._filteredMessages.map((msg) => msg.id).toList(),
  );
  final refreshSnapshot = state._refreshService.snapshot;

  return FluentSurface(
    key: const Key('info-mobile-controls'),
    padding: const EdgeInsets.symmetric(
      horizontal: FluentSpacing.s,
      vertical: FluentSpacing.xs,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('信息中心', style: theme.typography.subtitle),
                  Text(
                    '${state._filteredMessages.length} 条消息',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FluentIconButton(
              tooltip: unreadCount > 0 ? '全部标为已读 ($unreadCount)' : '全部标为已读',
              icon: const Icon(FluentIcons.read),
              iconSize: 16,
              onPressed: state._filteredMessages.isEmpty
                  ? null
                  : state._markAllRead,
            ),
            FluentIconButton(
              tooltip: '刷新官网消息',
              icon: state._refreshService.isRefreshingSchoolWebsite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.refresh),
              iconSize: 16,
              onPressed: state._refreshService.isRefreshing
                  ? null
                  : () => state._refreshSchoolWebsite(),
            ),
            FluentIconButton(
              tooltip: state._wechatSourceConfigured ? '刷新微信推文' : '请先配置微信公众号',
              icon: state._refreshService.isRefreshingWechat
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.sync),
              iconSize: 16,
              onPressed:
                  state._refreshService.isRefreshing ||
                      !state._wechatSourceConfigured
                  ? null
                  : state._refreshWechatArticles,
            ),
          ],
        ),
        Row(
          key: const Key('info-mobile-search-row'),
          children: [
            Expanded(child: state._buildSearchBar(theme)),
            const SizedBox(width: FluentSpacing.xs),
            FluentIconButton(
              tooltip: '筛选消息',
              icon: const Icon(FluentIcons.filter),
              iconSize: 16,
              appearance: FluentIconButtonAppearance.outline,
              onPressed: () => _showInfoMobileFilterDialog(state),
            ),
          ],
        ),
        if (refreshSnapshot.isRefreshing) ...[
          const SizedBox(height: FluentSpacing.xs),
          _buildInfoMobileRefreshProgress(state, theme),
        ],
        const SizedBox(height: FluentSpacing.xs),
        _buildInfoMobileFilterSummary(state, theme),
      ],
    ),
  );
}

Widget _buildInfoMobileRefreshProgress(
  _InfoPageState state,
  FluentThemeData theme,
) {
  final snapshot = state._refreshService.snapshot;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: FluentSpacing.s,
      vertical: FluentSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: theme.inactiveColor.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(FluentRadius.large),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: FluentProgressRing(strokeWidth: 2),
        ),
        const SizedBox(width: FluentSpacing.xs),
        Expanded(
          child: Text(
            snapshot.text.isEmpty ? '正在刷新...' : snapshot.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption,
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoMobileFilterSummary(
  _InfoPageState state,
  FluentThemeData theme,
) {
  final labels = _getInfoActiveFilterLabels(state);
  final effectiveLabels = labels.isEmpty ? const ['全部消息'] : labels;

  return SizedBox(
    key: const Key('info-mobile-filter-summary'),
    height: 22,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < effectiveLabels.length; i++) ...[
            _InfoFilterPill(label: effectiveLabels[i]),
            if (i < effectiveLabels.length - 1)
              const SizedBox(width: FluentSpacing.xs),
          ],
        ],
      ),
    ),
  );
}

List<String> _getInfoActiveFilterLabels(_InfoPageState state) {
  final labels = <String>[];
  if (state._searchQuery.trim().isNotEmpty) {
    labels.add('搜索：${state._searchQuery.trim()}');
  }
  if (state._filterSourceType != null) {
    labels.add(state._filterSourceType!.label);
  }
  if (state._filterWechatMpName != null) {
    labels.add(state._filterWechatMpName!);
  } else if (state._filterSourceName != null) {
    labels.add(state._filterSourceName!.label);
  }
  if (state._filterCategory != null) {
    labels.add(state._filterCategory!.label);
  }
  if (state._filterUnreadOnly) {
    labels.add('仅未读');
  }
  return labels;
}

class _InfoFilterPill extends StatelessWidget {
  const _InfoFilterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      height: 22,
      constraints: const BoxConstraints(maxWidth: 160),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.s),
      decoration: BoxDecoration(
        color: theme.inactiveColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(FluentRadius.circular),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorSecondary,
        ),
      ),
    );
  }
}

Widget _buildInfoRefreshProgress(_InfoPageState state, FluentThemeData theme) {
  final snapshot = state._refreshService.snapshot;
  final progressValue = snapshot.total <= 0
      ? null
      : (snapshot.completed / snapshot.total).clamp(0.0, 1.0);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(FluentSpacing.s),
    decoration: BoxDecoration(
      color: theme.inactiveColor.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(FluentRadius.xLarge),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentProgressBar(value: progressValue),
        const SizedBox(height: FluentSpacing.xs),
        Text(
          snapshot.text.isEmpty ? '正在刷新...' : snapshot.text,
          style: theme.typography.caption,
        ),
      ],
    ),
  );
}

Widget _buildInfoSearchBar(_InfoPageState state, FluentThemeData theme) {
  return FluentTextField(
    controller: state._searchController,
    placeholder: '搜索消息标题…',
    prefixIcon: FluentIcons.search,
    suffix: state._searchQuery.isNotEmpty
        ? FluentIconButton(
            icon: const Icon(FluentIcons.clear),
            iconSize: 12,
            onPressed: () {
              state._searchController.clear();
              state._searchQuery = '';
              state._applyFilters();
            },
          )
        : null,
    onChanged: (value) {
      state._searchQuery = value;
      state._applyFilters();
    },
  );
}

Widget _buildInfoFilterBar(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final availableSourceNames = state._getAvailableSourceNames();
  final availableWechatMpNames = state._getAvailableWechatMpNames();
  final availableCategories = state._getAvailableCategories();
  final wechatSourceSelected =
      state._filterSourceType == MessageSourceType.wechatPublic;

  return Wrap(
    spacing: FluentSpacing.s,
    runSpacing: FluentSpacing.s,
    children: [
      state._buildFilterCombo<MessageSourceType>(
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
          state._applyFilters();
        },
      ),
      if (wechatSourceSelected)
        state._buildFilterCombo<String>(
          label: '公众号名称',
          value: state._filterWechatMpName,
          items: availableWechatMpNames,
          itemLabel: (item) => item,
          enabled: state._filterSourceType != null,
          onChanged: (value) {
            state._filterWechatMpName = value;
            state._filterCategory = null;
            state._applyFilters();
          },
        )
      else
        state._buildFilterCombo<MessageSourceName>(
          label: '来源名称',
          value: state._filterSourceName,
          items: availableSourceNames,
          itemLabel: (item) => item.label,
          enabled: state._filterSourceType != null,
          onChanged: (value) {
            state._filterSourceName = value;
            state._filterCategory = null;
            state._applyFilters();
          },
        ),
      state._buildFilterCombo<MessageCategory>(
        label: '内容分类',
        value: state._filterCategory,
        items: availableCategories,
        itemLabel: (item) => item.label,
        enabled: !wechatSourceSelected && state._filterSourceName != null,
        onChanged: (value) {
          state._filterCategory = value;
          state._applyFilters();
        },
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FluentSwitch(
            value: state._filterUnreadOnly,
            semanticLabel: '仅显示未读消息',
            onChanged: (value) {
              state._filterUnreadOnly = value;
              state._applyFilters();
            },
          ),
          const SizedBox(width: FluentSpacing.xs),
          const Text('仅未读'),
        ],
      ),
    ],
  );
}

Widget _buildInfoFilterCombo<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) itemLabel,
  required void Function(T?) onChanged,
  bool enabled = true,
  double minWidth = 180,
  double maxWidth = 240,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
    child: FluentSelect<T?>(
      isExpanded: true,
      value: value,
      placeholder: Text(label),
      items: [
        FluentSelectItem<T?>(value: null, child: Text('全部$label')),
        ...items.map(
          (item) => FluentSelectItem<T?>(
            value: item,
            child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: enabled ? (selectedValue) => onChanged(selectedValue) : null,
    ),
  );
}

Future<void> _showInfoMobileFilterDialog(_InfoPageState state) {
  return showFluentDialog<void>(
    context: state.context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void applyAndRefreshDialog() {
            state._applyFilters();
            if (context.mounted) setDialogState(() {});
          }

          return FluentDialog(
            title: const Text('筛选消息'),
            content: _buildInfoMobileFilterForm(
              state,
              applyAndRefreshDialog: applyAndRefreshDialog,
            ),
            actions: [
              FluentButton.outline(
                child: const Text('重置'),
                onPressed: () {
                  state._filterSourceType = null;
                  state._filterSourceName = null;
                  state._filterWechatMpName = null;
                  state._filterCategory = null;
                  state._filterUnreadOnly = false;
                  applyAndRefreshDialog();
                },
              ),
              FluentButton.primary(
                child: const Text('完成'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildInfoMobileFilterForm(
  _InfoPageState state, {
  required VoidCallback applyAndRefreshDialog,
}) {
  final availableSourceNames = state._getAvailableSourceNames();
  final availableWechatMpNames = state._getAvailableWechatMpNames();
  final availableCategories = state._getAvailableCategories();
  final wechatSourceSelected =
      state._filterSourceType == MessageSourceType.wechatPublic;

  Widget combo<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: _buildInfoFilterCombo<T>(
        label: label,
        value: value,
        items: items,
        itemLabel: itemLabel,
        onChanged: onChanged,
        enabled: enabled,
        maxWidth: double.infinity,
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      combo<MessageSourceType>(
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
          applyAndRefreshDialog();
        },
      ),
      const SizedBox(height: FluentSpacing.s),
      if (wechatSourceSelected)
        combo<String>(
          label: '公众号名称',
          value: state._filterWechatMpName,
          items: availableWechatMpNames,
          itemLabel: (item) => item,
          enabled: state._filterSourceType != null,
          onChanged: (value) {
            state._filterWechatMpName = value;
            state._filterCategory = null;
            applyAndRefreshDialog();
          },
        )
      else
        combo<MessageSourceName>(
          label: '来源名称',
          value: state._filterSourceName,
          items: availableSourceNames,
          itemLabel: (item) => item.label,
          enabled: state._filterSourceType != null,
          onChanged: (value) {
            state._filterSourceName = value;
            state._filterCategory = null;
            applyAndRefreshDialog();
          },
        ),
      const SizedBox(height: FluentSpacing.s),
      combo<MessageCategory>(
        label: '内容分类',
        value: state._filterCategory,
        items: availableCategories,
        itemLabel: (item) => item.label,
        enabled: !wechatSourceSelected && state._filterSourceName != null,
        onChanged: (value) {
          state._filterCategory = value;
          applyAndRefreshDialog();
        },
      ),
      const SizedBox(height: FluentSpacing.s),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FluentSwitch(
            value: state._filterUnreadOnly,
            semanticLabel: '仅显示未读消息',
            onChanged: (value) {
              state._filterUnreadOnly = value;
              applyAndRefreshDialog();
            },
          ),
          const SizedBox(width: FluentSpacing.xs),
          const Text('仅显示未读'),
        ],
      ),
    ],
  );
}

Widget _buildInfoMessageList(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final messages = state._pagedMessages;

  return FluentSurface(
    key: const Key('info-message-list'),
    padding: const EdgeInsets.symmetric(vertical: FluentSpacing.s),
    child: ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isRead = state._stateService.isRead(message.id);

        return MessageTile(
          message: message,
          isRead: isRead,
          isDark: isDark,
          onTap: () => state._openMessage(message),
          onMarkRead: () async {
            await state._stateService.markAsRead(message.id);
            state._refreshView();
          },
        );
      },
    ),
  );
}

Widget _buildInfoMobilePagination(_InfoPageState state, FluentThemeData theme) {
  return SizedBox(
    key: const Key('info-mobile-pagination'),
    height: 48,
    child: Row(
      children: [
        FluentIconButton(
          tooltip: '上一页',
          icon: const Icon(FluentIcons.chevronLeft),
          iconSize: 16,
          onPressed: state._currentPage > 0
              ? () => state._setCurrentPage(state._currentPage - 1)
              : null,
        ),
        Expanded(
          child: Tooltip(
            message: '点击跳转到指定页',
            child: FluentHoverButton(
              onPressed: () => state._showPageJumpDialog(),
              builder: (context, states) {
                return Center(
                  child: Text(
                    '${state._currentPage + 1}/${state._totalPages} · '
                    '${state._filteredMessages.length} 条',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption?.copyWith(
                      decoration: states.isHovered
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        FluentIconButton(
          tooltip: '下一页',
          icon: const Icon(FluentIcons.chevronRight),
          iconSize: 16,
          onPressed: state._currentPage < state._totalPages - 1
              ? () => state._setCurrentPage(state._currentPage + 1)
              : null,
        ),
      ],
    ),
  );
}

Widget _buildInfoPagination(_InfoPageState state, FluentThemeData theme) {
  return Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: FluentSpacing.s,
    runSpacing: FluentSpacing.xs,
    children: [
      FluentIconButton(
        icon: const Icon(FluentIcons.chevronLeft),
        iconSize: 12,
        onPressed: state._currentPage > 0
            ? () => state._setCurrentPage(state._currentPage - 1)
            : null,
      ),
      Tooltip(
        message: '点击跳转到指定页',
        child: FluentHoverButton(
          onPressed: () => state._showPageJumpDialog(),
          builder: (context, states) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                '第 ${state._currentPage + 1} / ${state._totalPages} 页 '
                '(共 ${state._filteredMessages.length} 条)',
                style: theme.typography.caption?.copyWith(
                  decoration: states.isHovered
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
      FluentIconButton(
        icon: const Icon(FluentIcons.chevronRight),
        iconSize: 12,
        onPressed: state._currentPage < state._totalPages - 1
            ? () => state._setCurrentPage(state._currentPage + 1)
            : null,
      ),
    ],
  );
}

Future<void> _showInfoPageJumpDialog(_InfoPageState state) async {
  final controller = TextEditingController();
  final result = await showDialog<int>(
    context: state.context,
    builder: (ctx) => FluentDialog(
      title: const Text('跳转到指定页'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前第 ${state._currentPage + 1} 页，共 ${state._totalPages} 页'),
          const SizedBox(height: FluentSpacing.s),
          FluentTextField(
            controller: controller,
            placeholder: '输入页码 (1-${state._totalPages})',
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (_) {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= state._totalPages) {
                Navigator.of(ctx).pop(page - 1);
              }
            },
          ),
        ],
      ),
      actions: [
        FluentButton.outline(
          child: const Text('取消'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        FluentButton.primary(
          child: const Text('跳转'),
          onPressed: () {
            final page = int.tryParse(controller.text);
            if (page != null && page >= 1 && page <= state._totalPages) {
              Navigator.of(ctx).pop(page - 1);
            }
          },
        ),
      ],
    ),
  );
  controller.dispose();

  if (result != null && state.mounted) {
    state._setCurrentPage(result);
  }
}
