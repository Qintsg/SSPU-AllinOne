/*
 * 清源首页视图 — 今日学程时间轨与校园服务概览
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_view.dart
 */

part of 'home_page.dart';

extension _HomeDashboardView on _HomePageState {
  Widget _buildQingyuanHomePage(BuildContext context) {
    final theme = context.yhTheme;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final mobile = constraints.maxWidth < theme.breakpoint.compact;
          final pagePadding = mobile
              ? theme.spacing.m
              : viewportWidth < theme.breakpoint.expanded
              ? theme.spacing.xl
              : theme.spacing.xl2;
          return SingleChildScrollView(
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.layout.pageContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    mobile ? theme.spacing.l : theme.spacing.xl,
                    pagePadding,
                    theme.spacing.xl2 + theme.spacing.m,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHomeHeading(theme, compact: mobile),
                      _buildHomeStatusRow(theme),
                      _buildHomePrimaryLayout(theme, constraints.maxWidth),
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

  Widget _buildHomeHeading(YhTheme theme, {required bool compact}) {
    final now = widget.nowOverride ?? DateTime.now();
    final heading = Column(
      key: const Key('home-page-heading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${now.month} 月 ${now.day} 日 · ${_weekdayLabel(now.weekday)}',
          style: theme.typography.caption.copyWith(
            color: theme.color.brandInk,
            fontWeight: theme.typography.semibold,
            letterSpacing: theme.layout.divider,
          ),
        ),
        SizedBox(height: theme.spacing.s),
        Semantics(
          header: true,
          child: Text(_greeting(now), style: theme.typography.h1),
        ),
        SizedBox(height: theme.spacing.s),
        Text(
          '课程、待办和校园服务状态集中在同一条时间语境里，数据均保留在本机。',
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
      ],
    );
    final refreshAction = RefreshFeedbackAction(
      key: const Key('home-campus-card-refresh'),
      tooltip: '刷新首页',
      semanticLabel: '刷新首页',
      isLoading: _campusCardRefreshController.isLoading,
      feedback: _campusCardRefreshController.feedback,
      onPressed: _refreshHome,
      minTouchSize: theme.control.minimumTarget,
      maxFeedbackWidth: theme.layout.inlineControlWidth,
    );
    final content = compact
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, theme.spacing.s),
                  child: heading,
                ),
              ),
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
        bottom: compact
            ? theme.spacing.l
            : theme.spacing.l + theme.layout.divider * 3,
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

