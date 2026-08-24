/*
 * 清源首页视图 — 今日学程时间轨与校园服务概览
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_view.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'home_page.dart';

extension _HomeDashboardView on _HomePageState {
  /// 构建清源首页固定首屏骨架。
  Widget _buildQingyuanHomePage(BuildContext context) {
    final theme = context.yhTheme;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final compact =
              viewportWidth < theme.breakpoint.compact ||
              constraints.maxWidth < theme.breakpoint.compact;
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final minimumFixedViewportHeight =
              theme.layout.formContentWidth +
              theme.control.regular * 3 +
              theme.spacing.s;
          final allowScrolling =
              textScale > 1.2 ||
              constraints.maxHeight < minimumFixedViewportHeight;
          final pagePadding = compact
              ? theme.spacing.m
              : viewportWidth < theme.breakpoint.expanded
              ? theme.spacing.xl
              : theme.spacing.xl2;
          final page = Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: theme.layout.pageContentWidth,
                minHeight: allowScrolling ? 0 : constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  compact ? theme.spacing.m : theme.spacing.xl,
                  pagePadding,
                  compact ? theme.spacing.s : theme.spacing.xl,
                ),
                child: _buildHomeViewport(
                  theme,
                  width: constraints.maxWidth,
                  compact: compact,
                  allowScrolling: allowScrolling,
                ),
              ),
            ),
          );
          if (allowScrolling) {
            return SingleChildScrollView(child: page);
          }
          return page;
        },
      ),
    );
  }

  /// 按可用宽高编排时间轨、概览与行动坞。
  Widget _buildHomeViewport(
    YhTheme theme, {
    required double width,
    required bool compact,
    required bool allowScrolling,
  }) {
    final state = _homeDashboardDisplayState;
    final desktopPrimaryHeight =
        (MediaQuery.sizeOf(context).height *
                theme.responsive.homeContentHeightViewportPercent /
                100)
            .clamp(
              theme.layout.homeContentMinHeight,
              theme.layout.homeContentMaxHeight,
            )
            .toDouble();
    final retainedContent = {
      HomeDashboardDisplayState.content,
      HomeDashboardDisplayState.stale,
      HomeDashboardDisplayState.partialError,
      HomeDashboardDisplayState.credentialsPartial,
      HomeDashboardDisplayState.operationLocked,
    }.contains(state);
    final body = <Widget>[
      _buildHomeHeading(theme, compact: compact),
      if (retainedContent) ...[
        if (state == HomeDashboardDisplayState.content)
          _buildHomeStatusRow(theme),
        if (state != HomeDashboardDisplayState.content) ...[
          _buildHomeRetainedBanner(state),
          SizedBox(height: theme.spacing.m),
        ],
        if (allowScrolling)
          SizedBox(
            height: compact
                ? theme.layout.formContentWidth + theme.spacing.xl2
                : theme.layout.formContentWidth,
            child: _buildHomePrimaryLayout(theme, width, compact: compact),
          )
        else if (compact)
          SizedBox(
            height: _homeCompactPrimaryHeight(
              theme,
              contentState: state == HomeDashboardDisplayState.content,
            ),
            child: _buildHomePrimaryLayout(theme, width, compact: compact),
          )
        else
          SizedBox(
            height: desktopPrimaryHeight,
            child: _buildHomePrimaryLayout(theme, width, compact: compact),
          ),
        _buildHomeUtilityDock(theme, compact: compact),
      ] else
        _buildHomeStatePanel(theme, state),
    ];
    return Column(
      mainAxisSize: allowScrolling ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: body,
    );
  }

  HomeDashboardDisplayState get _homeDashboardDisplayState {
    final override = widget.dashboardDisplayStateOverride;
    if (override != null) return override;
    if (_campusCardRefreshController.isLoading && _hasHomeCacheData) {
      return HomeDashboardDisplayState.operationLocked;
    }
    if (_dashboardCachesLoading) return HomeDashboardDisplayState.loading;
    if (_dashboardCacheError != null) {
      return _hasHomeCacheData
          ? HomeDashboardDisplayState.stale
          : HomeDashboardDisplayState.error;
    }
    if (!_hasHomeCacheData) return HomeDashboardDisplayState.initial;
    if (_hasStaleHomeCache) {
      return HomeDashboardDisplayState.stale;
    }
    return HomeDashboardDisplayState.content;
  }

  bool get _hasHomeCacheData =>
      _campusCardResult != null ||
      _courseTableResult != null ||
      _academicOverviewResult != null ||
      _sportsAttendanceResult != null ||
      _studentReportResult != null ||
      _emailResult != null ||
      _latestMessages.isNotEmpty;

  bool get _hasStaleHomeCache {
    final now = widget.nowOverride ?? DateTime.now();
    bool stale(DateTime checkedAt) =>
        now.difference(checkedAt) >= const Duration(hours: 1);
    final results = <({DateTime checkedAt, bool success})>[
      if (_campusCardResult case final result?)
        (checkedAt: result.checkedAt, success: result.isSuccess),
      if (_courseTableResult case final result?)
        (checkedAt: result.checkedAt, success: result.isSuccess),
      if (_academicOverviewResult case final result?)
        (checkedAt: result.checkedAt, success: result.isSuccess),
      if (_sportsAttendanceResult case final result?)
        (checkedAt: result.checkedAt, success: result.isSuccess),
      if (_studentReportResult case final result?)
        (checkedAt: result.checkedAt, success: result.isSuccess),
      if (_emailResult case final result?)
        (checkedAt: result.checkedAt, success: result.isSuccess),
    ];
    if (results.any((result) => !result.success || stale(result.checkedAt))) {
      return true;
    }
    return false;
  }

  Widget _buildHomeStatePanel(YhTheme theme, HomeDashboardDisplayState state) {
    final content = switch (state) {
      HomeDashboardDisplayState.initial => _buildHomeStateMessage(
        theme,
        icon: YhIcons.calendar,
        title: '尚未整理今天',
        message: '先读取本机缓存；只有主动刷新时才访问校园服务。',
        action: YhButton(label: '读取首页数据', onTap: _refreshHome),
      ),
      HomeDashboardDisplayState.loading => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          YhRing.activity(label: '正在整理首页数据', size: theme.control.compact),
          SizedBox(width: theme.spacing.m),
          Flexible(
            child: ConstrainedBox(
              key: const Key('home-loading-copy'),
              constraints: BoxConstraints(
                maxWidth: theme.layout.statusProgressWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('正在整理今天', style: theme.typography.h3),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    '正在汇总固定的脱敏课程、待办与校园服务数据。',
                    style: theme.typography.body.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      HomeDashboardDisplayState.error => _buildHomeStateMessage(
        theme,
        icon: YhIcons.info,
        title: '无法更新首页数据',
        message: '请检查账户与网络后重试；已有本地缓存不会被删除。',
        action: YhButton(label: '重试', onTap: _refreshHome),
      ),
      HomeDashboardDisplayState.content ||
      HomeDashboardDisplayState.stale ||
      HomeDashboardDisplayState.partialError ||
      HomeDashboardDisplayState.credentialsPartial ||
      HomeDashboardDisplayState.operationLocked => const SizedBox.shrink(),
    };
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
        child: YhCard(
          key: ValueKey('home-dashboard-state-${state.name}'),
          padding: EdgeInsets.zero,
          child: state == HomeDashboardDisplayState.loading
              ? Padding(
                  padding: EdgeInsets.all(theme.spacing.l),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }

  /// 构建保留有效内容的协同状态横幅。
  Widget _buildHomeRetainedBanner(HomeDashboardDisplayState state) {
    final (text, kind, icon) = switch (state) {
      HomeDashboardDisplayState.stale => (
        '当前显示 ${_latestHomeUpdate == null ? '较早' : _formatHomeTime(_latestHomeUpdate!)} 的本地首页缓存；部分校园服务可能已更新。',
        YhBannerKind.warn,
        YhIcons.info,
      ),
      HomeDashboardDisplayState.partialError => (
        '邮箱与体育考勤更新失败；课程、校园卡和已有摘要仍可使用。',
        YhBannerKind.warn,
        YhIcons.warning,
      ),
      HomeDashboardDisplayState.credentialsPartial => (
        '邮箱与体育尚未连接；本机课程和校园卡仍可使用，可稍后在设置中连接。',
        YhBannerKind.info,
        YhIcons.info,
      ),
      HomeDashboardDisplayState.operationLocked => (
        '正在刷新首页；当前内容保持可用，完成前不会重复请求。',
        YhBannerKind.info,
        YhIcons.sync,
      ),
      _ => ('', YhBannerKind.info, YhIcons.info),
    };
    final banner = YhBanner(text: text, kind: kind, leadingIcon: icon);
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    return Padding(
      key: Key('home-dashboard-${state.name}-banner'),
      padding: EdgeInsets.only(top: compact ? theme.spacing.xs : 0),
      child: banner,
    );
  }

  Widget _buildHomeStateMessage(
    YhTheme theme, {
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
  }) {
    final compactGap = theme.spacing.xs + theme.layout.divider * 2;
    return Padding(
      padding: EdgeInsets.all(theme.spacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.brandTint,
              borderRadius: BorderRadius.circular(theme.radius.m),
            ),
            child: SizedBox.square(
              dimension: theme.control.regular,
              child: Icon(
                icon,
                size: theme.spacing.xl,
                color: theme.color.brandStrong,
              ),
            ),
          ),
          SizedBox(height: compactGap),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.h3,
            ),
          ),
          SizedBox(height: compactGap),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.statusProgressWidth,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
          SizedBox(height: compactGap),
          action,
        ],
      ),
    );
  }

  Widget _buildHomeHeading(YhTheme theme, {required bool compact}) {
    final now = widget.nowOverride ?? DateTime.now();
    final greeting = _greetingPhrases(now);
    final heading = Column(
      key: const Key('home-page-heading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact) SizedBox(height: theme.spacing.xs),
        Text(
          '${now.month} 月 ${now.day} 日 · ${_weekdayLabel(now.weekday)}',
          style: theme.typography.caption.copyWith(
            color: theme.color.brandInk,
            fontWeight: theme.typography.semibold,
            letterSpacing: theme.layout.divider,
          ),
        ),
        SizedBox(height: compact ? theme.spacing.xs : theme.spacing.s),
        Semantics(
          header: true,
          label: greeting.text,
          child: compact
              ? _HomeGreetingPhraseWrap(
                  leading: greeting.leading,
                  focus: greeting.focus,
                  style: theme.typography.h1,
                )
              : Text(greeting.text, style: theme.typography.h1),
        ),
        if (!compact) ...[
          SizedBox(height: theme.spacing.s),
          Text(
            key: const Key('home-heading-description'),
            '课程、待办和校园服务状态集中在同一条时间语境里，数据均保留在本机。',
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
        ],
      ],
    );
    final refreshAction = RefreshFeedbackAction(
      key: const Key('home-campus-card-refresh'),
      tooltip: '刷新首页',
      semanticLabel: '刷新首页',
      isLoading: _campusCardRefreshController.isLoading,
      feedback: _campusCardRefreshController.feedback,
      onPressed:
          _homeDashboardDisplayState ==
              HomeDashboardDisplayState.operationLocked
          ? null
          : _refreshHome,
      minTouchSize: theme.control.minimumTarget,
      maxFeedbackWidth: theme.layout.inlineControlWidth,
    );
    final content = compact
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              SizedBox(width: theme.spacing.s),
              refreshAction,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              SizedBox(width: theme.spacing.l),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YhButton(
                    key: const Key('home-customize'),
                    label: '自定义首页',
                    variant: YhButtonVariant.secondary,
                    onTap: widget.onOpenSettings,
                  ),
                  SizedBox(width: theme.spacing.s),
                  refreshAction,
                ],
              ),
            ],
          );
    return Padding(
      padding: EdgeInsets.only(
        bottom: compact ? theme.spacing.xs : theme.spacing.m + theme.spacing.xs,
      ),
      child: content,
    );
  }

  Widget _buildHomeStatusRow(YhTheme theme) {
    final updatedAt = _latestHomeUpdate;
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.m),
      child: Wrap(
        spacing: theme.spacing.s,
        runSpacing: theme.spacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CampusNetworkStatusIndicator(
            service: widget.campusNetworkStatusService,
            variant: CampusNetworkStatusIndicatorVariant.home,
            indicatorKey: const Key('campus-network-status-home'),
          ),
          YhStatusPill(
            label: updatedAt == null
                ? '本地数据 · 等待更新'
                : '本地数据 · ${_formatHomeTime(updatedAt)} 更新',
            kind: YhStatusKind.info,
          ),
        ],
      ),
    );
  }
}
