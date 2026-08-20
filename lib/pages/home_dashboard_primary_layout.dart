/*
 * 清源首页主布局 — 编排首屏时间轨与可配置的服务摘要。
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_primary_layout.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'home_page.dart';

extension _HomeDashboardPrimaryLayout on _HomePageState {
  /// 返回当前首页右侧可见的校园服务摘要数量。
  int get _homeOverviewItemCount => [
    _studentProfileCardVisible,
    _campusCardCardVisible,
    _emailTileVisible,
    _sportsAttendanceTileVisible,
  ].where((visible) => visible).length;

  /// 计算紧凑端时间轨与概览账本的总高度，避免关闭项目后保留空行。
  double _homeCompactPrimaryHeight(
    YhTheme theme, {
    required bool contentState,
  }) {
    final defaultOverviewHeight =
        theme.control.regular * 2 + theme.spacing.xl + theme.layout.divider;
    final fullHeight =
        theme.layout.popoverWidth +
        theme.control.regular * 2 +
        theme.spacing.xl +
        (contentState ? theme.spacing.xl2 : 0);
    final timelineHeight = fullHeight - defaultOverviewHeight - theme.spacing.s;
    final count = _homeOverviewItemCount;
    if (count == 0) return timelineHeight;
    final rows = (count + 1) ~/ 2;
    final rowHeight = theme.control.regular + theme.spacing.m;
    final overviewHeight = rowHeight * rows + theme.layout.divider * (rows - 1);
    return timelineHeight + theme.spacing.s + overviewHeight;
  }

  /// 构建首页主次区域的响应式布局。
  Widget _buildHomePrimaryLayout(
    YhTheme theme,
    double width, {
    required bool compact,
  }) {
    final timeline = _buildTimelinePanel(theme);
    final overviewCount = _homeOverviewItemCount;
    if (overviewCount == 0) return timeline;
    final overview = _buildAnimatedHomeOverviewStack(
      theme,
      compactGrid: compact,
    );
    if (compact) {
      final rows = (overviewCount + 1) ~/ 2;
      final rowHeight = theme.control.regular + theme.spacing.m;
      final overviewHeight =
          rowHeight * rows + theme.layout.divider * (rows - 1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: timeline),
          SizedBox(height: theme.spacing.s),
          SizedBox(height: overviewHeight, child: overview),
        ],
      );
    }
    final overviewSlot = overviewCount <= 2
        ? Align(
            alignment: AlignmentDirectional.topCenter,
            child: SizedBox(width: double.infinity, child: overview),
          )
        : overview;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: theme.responsive.homePrimaryFlex, child: timeline),
        SizedBox(width: theme.spacing.m),
        Expanded(flex: theme.responsive.homeSecondaryFlex, child: overviewSlot),
      ],
    );
  }

  /// 在首页设置变化时平滑收束概览账本，并尊重系统减少动态设置。
  Widget _buildAnimatedHomeOverviewStack(
    YhTheme theme, {
    required bool compactGrid,
  }) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSize(
      duration: theme.motion.effective(
        theme.motion.base,
        disableAnimations: disableAnimations,
      ),
      curve: theme.motion.curve,
      alignment: AlignmentDirectional.topCenter,
      child: _buildHomeOverviewStack(theme, compactGrid: compactGrid),
    );
  }

  /// 构建首屏的今日学程时间轨。
  Widget _buildTimelinePanel(YhTheme theme) {
    final entries = _homeTimelineEntries;
    final nextIndex = entries.indexWhere((entry) => entry.isUpcoming);
    final next = nextIndex < 0 ? null : entries[nextIndex];
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tightCompact = viewportWidth < theme.breakpoint.compact;
    final dense = viewportWidth < theme.breakpoint.large;
    final fluidPanelPadding =
        viewportWidth * theme.responsive.panelPaddingViewportPercent / 100;
    final panelPadding = dense
        ? viewportWidth < theme.breakpoint.compact
              ? theme.spacing.m
              : theme.spacing.l
        : fluidPanelPadding.clamp(theme.spacing.l, theme.spacing.xl).toDouble();
    final fluidHeroSize =
        viewportWidth * theme.responsive.homeHeroViewportPercent / 100;
    final heroStyle = theme.typography.hero.copyWith(
      fontSize: fluidHeroSize
          .clamp(
            theme.typography.h1.fontSize! - theme.layout.divider,
            theme.typography.display.fontSize!,
          )
          .toDouble(),
    );
    return Semantics(
      label: '今日学程时间轨',
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radius.l),
        child: DecoratedBox(
          key: const Key('home-today-courses-tile'),
          decoration: BoxDecoration(color: theme.color.structural),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HomeTimelineBackdropPainter(theme),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(panelPadding),
                child: DefaultTextStyle.merge(
                  style: theme.typography.body.copyWith(
                    color: theme.color.onStructural,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '今日学程时间轨',
                              style: _timelineMetaStyle(theme),
                            ),
                          ),
                          Text(
                            '${_todayCourseEntries.length} 节课 · '
                            '${_latestMessages.length} 项待办',
                            style: _timelineMetaStyle(theme),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: tightCompact
                            ? theme.spacing.s
                            : dense
                            ? theme.spacing.l + theme.layout.divider * 2
                            : theme.spacing.xl,
                      ),
                      if (next == null)
                        Text(
                          '今天的已缓存日程已经看完',
                          style: heroStyle.copyWith(
                            color: theme.color.onStructural,
                          ),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '下一项是 '),
                              TextSpan(
                                text: next.title,
                                style: TextStyle(
                                  color: theme.color.onStructural,
                                  fontWeight: theme.typography.semibold,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '\n还有 ${widget.homeCountdownMinutesOverride ?? next.minutesUntil} 分钟开始',
                              ),
                            ],
                          ),
                          style: heroStyle.copyWith(
                            color: theme.color.onStructural,
                          ),
                        ),
                      SizedBox(
                        height: tightCompact
                            ? theme.spacing.m + theme.spacing.xs
                            : dense
                            ? theme.spacing.xl + theme.layout.divider * 2
                            : theme.spacing.xl,
                      ),
                      if (entries.isEmpty)
                        Text(
                          '打开课表或信息页刷新后，今天的课程与待办会显示在这里。',
                          style: theme.typography.body.copyWith(
                            color: _timelineDetailColor(theme),
                          ),
                        )
                      else
                        for (var index = 0; index < entries.length; index++)
                          _HomeTimelineRow(
                            entry: entries[index],
                            current: index == nextIndex,
                            last: index == entries.length - 1,
                            dense: dense,
                          ),
                      if (!dense) SizedBox(height: theme.focus.ringWidth),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _timelineMetaStyle(YhTheme theme) {
    return theme.typography.small.copyWith(
      color: theme.color.onStructural.withValues(
        alpha: theme.opacity.timelineMeta,
      ),
    );
  }

  Color _timelineDetailColor(YhTheme theme) {
    return theme.color.onStructural.withValues(
      alpha: theme.opacity.timelineDetail,
    );
  }
}
