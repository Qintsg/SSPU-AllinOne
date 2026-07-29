/*
 * 独立课程表页面 — 展示本专科教务系统只读课表数据
 * @Project : SSPU-AllinOne
 * @File : course_schedule_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'dart:async';
import 'dart:math' as math;

import '../controllers/retained_refresh_controller.dart';
import '../design/qingyuan/qingyuan_ui.dart';
import '../models/academic_eams.dart';
import '../models/course_period.dart';
import '../services/academic_calendar_service.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../services/academic_term_service.dart';
import 'academic_calendar_page.dart';

/// 独立课程表页面。
class CourseSchedulePage extends StatefulWidget {
  /// 本专科教务只读服务，测试中可替换为 fake。
  final AcademicEamsClient? academicEamsService;

  /// 从教务中心摘要页带入的初始课表结果。
  final AcademicEamsQueryResult? initialResult;

  /// 测试专用：覆盖自动刷新开关。
  final bool? autoRefreshEnabledOverride;

  /// 测试专用：覆盖自动刷新间隔。
  final int? autoRefreshIntervalOverride;

  /// 测试专用：锁定当前时间，确保星期高亮和刷新判定可重现。
  final DateTime? nowOverride;

  /// 测试专用：锁定页头学期文案，避免视觉 fixture 依赖本机日期。
  final String? termLabelOverride;

  /// 校历客户端，测试中可替换为 fake。
  final AcademicCalendarClient? academicCalendarService;

  const CourseSchedulePage({
    super.key,
    this.academicEamsService,
    this.initialResult,
    this.autoRefreshEnabledOverride,
    this.autoRefreshIntervalOverride,
    this.nowOverride,
    this.termLabelOverride,
    this.academicCalendarService,
  });

  @override
  State<CourseSchedulePage> createState() => _CourseSchedulePageState();
}

class _CourseSchedulePageState extends State<CourseSchedulePage> {
  late final RetainedRefreshController<AcademicEamsQueryResult>
  _refreshController;
  Timer? _autoRefreshTimer;
  StreamSubscription<int>? _credentialChangeSubscription;
  late int _selectedMobileWeekday;
  int _resultGeneration = 0;

  DateTime get _now => widget.nowOverride ?? DateTime.now();
  AcademicEamsQueryResult? get _result => _refreshController.result;
  bool get _isLoading => _refreshController.isRefreshing;

  AcademicEamsClient get _academicEamsService {
    return widget.academicEamsService ?? AcademicEamsService.instance;
  }

  @override
  void initState() {
    super.initState();
    _selectedMobileWeekday = _now.weekday;
    _refreshController = RetainedRefreshController(
      initialResult: widget.initialResult,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.snapshot?.courseTable != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleRefreshChanged);
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _loadCacheAndAutoRefreshSettings();
  }

  @override
  void didUpdateWidget(covariant CourseSchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialResult, widget.initialResult)) {
      _resultGeneration++;
      _refreshController.updateExternalResult(widget.initialResult);
    }
  }

  void _handleRefreshChanged() {
    if (mounted) setState(() {});
  }

  void _clearAuthenticatedState() {
    _resultGeneration++;
    _refreshController.updateExternalResult(null);
  }

  Future<void> _loadAutoRefreshSettings() async {
    final service = widget.academicEamsService is AcademicEamsService
        ? widget.academicEamsService as AcademicEamsService
        : AcademicEamsService.instance;
    final enabled =
        widget.autoRefreshEnabledOverride ??
        await service.isAutoRefreshEnabled();
    final interval =
        widget.autoRefreshIntervalOverride ??
        await service.getAutoRefreshIntervalMinutes();
    if (!mounted) return;
    _restartAutoRefreshTimer(enabled, interval);
    if (enabled && _shouldAutoRefresh(_result?.checkedAt, interval)) {
      unawaited(_loadCourseTable(silent: true));
    }
  }

  void _restartAutoRefreshTimer(bool enabled, int intervalMinutes) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _autoRefreshTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      if (_shouldAutoRefresh(_result?.checkedAt, intervalMinutes)) {
        unawaited(_loadCourseTable(silent: true));
      }
    });
  }

  Future<void> _loadCacheAndAutoRefreshSettings() async {
    final generation = _resultGeneration;
    final cachedResult = await _academicEamsService
        .readLatestCachedCourseTable();
    if (mounted &&
        generation == _resultGeneration &&
        cachedResult != null &&
        !_hasUsableCourseTable(_result)) {
      _refreshController.updateExternalResult(cachedResult);
    }
    await _loadAutoRefreshSettings();
  }

  bool _hasUsableCourseTable(AcademicEamsQueryResult? result) {
    final entries = result?.snapshot?.courseTable?.entries;
    return result?.isSuccess == true && entries != null && entries.isNotEmpty;
  }

  Future<void> _loadCourseTable({bool silent = false}) async {
    await _refreshController.refresh(
      () => _academicEamsService.fetchCourseTable(requireCampusNetwork: silent),
    );
  }

  bool _shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return _now.difference(fetchedAt) >= Duration(minutes: intervalMinutes);
  }

  void _openAcademicCalendar() {
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) =>
            AcademicCalendarPage(service: widget.academicCalendarService),
      ),
    );
  }

  @override
  void dispose() {
    _credentialChangeSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _refreshController
      ..removeListener(_handleRefreshChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final canPop = Navigator.of(context).canPop();
    final courseTable = _result?.snapshot?.courseTable;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final fluidPaddingProgress =
        ((viewportWidth - theme.breakpoint.medium) /
                (theme.breakpoint.expanded - theme.breakpoint.medium))
            .clamp(0.0, 1.0);
    final fluidHorizontalPadding =
        theme.spacing.xl +
        (theme.spacing.xl2 - theme.spacing.xl) * fluidPaddingProgress;
    final horizontalPadding = viewportWidth < theme.breakpoint.medium
        ? theme.spacing.m
        : fluidHorizontalPadding;
    final verticalPadding = viewportWidth < theme.breakpoint.medium
        ? theme.spacing.xl
        : fluidHorizontalPadding + theme.spacing.s;
    final contentGap = viewportWidth < theme.breakpoint.medium
        ? theme.spacing.m
        : (_result?.isSuccess == true && courseTable != null
              ? theme.spacing.m
              : theme.spacing.l);

    return YhPageScaffold(
      appBar: canPop
          ? YhAppBar(
              title: '课程表',
              leading: YhButton(
                label: '返回',
                leadingIcon: YhIcons.back,
                variant: YhButtonVariant.text,
                onTap: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SingleChildScrollView(
        primary: true,
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.pageContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeader(courseTable, viewportWidth),
                  SizedBox(height: contentGap),
                  _buildContent(courseTable),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(
    AcademicCourseTableSnapshot? courseTable,
    double viewportWidth,
  ) {
    final theme = context.yhTheme;
    final normalizedTerm = _resolvedTermName(courseTable);
    final compact = viewportWidth < theme.breakpoint.medium;
    final actionMinWidth = compact
        ? (viewportWidth - theme.spacing.m * 2 - theme.spacing.s) / 2
        : theme.control.minimumTarget * 2 + theme.spacing.m;
    final actions = <Widget>[
      YhButton(
        key: const Key('open-academic-calendar'),
        label: '查看校历',
        minWidth: actionMinWidth,
        variant: YhButtonVariant.secondary,
        onTap: _openAcademicCalendar,
      ),
      YhButton(
        key: const Key('course-schedule-refresh'),
        label: _isLoading ? '正在刷新…' : '刷新课表',
        minWidth: !compact && _isLoading
            ? actionMinWidth + theme.spacing.s
            : actionMinWidth,
        disabled: _isLoading,
        onTap: _loadCourseTable,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    normalizedTerm,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.serviceSchedule,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Semantics(
                    header: true,
                    child: Text('课程表', style: theme.typography.h1),
                  ),
                  SizedBox(height: theme.spacing.s),
                  Text(
                    '周视图在桌面保持七天空间关系，窄屏切换为按天列表；'
                    '课程颜色只表达课表业务域。',
                    style:
                        (compact
                                ? theme.typography.small
                                : theme.typography.body)
                            .copyWith(color: theme.color.muted),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              SizedBox(width: theme.spacing.l),
              Transform.translate(
                offset: Offset(0, -theme.spacing.s),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    actions.first,
                    SizedBox(width: theme.spacing.s),
                    actions.last,
                  ],
                ),
              ),
            ],
          ],
        ),
        if (compact) ...[
          SizedBox(height: theme.spacing.l),
          Row(
            children: [
              Expanded(child: actions.first),
              SizedBox(width: theme.spacing.s),
              Expanded(child: actions.last),
            ],
          ),
        ],
        if (_result?.isSuccess == true && courseTable != null) ...[
          SizedBox(height: compact ? theme.spacing.m : theme.spacing.l),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              YhStatusPill(
                label: '${courseTable.entries.length} 门课程',
                kind: YhStatusKind.info,
              ),
              YhStatusPill(
                label:
                    '${_result!.checkedAt.hour.toString().padLeft(2, '0')}:'
                    '${_result!.checkedAt.minute.toString().padLeft(2, '0')} 更新',
                kind: YhStatusKind.info,
              ),
              if (_result!.snapshot!.warnings.isNotEmpty)
                const YhStatusPill(label: '本地缓存', kind: YhStatusKind.warning),
            ],
          ),
        ],
      ],
    );
  }

  String _resolvedTermName(AcademicCourseTableSnapshot? courseTable) {
    final termName = widget.termLabelOverride?.trim().isNotEmpty == true
        ? widget.termLabelOverride!.trim()
        : courseTable?.termName?.trim();
    if (termName != null && termName.isNotEmpty) {
      return termName.replaceFirst('-', '–');
    }
    final checkedAt = _result?.checkedAt;
    if (checkedAt != null) {
      final definition = AcademicCalendarResolver().definitionForContext(
        checkedAt,
      );
      if (definition != null) return '${definition.choice.label}（按校历推断）';
    }
    return '课程安排';
  }

  Widget _buildContent(AcademicCourseTableSnapshot? courseTable) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    if (_isLoading && _result == null) {
      return const _ScheduleStatePanel(
        loading: true,
        statusLabel: '读取中',
        title: '正在读取当前学期课表',
        message: '正在从教务课表恢复数据；页面、校历入口和返回路径保持可用。',
        contextLabel: '只读访问 · 当前学期',
      );
    }
    if (_result == null) {
      return _ScheduleStatePanel(
        symbol: '→',
        statusLabel: '尚未开始',
        title: '准备读取课程表',
        message: '首次读取只访问当前 OA 登录态下的课表；由你决定何时开始。',
        contextLabel: '只读访问 · 当前学期',
        primaryActionLabel: '开始读取',
        onPrimaryAction: _loadCourseTable,
        onCalendar: _openAcademicCalendar,
      );
    }
    if (!_result!.isSuccess || courseTable == null) {
      return _ScheduleStatePanel(
        symbol: '!',
        statusLabel: '需要处理',
        title: _result!.message,
        message: _result!.detail,
        contextLabel: '已有缓存不会被清空',
        primaryActionLabel: '检查后重试',
        onPrimaryAction: _loadCourseTable,
        onCalendar: _openAcademicCalendar,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading) ...[
          if (compact) SizedBox(height: theme.spacing.xs),
          const YhBanner(text: '正在刷新课表；当前课程、星期选择和校历入口保持可用，完成前已锁定重复刷新。'),
          SizedBox(height: theme.spacing.m),
        ],
        if (_refreshController.retainedFailure case final failure?) ...[
          YhBanner(text: failure, kind: YhBannerKind.danger),
          SizedBox(height: theme.spacing.m),
        ],
        if (courseTable.entries.isNotEmpty &&
            _result!.snapshot!.warnings.isNotEmpty) ...[
          if (compact) SizedBox(height: theme.spacing.xs),
          const YhBanner(
            text: '正在显示昨日缓存；刷新失败不会删除当前周视图，可在原位置重试。',
            kind: YhBannerKind.warn,
          ),
          SizedBox(height: theme.spacing.m),
        ],
        if (courseTable.entries.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: theme.spacing.s - theme.spacing.xs / 2,
            ),
            child: _ScheduleStatePanel(
              symbol: '○',
              statusLabel: '当前范围',
              title: '本学期暂无课程',
              message: '当前学期没有可展示的课程；刚完成选课时可稍后刷新，或查看校历确认学期。',
              contextLabel:
                  '0 门课程 · ${_formatCheckedTime(_result!.checkedAt)} 更新',
              primaryActionLabel: '重新读取',
              onPrimaryAction: _loadCourseTable,
              onCalendar: _openAcademicCalendar,
            ),
          )
        else
          _CourseScheduleAdaptiveView(
            courseTable: courseTable,
            currentWeekday: _now.weekday,
            selectedMobileWeekday: _selectedMobileWeekday,
            onSelectedMobileWeekdayChanged: (weekday) {
              setState(() => _selectedMobileWeekday = weekday);
            },
          ),
      ],
    );
  }

  String _formatCheckedTime(DateTime checkedAt) {
    return '${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}

class _ScheduleStatePanel extends StatelessWidget {
  const _ScheduleStatePanel({
    this.loading = false,
    this.symbol,
    required this.statusLabel,
    required this.title,
    required this.message,
    required this.contextLabel,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onCalendar,
  });

  final bool loading;
  final String? symbol;
  final String statusLabel;
  final String title;
  final String message;
  final String contextLabel;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final effectiveAccent = theme.color.serviceSchedule;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compact = viewportWidth < theme.breakpoint.medium;
    final compactActionMinWidth =
        (viewportWidth -
            theme.spacing.m * 2 -
            theme.spacing.l * 2 -
            theme.spacing.s -
            theme.spacing.xs) /
        2;
    return YhCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: compact
              ? theme.control.regular * 6 + theme.spacing.xl
              : theme.control.regular * 8,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                Semantics(
                  label: title,
                  value: '加载中',
                  child: SizedBox.square(
                    dimension: theme.control.minimumTarget,
                    child: CustomPaint(
                      painter: _ScheduleSpinnerPainter(
                        trackColor: theme.color.border,
                        activeColor: effectiveAccent,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: theme.layout.bottomNavigationHeight,
                  height: theme.layout.bottomNavigationHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(theme.radius.l),
                  ),
                  child: Text(
                    symbol ?? '→',
                    style: theme.typography.display.copyWith(
                      color: effectiveAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(height: theme.spacing.l),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.color.brandTint,
                  borderRadius: BorderRadius.circular(theme.radius.full),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.s,
                    vertical: theme.spacing.xs,
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.typography.caption.copyWith(
                      color: effectiveAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.typography.h2,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.control.regular * 11,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Text(
                contextLabel,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
              if (!loading &&
                  primaryActionLabel != null &&
                  onPrimaryAction != null &&
                  onCalendar != null) ...[
                SizedBox(height: theme.spacing.l),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: theme.spacing.s,
                  runSpacing: theme.spacing.s,
                  children: [
                    YhButton(
                      key: const Key('schedule-state-calendar'),
                      label: '查看校历',
                      minWidth: compact ? compactActionMinWidth : null,
                      variant: YhButtonVariant.secondary,
                      onTap: onCalendar,
                    ),
                    YhButton(
                      key: const Key('schedule-state-primary'),
                      label: primaryActionLabel!,
                      minWidth: compact ? compactActionMinWidth : null,
                      onTap: onPrimaryAction,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleSpinnerPainter extends CustomPainter {
  const _ScheduleSpinnerPainter({
    required this.trackColor,
    required this.activeColor,
  });

  final Color trackColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide / 12;
    final bounds = Offset.zero & size;
    final arcBounds = bounds.deflate(strokeWidth / 2);
    canvas.drawCircle(
      bounds.center,
      (size.shortestSide - strokeWidth) / 2,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      arcBounds,
      -math.pi / 2,
      math.pi * 0.72,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _ScheduleSpinnerPainter oldDelegate) {
    return trackColor != oldDelegate.trackColor ||
        activeColor != oldDelegate.activeColor;
  }
}

class _CourseScheduleAdaptiveView extends StatelessWidget {
  const _CourseScheduleAdaptiveView({
    required this.courseTable,
    required this.currentWeekday,
    required this.selectedMobileWeekday,
    required this.onSelectedMobileWeekdayChanged,
  });

  final AcademicCourseTableSnapshot courseTable;
  final int currentWeekday;
  final int selectedMobileWeekday;
  final ValueChanged<int> onSelectedMobileWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YhTabs<int>(
          tabs: [
            for (var weekday = 1; weekday <= 7; weekday++)
              YhTab(
                value: weekday,
                label: weekday == currentWeekday
                    ? '${_weekdayLabel(weekday)} · 今天'
                    : _weekdayLabel(weekday),
              ),
          ],
          value: selectedMobileWeekday,
          onChanged: onSelectedMobileWeekdayChanged,
        ),
        SizedBox(height: theme.spacing.m - theme.spacing.xs),
        if (compact)
          _CourseDayScheduleView(
            entries: _entriesForWeekday(
              courseTable.entries,
              selectedMobileWeekday,
            ),
            selectedWeekday: selectedMobileWeekday,
          )
        else
          _CourseWeekGridView(
            entries: courseTable.entries,
            currentWeekday: currentWeekday,
          ),
      ],
    );
  }
}

class _CourseWeekGridView extends StatelessWidget {
  const _CourseWeekGridView({
    required this.entries,
    required this.currentWeekday,
  });

  final List<AcademicCourseTableEntry> entries;
  final int currentWeekday;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    const periodTable = CoursePeriodTable.standard;
    final periodColumnWidth =
        theme.control.regular + theme.spacing.l + theme.spacing.xs / 2;
    final cellMinHeight =
        theme.control.regular + theme.spacing.xl + theme.spacing.xs / 2;
    var maxUnit = 1;
    for (final entry in entries) {
      if (entry.endUnit > maxUnit) maxUnit = entry.endUnit;
    }
    final groupCount = (maxUnit + 1) ~/ 2;

    return YhCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _CourseGridHeader(
            currentWeekday: currentWeekday,
            periodColumnWidth: periodColumnWidth,
          ),
          for (var group = 0; group < groupCount; group++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CoursePeriodCell(
                    startUnit: group * 2 + 1,
                    endUnit: group * 2 + 1 == periodTable.periods.length
                        ? group * 2 + 1
                        : group * 2 + 2,
                    width: periodColumnWidth,
                    minHeight: cellMinHeight,
                  ),
                  for (var weekday = 1; weekday <= 7; weekday++)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: weekday == currentWeekday
                              ? theme.color.brandTint
                              : theme.color.surface,
                          border: BorderDirectional(
                            start: BorderSide(color: theme.color.border),
                            top: BorderSide(color: theme.color.border),
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: cellMinHeight),
                          child: Padding(
                            padding: EdgeInsets.all(theme.spacing.s),
                            child: _CourseGridCell(
                              entries: _entriesStartingBetween(
                                entries,
                                weekday,
                                group * 2 + 1,
                                group * 2 + 2,
                              ),
                            ),
                          ),
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

class _CourseGridHeader extends StatelessWidget {
  const _CourseGridHeader({
    required this.currentWeekday,
    required this.periodColumnWidth,
  });

  final int currentWeekday;
  final double periodColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return SizedBox(
      height: theme.control.regular,
      child: Row(
        children: [
          SizedBox(
            width: periodColumnWidth,
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.s),
              child: Text(
                '节次',
                style: theme.typography.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (var weekday = 1; weekday <= 7; weekday++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: weekday == currentWeekday
                      ? theme.color.brandTint
                      : theme.color.sunken,
                  border: BorderDirectional(
                    start: BorderSide(color: theme.color.border),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(theme.spacing.s),
                  child: Text(
                    _weekdayLabel(weekday),
                    textAlign: TextAlign.center,
                    style: theme.typography.body.copyWith(
                      color: weekday == currentWeekday
                          ? theme.color.brandInk
                          : theme.color.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoursePeriodCell extends StatelessWidget {
  const _CoursePeriodCell({
    required this.startUnit,
    required this.endUnit,
    required this.width,
    required this.minHeight,
  });

  final int startUnit;
  final int endUnit;
  final double width;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final startPeriod = CoursePeriodTable.standard.periodOf(startUnit)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        border: Border(top: BorderSide(color: theme.color.border)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  startUnit == endUnit ? '$startUnit' : '$startUnit–$endUnit',
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  startPeriod.timeRange.split('-').first,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseGridCell extends StatelessWidget {
  const _CourseGridCell({required this.entries});

  final List<AcademicCourseTableEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = context.yhTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(child: _CourseBlock(entry: entries[i])),
          if (i < entries.length - 1) SizedBox(width: theme.spacing.xs),
        ],
      ],
    );
  }
}

class _CourseDayScheduleView extends StatelessWidget {
  const _CourseDayScheduleView({
    required this.entries,
    required this.selectedWeekday,
  });

  final List<AcademicCourseTableEntry> entries;
  final int selectedWeekday;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (entries.isEmpty) {
      return YhCard(
        child: YhEmptyState(
          icon: YhIcons.calendar,
          title: '${_weekdayLabel(selectedWeekday)}暂无课程',
          message: '可切换其它日期查看本周安排。',
        ),
      );
    }
    return Column(
      children: [
        for (final entry in entries) ...[
          YhCard(
            padding: EdgeInsets.all(theme.spacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: theme.control.regular * 2,
                  child: Text(
                    '${CoursePeriodTable.standard.rangeText(entry.startUnit, entry.endUnit).split('-').first}'
                    ' · ${entry.startUnit}–${entry.endUnit} 节',
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                    ),
                  ),
                ),
                SizedBox(width: theme.spacing.m),
                Expanded(child: _CourseBlock(entry: entry)),
              ],
            ),
          ),
          if (entry != entries.last) SizedBox(height: theme.spacing.s),
        ],
      ],
    );
  }
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.entry});

  final AcademicCourseTableEntry entry;

  @override
  Widget build(BuildContext context) {
    final detail = entry.location?.trim().isNotEmpty == true
        ? entry.location!.trim()
        : entry.teacher?.trim().isNotEmpty == true
        ? entry.teacher!.trim()
        : entry.rawText;
    return SizedBox(
      width: double.infinity,
      child: YhCourseBlock(name: entry.courseName, time: detail),
    );
  }
}

List<AcademicCourseTableEntry> _entriesForWeekday(
  List<AcademicCourseTableEntry> entries,
  int weekday,
) {
  final filtered = entries.where((entry) => entry.weekday == weekday).toList();
  filtered.sort((a, b) => a.startUnit.compareTo(b.startUnit));
  return filtered;
}

List<AcademicCourseTableEntry> _entriesStartingBetween(
  List<AcademicCourseTableEntry> entries,
  int weekday,
  int startUnit,
  int endUnit,
) {
  final filtered = entries
      .where(
        (entry) =>
            entry.weekday == weekday &&
            entry.startUnit >= startUnit &&
            entry.startUnit <= endUnit,
      )
      .toList();
  filtered.sort((a, b) => a.courseName.compareTo(b.courseName));
  return filtered;
}

String _weekdayLabel(int weekday) {
  return switch (weekday) {
    1 => '周一',
    2 => '周二',
    3 => '周三',
    4 => '周四',
    5 => '周五',
    6 => '周六',
    7 => '周日',
    _ => '未知',
  };
}