  Widget _buildHomePrimaryLayout(YhTheme theme, double width) {
    final stacked =
        width <=
        theme.breakpoint.medium +
            theme.layout.inlineControlWidth -
            theme.spacing.xl2;
    final timeline = _buildTimelinePanel(theme);
    final overview = _buildHomeOverviewStack(theme);
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          timeline,
          SizedBox(height: theme.spacing.m),
          overview,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: theme.responsive.homePrimaryFlex, child: timeline),
        SizedBox(width: theme.spacing.m),
        Expanded(flex: theme.responsive.homeSecondaryFlex, child: overview),
      ],
    );
  }

  Widget _buildTimelinePanel(YhTheme theme) {
    final entries = _homeTimelineEntries;
    final nextIndex = entries.indexWhere((entry) => entry.isUpcoming);
    final next = nextIndex < 0 ? null : entries[nextIndex];
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final stacked =
        viewportWidth <=
        theme.breakpoint.medium +
            theme.layout.inlineControlWidth -
            theme.spacing.xl2;
    final minimumHeight = stacked
        ? 0.0
        : theme.layout.formContentWidth -
              theme.spacing.xl2 -
              theme.layout.divider * 2;
    final compact = viewportWidth < theme.breakpoint.compact;
    final fluidPanelPadding =
        viewportWidth * theme.responsive.panelPaddingViewportPercent / 100;
    final panelPadding = compact
        ? theme.spacing.l
        : fluidPanelPadding
              .clamp(theme.spacing.l, theme.spacing.xl2)
              .toDouble();
    final fluidHeroSize =
        viewportWidth * theme.responsive.heroViewportPercent / 100;
    final heroStyle = compact
        ? theme.typography.h1.copyWith(
            height: theme.typography.hero.height,
            fontWeight: theme.typography.hero.fontWeight,
          )
        : theme.typography.hero.copyWith(
            fontSize: fluidHeroSize
                .clamp(
                  theme.typography.h1.fontSize!,
                  theme.typography.hero.fontSize!,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minimumHeight),
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
                          height: compact ? theme.spacing.l : theme.spacing.xl,
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
                                    color: theme.color.brandTint,
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
                        SizedBox(height: theme.spacing.xl),
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
                            ),
                        SizedBox(
                          height: compact
                              ? theme.layout.divider
                              : theme.focus.ringWidth,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildHomeOverviewStack(YhTheme theme) {
    final children = <Widget>[];
    void add(Widget child) {
      if (children.isNotEmpty) children.add(SizedBox(height: theme.spacing.m));
      children.add(child);
    }

    if (_studentProfileCardVisible) add(_buildProgramOverviewCard(theme));
    if (_campusCardCardVisible) add(_buildCampusCardBalanceCard(context));
    if (_emailTileVisible) add(_buildEmailOverviewCard(theme));
    if (_sportsAttendanceTileVisible) add(_buildSportsOverviewCard(theme));
    return Column(
      key: const Key('home-overview-stack'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildProgramOverviewCard(YhTheme theme) {
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
    );
  }

  Widget _buildEmailOverviewCard(YhTheme theme) {
    final count = _emailResult?.snapshot?.messages.length;
    return _HomeOverviewCard(
      key: const Key('home-email-tile'),
      icon: YhIcons.mail,
      color: theme.color.serviceMail,
      title: '学校邮箱',
      detail: count == null ? '邮箱缓存尚未读取' : '$count 封未读邮件',
      value: count?.toString() ?? '未读取',
    );
  }

  Widget _buildSportsOverviewCard(YhTheme theme) {
    final count = _sportsAttendanceResult?.summary?.totalCount;
    return _HomeOverviewCard(
      key: const Key('home-sports-attendance-tile'),
      icon: YhIcons.sports,
      color: theme.color.serviceSports,
      title: '体育考勤',
      detail: count == null ? '体育考勤尚未读取' : '本学期出勤正常',
      value: count == null ? '未读取' : '$count / $count',
    );
  }

  List<_HomeTimelineEntry> get _homeTimelineEntries {
    final now = widget.nowOverride ?? DateTime.now();
    final entries = <_HomeTimelineEntry>[
      if (_todayCoursesTileVisible)
        for (final course in _todayCourseEntries)
          _HomeTimelineEntry.course(course, now),
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

  String _greeting(DateTime now) {
    if (now.hour < 11) return '早上好，先看清今天。';
    if (now.hour < 18) return '下午好，继续看清今天。';
    return '晚上好，收好今天的线索。';
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

class _HomeOverviewCard extends StatelessWidget {
  const _HomeOverviewCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      semanticLabel: '$title，$detail，$value',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.control.regular),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  color.withValues(alpha: theme.opacity.domainTint),
                  theme.color.surface,
                ),
                borderRadius: BorderRadius.circular(theme.radius.input),
              ),
              child: SizedBox.square(
                dimension: theme.control.regular - theme.spacing.xs,
                child: Icon(icon, size: theme.spacing.l, color: color),
              ),
            ),
            SizedBox(width: theme.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.body.copyWith(
                      fontWeight: theme.typography.semibold,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.spacing.m),
            Text(
              value,
              style: theme.typography.body.copyWith(
                fontFamily: YhTypographyTokens.fontFamilyMono,
                fontWeight: theme.typography.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTimelineEntry {
  const _HomeTimelineEntry({
    required this.time,
    required this.title,
    required this.detail,
    required this.minuteOfDay,
    required this.minutesUntil,
  });

  factory _HomeTimelineEntry.course(
    AcademicCourseTableEntry course,
    DateTime now,
  ) {
    final period = CoursePeriodTable.standard.periodOf(course.startUnit);
    final time = period?.startTime ?? course.timeText;
    final minuteOfDay = _parseMinuteOfDay(time);
    return _HomeTimelineEntry(
      time: time,
      title: course.courseName,
      detail: course.location?.trim().isNotEmpty == true
          ? course.location!.trim()
          : course.teacher?.trim().isNotEmpty == true
          ? course.teacher!.trim()
          : course.timeText,
      minuteOfDay: minuteOfDay,
      minutesUntil: minuteOfDay - now.hour * 60 - now.minute,
    );
  }

  factory _HomeTimelineEntry.message(MessageItem message, DateTime now) {
    final fallback = DateTime(now.year, now.month, now.day, 16);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      message.timestamp ?? fallback.millisecondsSinceEpoch,
    );
    final minuteOfDay = dateTime.hour * 60 + dateTime.minute;
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    return _HomeTimelineEntry(
      time: time,
      title: message.title,
      detail: message.title.contains('作业') ? '在教务系统提交' : '在信息中心查看',
      minuteOfDay: minuteOfDay,
      minutesUntil: minuteOfDay - now.hour * 60 - now.minute,
    );
  }

  final String time;
  final String title;
  final String detail;
  final int minuteOfDay;
  final int minutesUntil;

  bool get isUpcoming => minutesUntil >= 0;

  static int _parseMinuteOfDay(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return 0;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }
}

class _HomeTimelineBackdropPainter extends CustomPainter {
  const _HomeTimelineBackdropPainter(this.theme);

  final YhTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width + theme.spacing.xl2,
      size.height + theme.spacing.xl2,
    );
    final radius = theme.layout.statusProgressWidth / 2;
    final midSpread = theme.spacing.xl + theme.spacing.xs;
    final outerSpread = theme.spacing.xl2 + theme.spacing.l;
    canvas.drawCircle(
      center,
      radius + outerSpread,
      Paint()
        ..color = theme.color.onStructural.withValues(
          alpha: theme.opacity.timelineOrbitOuter,
        ),
    );
    canvas.drawCircle(
      center,
      radius + midSpread,
      Paint()
        ..color = theme.color.onStructural.withValues(
          alpha: theme.opacity.timelineOrbitMid,
        ),
    );
    canvas.drawCircle(center, radius, Paint()..color = theme.color.structural);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.layout.divider
        ..color = theme.color.onStructural.withValues(
          alpha: theme.opacity.timelineOrbit,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeTimelineBackdropPainter oldDelegate) {
    return theme != oldDelegate.theme;
  }
}

class _HomeTimelineRow extends StatelessWidget {
  const _HomeTimelineRow({
    required this.entry,
    required this.current,
    required this.last,
  });

  final _HomeTimelineEntry entry;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final trackWidth = theme.spacing.m + theme.layout.divider * 2;
    final timeWidth =
        theme.control.regular + theme.spacing.s + theme.spacing.xs;
    final rowHeight =
        theme.control.regular + theme.spacing.xl + theme.layout.divider * 2;
    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeWidth,
            child: Text(
              entry.time,
              style: theme.typography.small.copyWith(
                color: theme.color.onStructural,
                fontFamily: YhTypographyTokens.fontFamilyMono,
                fontWeight: theme.typography.semibold,
              ),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          SizedBox(
            width: trackWidth,
            height: rowHeight,
            child: CustomPaint(
              painter: _HomeTimelineTrackPainter(
                current: current,
                last: last,
                theme: theme,
              ),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.copyWith(
                    color: theme.color.onStructural,
                    fontWeight: theme.typography.semibold,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  current ? '${entry.detail} · 当前' : entry.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.onStructural.withValues(
                      alpha: theme.opacity.timelineDetail,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTimelineTrackPainter extends CustomPainter {
  const _HomeTimelineTrackPainter({
    required this.current,
    required this.last,
    required this.theme,
  });

  final bool current;
  final bool last;
  final YhTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, theme.spacing.s);
    if (!last) {
      canvas.drawLine(
        Offset(center.dx, center.dy + theme.spacing.xs),
        Offset(center.dx, size.height),
        Paint()
          ..color = theme.color.onStructural.withValues(
            alpha: theme.opacity.timelineTrack,
          )
          ..strokeWidth = theme.layout.divider,
      );
    }
    if (current) {
      canvas.drawCircle(
        center,
        theme.spacing.s,
        Paint()
          ..color = theme.color.brandTint.withValues(
            alpha: theme.opacity.timelineCurrentRing,
          ),
      );
    }
    final dotRadius = theme.spacing.s - theme.spacing.xs / 2;
    canvas.drawCircle(
      center,
      dotRadius,
      Paint()
        ..color = current
            ? theme.color.brandTint
            : theme.color.onStructural.withValues(
                alpha: theme.opacity.timelineDot,
              ),
    );
    canvas.drawCircle(
      center,
      dotRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.focus.ringWidth
        ..color = theme.color.structural,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeTimelineTrackPainter oldDelegate) {
    return current != oldDelegate.current ||
        last != oldDelegate.last ||
        theme != oldDelegate.theme;
  }
}
