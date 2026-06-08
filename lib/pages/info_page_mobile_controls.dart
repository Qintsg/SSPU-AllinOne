/*
 * 信息页移动控制区 — 搜索优先的紧凑操作行
 * @Project : SSPU-AllinOne
 * @File : info_page_mobile_controls.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

part of 'info_page.dart';

Widget _buildInfoMobileControls(_InfoPageState state, FluentThemeData theme) {
  final refreshSnapshot = state._refreshService.snapshot;
  return Padding(
    key: const Key('info-mobile-controls'),
    padding: const EdgeInsets.symmetric(
      horizontal: FluentSpacing.xs,
      vertical: FluentSpacing.xs,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const Key('info-mobile-search-row'),
          children: [
            Expanded(child: state._buildSearchBar(theme)),
            const SizedBox(width: FluentSpacing.xxs),
            _InfoCompactIconButton(
              key: const Key('info-mobile-filter-button'),
              tooltip: '筛选消息',
              icon: FluentIcons.filter,
              onPressed: () => _showInfoMobileFilterDialog(state),
            ),
            _InfoCompactIconButton(
              tooltip: '全部标为已读',
              icon: FluentIcons.read,
              onPressed: state._filteredMessages.isEmpty
                  ? null
                  : state._markAllRead,
            ),
            _InfoCompactIconButton(
              tooltip: '刷新官网消息',
              icon: FluentIcons.refresh,
              busy: state._refreshService.isRefreshingSchoolWebsite,
              onPressed: state._refreshService.isRefreshing
                  ? null
                  : () => state._refreshSchoolWebsite(),
            ),
            _InfoCompactIconButton(
              tooltip: state._wechatSourceConfigured ? '刷新微信推文' : '请先配置微信公众号',
              icon: FluentIcons.sync,
              busy: state._refreshService.isRefreshingWechat,
              onPressed:
                  state._refreshService.isRefreshing ||
                      !state._wechatSourceConfigured
                  ? null
                  : state._refreshWechatArticles,
            ),
          ],
        ),
        const SizedBox(height: FluentSpacing.xxs),
        _buildInfoMobileFilterSummary(state, theme),
        if (refreshSnapshot.isRefreshing) ...[
          const SizedBox(height: FluentSpacing.xxs),
          _buildInfoMobileRefreshProgress(state, theme),
        ],
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
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.xs),
    decoration: BoxDecoration(
      color: theme.inactiveColor.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(FluentRadius.medium),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 12,
          height: 12,
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
  final messageCountLabel = '${state._filteredMessages.length} 条';
  final effectiveLabels = labels.isEmpty
      ? <String>[messageCountLabel, '全部消息']
      : <String>[messageCountLabel, ...labels];

  return SizedBox(
    key: const Key('info-mobile-filter-summary'),
    height: 20,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < effectiveLabels.length; i++) ...[
            _InfoFilterPill(label: effectiveLabels[i]),
            if (i < effectiveLabels.length - 1)
              const SizedBox(width: FluentSpacing.xxs),
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
      height: 20,
      constraints: const BoxConstraints(maxWidth: 150),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.xs),
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
