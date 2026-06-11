/*
 * 信息页桌面控制区 — 标题行操作与筛选工具行
 * @Project : SSPU-AllinOne
 * @File : info_page_controls.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

part of 'info_page.dart';

Widget _buildInfoRegularControls(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final refreshSnapshot = state._refreshService.snapshot;

  return Column(
    key: const Key('info-regular-controls'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildInfoRegularFilterRow(state, theme, isDark),
      _buildInfoActiveFilterChips(state, includeCount: true),
      if (refreshSnapshot.isRefreshing) ...[
        const SizedBox(height: FluentSpacing.xs),
        state._buildRefreshProgress(theme),
      ],
    ],
  );
}

Widget _buildInfoActiveFilterChips(
  _InfoPageState state, {
  required bool includeCount,
}) {
  final chips = <Widget>[
    if (includeCount)
      FluentStatusChip(
        label: '${state._filteredMessages.length} 条',
        icon: FluentIcons.list,
      ),
    if (state._searchQuery.trim().isNotEmpty)
      FluentStatusChip(
        label: '搜索：${state._searchQuery.trim()}',
        icon: FluentIcons.search,
        onClose: () {
          state._searchController.clear();
          state._searchQuery = '';
          state._applyFilters();
        },
      ),
    if (state._filterSourceType != null)
      FluentStatusChip(
        label: state._filterSourceType!.label,
        icon: FluentIcons.filter,
        onClose: () {
          state._filterSourceType = null;
          state._filterSourceName = null;
          state._filterWechatMpName = null;
          state._filterCategory = null;
          state._applyFilters();
        },
      ),
    if (state._filterWechatMpName != null)
      FluentStatusChip(
        label: state._filterWechatMpName!,
        icon: FluentIcons.chat,
        onClose: () {
          state._filterWechatMpName = null;
          state._applyFilters();
        },
      )
    else if (state._filterSourceName != null)
      FluentStatusChip(
        label: state._filterSourceName!.label,
        icon: FluentIcons.news,
        onClose: () {
          state._filterSourceName = null;
          state._filterCategory = null;
          state._applyFilters();
        },
      ),
    if (state._filterCategory != null)
      FluentStatusChip(
        label: state._filterCategory!.label,
        icon: FluentIcons.list,
        onClose: () {
          state._filterCategory = null;
          state._applyFilters();
        },
      ),
    if (state._filterUnreadOnly)
      FluentStatusChip(
        label: '仅未读',
        icon: FluentIcons.read,
        tone: FluentStatusChipTone.brand,
        onClose: () {
          state._filterUnreadOnly = false;
          state._applyFilters();
        },
      ),
  ];

  if (chips.length == 1 && includeCount) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: FluentSpacing.xs),
    child: Wrap(
      spacing: FluentSpacing.xs,
      runSpacing: FluentSpacing.xxs,
      children: chips,
    ),
  );
}

Widget _buildInfoHeaderActions(_InfoPageState state, FluentThemeData theme) {
  final unreadCount = state._stateService.countUnread(
    state._filteredMessages.map((msg) => msg.id).toList(),
  );

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FluentButton.primary(
        size: FluentButtonSize.medium,
        onPressed: state._filteredMessages.isEmpty ? null : state._markAllRead,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.read, size: 16),
            const SizedBox(width: FluentSpacing.xs),
            Text('全部标为已读${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
          ],
        ),
      ),
      const SizedBox(width: FluentSpacing.xs),
      FluentButton.outline(
        size: FluentButtonSize.medium,
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
              const Icon(FluentIcons.refresh, size: 16),
            const SizedBox(width: FluentSpacing.xs),
            const Text('刷新官网消息'),
          ],
        ),
      ),
      const SizedBox(width: FluentSpacing.xs),
      FluentButton.outline(
        size: FluentButtonSize.medium,
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
              const Icon(FluentIcons.sync, size: 16),
            const SizedBox(width: FluentSpacing.xs),
            const Text('刷新微信推文'),
          ],
        ),
      ),
    ],
  );
}

Widget _buildInfoRegularFilterRow(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final useWrap = constraints.maxWidth < 720;
      final controls = <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220),
          child: state._buildSearchBar(theme),
        ),
        state._buildFilterCombo<MessageSourceType>(
          label: '来源类型',
          value: state._filterSourceType,
          items: const [
            MessageSourceType.schoolWebsite,
            MessageSourceType.wechatPublic,
          ],
          itemLabel: (item) => item.label,
          minWidth: 140,
          maxWidth: 170,
          onChanged: (value) {
            state._filterSourceType = value;
            state._filterSourceName = null;
            state._filterWechatMpName = null;
            state._filterCategory = null;
            state._applyFilters();
          },
        ),
        _buildInfoSecondarySourceFilter(state),
        state._buildFilterCombo<MessageCategory>(
          label: '内容分类',
          value: state._filterCategory,
          items: state._getAvailableCategories(),
          itemLabel: (item) => item.label,
          enabled:
              state._filterSourceType != MessageSourceType.wechatPublic &&
              state._filterSourceName != null,
          minWidth: 140,
          maxWidth: 170,
          onChanged: (value) {
            state._filterCategory = value;
            state._applyFilters();
          },
        ),
        _buildInfoUnreadToggle(state, compact: true),
      ];

      if (useWrap) {
        return Wrap(
          spacing: FluentSpacing.xs,
          runSpacing: FluentSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: controls,
        );
      }

      return Row(
        children: [
          Expanded(child: controls[0]),
          for (final control in controls.skip(1)) ...[
            const SizedBox(width: FluentSpacing.xs),
            control,
          ],
        ],
      );
    },
  );
}

Widget _buildInfoSecondarySourceFilter(_InfoPageState state) {
  final wechatSourceSelected =
      state._filterSourceType == MessageSourceType.wechatPublic;

  if (wechatSourceSelected) {
    return state._buildFilterCombo<String>(
      label: '公众号名称',
      value: state._filterWechatMpName,
      items: state._getAvailableWechatMpNames(),
      itemLabel: (item) => item,
      enabled: state._filterSourceType != null,
      minWidth: 150,
      maxWidth: 190,
      onChanged: (value) {
        state._filterWechatMpName = value;
        state._filterCategory = null;
        state._applyFilters();
      },
    );
  }

  return state._buildFilterCombo<MessageSourceName>(
    label: '来源名称',
    value: state._filterSourceName,
    items: state._getAvailableSourceNames(),
    itemLabel: (item) => item.label,
    enabled: state._filterSourceType != null,
    minWidth: 150,
    maxWidth: 190,
    onChanged: (value) {
      state._filterSourceName = value;
      state._filterCategory = null;
      state._applyFilters();
    },
  );
}

Widget _buildInfoRefreshProgress(_InfoPageState state, FluentThemeData theme) {
  final snapshot = state._refreshService.snapshot;
  final progressValue = snapshot.total <= 0
      ? null
      : (snapshot.completed / snapshot.total).clamp(0.0, 1.0);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: FluentSpacing.s,
      vertical: FluentSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: theme.inactiveColor.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(FluentRadius.medium),
    ),
    child: Row(
      children: [
        SizedBox(width: 120, child: FluentProgressBar(value: progressValue)),
        const SizedBox(width: FluentSpacing.s),
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

Widget _buildInfoSearchBar(_InfoPageState state, FluentThemeData theme) {
  return FluentTextField(
    controller: state._searchController,
    placeholder: '搜索消息标题…',
    prefixIcon: FluentIcons.search,
    suffix: state._searchQuery.isNotEmpty
        ? _InfoCompactIconButton(
            tooltip: '清空搜索',
            icon: FluentIcons.clear,
            size: 28,
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

Widget _buildInfoUnreadToggle(_InfoPageState state, {required bool compact}) {
  return Row(
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
      SizedBox(width: compact ? FluentSpacing.xxs : FluentSpacing.xs),
      const Text('仅未读'),
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

class _InfoCompactIconButton extends StatelessWidget {
  const _InfoCompactIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 16,
    this.busy = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final theme = FluentTheme.of(context);
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      iconSize: WidgetStatePropertyAll(iconSize),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radii.mediumBorder),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isPressed) return colors.subtleBackgroundPressed;
        if (states.isHovered || states.isFocused) {
          return colors.subtleBackgroundHover;
        }
        return theme.cardColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) return colors.neutralForegroundDisabled;
        return colors.neutralForeground2;
      }),
    );

    final child = busy
        ? SizedBox.square(
            dimension: iconSize,
            child: const FluentProgressRing(strokeWidth: 2),
          )
        : Icon(icon);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: SizedBox.square(
          dimension: size,
          child: IconButton(icon: child, onPressed: onPressed, style: style),
        ),
      ),
    );
  }
}
