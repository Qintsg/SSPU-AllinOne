/*
 * 清源首页内容面板 — 时间轨、业务概览与行动坞
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_content.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'home_page.dart';

extension _HomeDashboardContent on _HomePageState {
  Widget _buildHomeOverviewStack(YhTheme theme, {required bool compactGrid}) {
    final children = <Widget>[];
    void add(Widget child) => children.add(child);

    if (_studentProfileCardVisible) {
      add(_buildProgramOverviewCard(theme, compact: compactGrid));
    }
    if (_campusCardCardVisible) {
      add(_buildCampusCardBalanceCard(context, compact: compactGrid));
    }
    if (_emailTileVisible) {
      add(_buildEmailOverviewCard(theme, compact: compactGrid));
    }
    if (_sportsAttendanceTileVisible) {
      add(_buildSportsOverviewCard(theme, compact: compactGrid));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    Widget separatedColumn(List<Widget> items) => Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: items[index]),
          if (index < items.length - 1)
            SizedBox(
              height: theme.layout.divider,
              child: ColoredBox(color: theme.color.border),
            ),
        ],
      ],
    );

    Widget compactColumn(List<Widget> items) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: theme.control.regular + theme.spacing.m,
            ),
            child: items[index],
          ),
          if (index < items.length - 1)
            SizedBox(
              height: theme.layout.divider,
              child: ColoredBox(color: theme.color.border),
            ),
        ],
      ],
    );

    final content = compactGrid
        ? Column(
            children: [
              for (var index = 0; index < children.length; index += 2) ...[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: children[index]),
                      if (index + 1 < children.length) ...[
                        SizedBox(
                          width: theme.layout.divider,
                          child: ColoredBox(color: theme.color.border),
                        ),
                        Expanded(child: children[index + 1]),
                      ] else
                        const Spacer(),
                    ],
                  ),
                ),
                if (index + 2 < children.length)
                  SizedBox(
                    height: theme.layout.divider,
                    child: ColoredBox(color: theme.color.border),
                  ),
              ],
            ],
          )
        : children.length <= 2
        ? compactColumn(children)
        : separatedColumn(children);

    return ClipRRect(
      key: const Key('home-overview-stack'),
      borderRadius: BorderRadius.circular(theme.radius.l),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.surface,
          border: Border.all(
            color: theme.color.border,
            width: theme.layout.divider,
          ),
          borderRadius: BorderRadius.circular(theme.radius.l),
        ),
        child: content,
      ),
    );
  }

  Widget _buildHomeUtilityDock(YhTheme theme, {required bool compact}) {
    if (!_studentReportTileVisible && !_quickLinksTileVisible) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[
      if (_studentReportTileVisible)
        _buildSecondClassroomCard(theme, compact: compact),
      if (_quickLinksTileVisible) _buildQuickLinksCard(theme, compact: compact),
    ];
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final cardHeight = compact
        ? theme.control.regular + theme.spacing.m
        : viewportWidth <= theme.breakpoint.expanded + theme.spacing.l * 4
        ? theme.control.regular + theme.spacing.xl
        : theme.control.regular + theme.spacing.xl + theme.spacing.s;
    final content = children.length == 1
        ? Center(child: children.first)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: compact
                    ? theme.responsive.homeUtilityPrimaryFlex
                    : MediaQuery.sizeOf(context).width <=
                          theme.breakpoint.settingsNavigationCompact
                    ? theme.responsive.homeUtilityMediumSummaryFlex
                    : theme.responsive.homeSecondaryFlex,
                child: Center(child: children.first),
              ),
              SizedBox(
                width: theme.layout.divider,
                child: ColoredBox(color: theme.color.border),
              ),
              Expanded(
                flex: compact
                    ? theme.responsive.homeUtilitySecondaryFlex
                    : MediaQuery.sizeOf(context).width <=
                          theme.breakpoint.settingsNavigationCompact
                    ? theme.responsive.homeUtilityMediumActionsFlex
                    : theme.responsive.homePrimaryFlex,
                child: Center(child: children.last),
              ),
            ],
          );
    return Padding(
      padding: EdgeInsets.only(
        top: compact ? theme.spacing.s : theme.spacing.m,
      ),
      child: SizedBox(
        height: cardHeight,
        child: YhCard(
          key: const Key('home-utility-dock'),
          semanticLabel: '课外进度与常用入口',
          padding: EdgeInsets.zero,
          radius: compact ? theme.radius.m : theme.radius.l,
          child: content,
        ),
      ),
    );
  }

  Widget _buildSecondClassroomCard(YhTheme theme, {required bool compact}) {
    final result = _studentReportResult;
    final hasCredentials =
        widget.studentReportResultOverride != null ||
        (_credentialsStatus.oaAccount.trim().isNotEmpty &&
            _credentialsStatus.hasOaPassword);
    if (!hasCredentials) {
      return _HomeOverviewCard(
        key: const Key('home-second-classroom-tile'),
        icon: YhIcons.academic,
        color: theme.color.serviceSecondClass,
        title: '第二课堂',
        detail: '需要先保存 OA 账号密码',
        value: '未配置',
        onTap: widget.onOpenSettings,
        embedded: true,
        compact: compact,
      );
    }
    if (result != null && !result.isSuccess) {
      return _HomeOverviewCard(
        key: const Key('home-second-classroom-tile'),
        icon: YhIcons.academic,
        color: theme.color.serviceSecondClass,
        title: '第二课堂暂不可用',
        detail: firstNonEmptyText(
          result.detail,
          result.message,
          fallback: '请检查 OA 登录与校园网络',
        ),
        value: '未更新',
        onTap: widget.onOpenSettings,
        embedded: true,
        compact: compact,
      );
    }
    final totals = result?.summary?.totals;
    final earned = totals?.totalEarnedCredit;
    final required = totals?.totalRequiredCredit;
    final percent = earned == null || required == null || required <= 0
        ? null
        : ((earned / required) * 100).round();
    final detail = earned == null || required == null
        ? '第二课堂学分尚未读取'
        : '已获 ${_compactNumber(earned)} / 必修 ${_compactNumber(required)} 学分';
    return _HomeOverviewCard(
      key: const Key('home-second-classroom-tile'),
      icon: YhIcons.academic,
      color: theme.color.serviceSecondClass,
      title: '第二课堂',
      detail: detail,
      value: percent == null ? '未读取' : '$percent%',
      embedded: true,
      compact: compact,
    );
  }

  Widget _buildQuickLinksCard(YhTheme theme, {required bool compact}) {
    final favorites = _quickLinkFavorites.take(3).toList(growable: false);
    final hideHeading =
        compact ||
        MediaQuery.sizeOf(context).width <= theme.breakpoint.expanded;
    final actions = <Widget>[
      for (var index = 0; index < favorites.length; index++)
        _HomeQuickAction(
          key: Key('home-quick-link-action-$index'),
          icon: _quickLinkIcon(favorites[index]),
          label: favorites[index].name,
          compact: compact,
          onPressed: () => unawaited(_openQuickLink(favorites[index])),
        ),
    ];
    return Semantics(
      key: const Key('home-quick-links-tile'),
      container: true,
      label: '常用入口',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : theme.spacing.s,
        ),
        child: favorites.isEmpty
            ? Text(
                compact ? '在“跳转”中收藏入口' : '还没有可用入口，可在“跳转”中收藏常用校园服务。',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hideHeading) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '常用入口',
                          style: theme.typography.caption.copyWith(
                            color: theme.color.brandInk,
                            fontWeight: theme.typography.semibold,
                          ),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text('从今天直接出发', style: theme.typography.h3),
                      ],
                    ),
                    SizedBox(width: theme.spacing.l),
                  ],
                  ...actions,
                ],
              ),
      ),
    );
  }

  IconData _quickLinkIcon(QuickLinkItemConfig item) {
    return switch (item.icon?.trim()) {
      'security' => YhIcons.lock,
      'library' => YhIcons.library,
      'education' => YhIcons.academic,
      'mail' => YhIcons.mail,
      'finance' => YhIcons.finance,
      'globe' => YhIcons.globe,
      _ when item.name.contains('认证') => YhIcons.lock,
      _ when item.name.contains('图书') => YhIcons.library,
      _ => YhIcons.globe,
    };
  }

  Future<void> _openQuickLink(QuickLinkItemConfig item) async {
    final uri = Uri.tryParse(item.url);
    if (uri == null || uri.host.isEmpty) return;
    final authenticationRequired = _quickLinkRequiresOaAuthentication(item);
    final authenticationReady =
        !authenticationRequired ||
        await AcademicCredentialsService.instance.readOaLoginSession() != null;
    if (!mounted) return;
    final confirmed = await Navigator.of(context).push<bool>(
      YhPageRoute<bool>(
        builder: (_) => ExternalLinkConfirmationPage(
          displayName: item.name,
          uri: uri,
          authenticationRequired: authenticationRequired,
          authenticationReady: authenticationReady,
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _quickLinkRequiresOaAuthentication(QuickLinkItemConfig item) {
    final host = Uri.tryParse(item.url)?.host.toLowerCase() ?? '';
    return host == 'oa.sspu.edu.cn' ||
        item.name.contains('（OA）') ||
        item.name.contains('统一身份认证');
  }

  Widget _buildProgramOverviewCard(YhTheme theme, {required bool compact}) {
    final completion = _academicOverviewResult?.snapshot?.programCompletion;
    final completed = completion?.completedCredits;
    final total = completion == null
        ? null
        : completion.completedCredits + completion.pendingCredits;
    final percent = completed == null || total == null || total <= 0
        ? null
        : ((completed / total) * 100).round();
    return _HomeOverviewCard(
      key: const Key('home-training-plan-card'),
      icon: YhIcons.academic,
      color: theme.color.serviceAcademic,
      title: '培养方案',
      detail: completed == null || total == null
          ? '培养进度尚未读取'
          : '已修 ${_compactNumber(completed)} / '
                '${_compactNumber(total)} 学分',
      value: percent == null ? '未读取' : '$percent%',
      compact: compact,
    );
  }

  Widget _buildEmailOverviewCard(YhTheme theme, {required bool compact}) {
    final count = _emailResult?.snapshot?.messages.length;
    return _HomeOverviewCard(
      key: const Key('home-email-tile'),
      icon: YhIcons.mail,
      color: theme.color.serviceMail,
      title: '学校邮箱',
      detail: count == null ? '邮箱缓存尚未读取' : '$count 封未读邮件',
      value: count?.toString() ?? '未读取',
      compact: compact,
    );
  }

  Widget _buildSportsOverviewCard(YhTheme theme, {required bool compact}) {
    final count = _sportsAttendanceResult?.summary?.totalCount;
    return _HomeOverviewCard(
      key: const Key('home-sports-attendance-tile'),
      icon: YhIcons.sports,
      color: theme.color.serviceSports,
      title: '体育考勤',
      detail: count == null ? '体育考勤尚未读取' : '本学期出勤正常',
      value: count == null ? '未读取' : '$count / $count',
      compact: compact,
    );
  }

  List<_HomeTimelineEntry> get _homeTimelineEntries {
    final now = widget.nowOverride ?? DateTime.now();
    final entries = <_HomeTimelineEntry>[
      if (_todayCoursesTileVisible)
        for (final course in _todayCourseEntries)
          _HomeTimelineEntry.course(
            course,
            now,
            timeOverride: widget.homeCourseTimeOverrides?[course.courseName],
          ),
      if (_messagesTileVisible)
        for (final message in _latestMessages.take(1))
          _HomeTimelineEntry.message(message, now),
    ]..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    return entries.take(3).toList(growable: false);
  }

  DateTime? get _latestHomeUpdate {
    if (widget.homeUpdatedAtOverride != null) {
      return widget.homeUpdatedAtOverride;
    }
    final values = <DateTime?>[
      _campusCardResult?.checkedAt,
      _courseTableResult?.checkedAt,
      _academicOverviewResult?.checkedAt,
      _sportsAttendanceResult?.checkedAt,
      _emailResult?.checkedAt,
      _studentReportResult?.checkedAt,
    ].whereType<DateTime>().toList(growable: false);
    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }

  Future<void> _refreshHome() async {
    final tasks = <Future<void>>[
      _loadCampusCard(),
      _loadDashboardCaches(),
      if (widget.messagesOverride == null) _loadLatestMessages(),
    ];
    await Future.wait<void>(tasks);
  }

  /// 根据时段生成首页问候的可阅读短语。
  ///
  /// :param now: 用于判断问候时段的当前时间。
  /// :returns: 可在紧凑端保持完整断句的问候短语。
  _HomeGreetingPhrases _greetingPhrases(DateTime now) {
    if (now.hour < 11) {
      return const _HomeGreetingPhrases('早上好，', '先看清今天。');
    }
    if (now.hour < 18) {
      return const _HomeGreetingPhrases('下午好，', '继续看清今天。');
    }
    return const _HomeGreetingPhrases('晚上好，', '收好今天的线索。');
  }

  String _weekdayLabel(int weekday) => switch (weekday) {
    DateTime.monday => '星期一',
    DateTime.tuesday => '星期二',
    DateTime.wednesday => '星期三',
    DateTime.thursday => '星期四',
    DateTime.friday => '星期五',
    DateTime.saturday => '星期六',
    DateTime.sunday => '星期日',
    _ => '',
  };

  String _formatHomeTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _compactNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}
