/*
 * 资讯页面头部与内容布局 — 标题、状态、搜索和分页
 * @Project : SSPU-AllinOne
 * @File : info_page_header.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'info_page.dart';

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({required this.state, required this.compact});

  final _InfoPageState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      key: compact ? const Key('info-mobile-controls') : null,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                  : state._refreshAllEnabledSources,
            ),
          ],
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
