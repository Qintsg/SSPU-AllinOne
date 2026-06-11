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
        _buildInfoActiveFilterChips(state, includeCount: true),
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
