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
import '../services/data_auto_refresh_preferences.dart';
import 'academic_calendar_page.dart';

part 'course_schedule_state_panel.dart';
part 'course_schedule_views.dart';

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
  StreamSubscription<int>? _dataAutoRefreshSubscription;
  bool _autoRefreshEnabled = false;
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
    _dataAutoRefreshSubscription = DataAutoRefreshPreferences.instance.changes
        .listen(_handleDataAutoRefreshIntervalChanged);
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
    _autoRefreshEnabled = enabled;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (!enabled || intervalMinutes <= 0) return;
    _autoRefreshTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      if (_shouldAutoRefresh(_result?.checkedAt, intervalMinutes)) {
        unawaited(_loadCourseTable(silent: true));
      }
    });
  }

  /// 共享刷新时长变化后重启课表定时器。
  ///
  /// :param minutes: 新的共享刷新间隔分钟数。
  /// :returns: 无返回值。
  void _handleDataAutoRefreshIntervalChanged(int minutes) {
    if (widget.autoRefreshIntervalOverride != null) return;
    _restartAutoRefreshTimer(_autoRefreshEnabled, minutes);
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
    _dataAutoRefreshSubscription?.cancel();
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
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final fillViewport =
        !(viewportWidth < theme.breakpoint.medium) &&
        viewportHeight >= theme.control.regular * 16 + theme.spacing.s;
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
      body: fillViewport
          ? Align(
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
                      Expanded(
                        child: _buildContent(courseTable, fillHeight: true),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
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
    final refreshAction = compact
        ? YhButton(
            key: const Key('course-schedule-refresh'),
            label: _isLoading ? '正在刷新…' : '刷新课表',
            minWidth: actionMinWidth,
            disabled: _isLoading,
            onTap: _loadCourseTable,
          )
        : YhIconButton(
            key: const Key('course-schedule-refresh'),
            icon: _isLoading ? YhIcons.sync : YhIcons.refresh,
            semanticLabel: _isLoading ? '正在刷新课程表' : '刷新课程表',
            disabled: _isLoading,
            onTap: _loadCourseTable,
          );
    final actions = <Widget>[
      YhButton(
        key: const Key('open-academic-calendar'),
        label: '查看校历',
        minWidth: actionMinWidth,
        variant: YhButtonVariant.secondary,
        onTap: _openAcademicCalendar,
      ),
      refreshAction,
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

  Widget _buildContent(
    AcademicCourseTableSnapshot? courseTable, {
    bool fillHeight = false,
  }) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    Widget statePanel(_ScheduleStatePanel panel) =>
        fillHeight ? Center(child: panel) : panel;
    if (_isLoading && _result == null) {
      return statePanel(
        const _ScheduleStatePanel(
          loading: true,
          statusLabel: '读取中',
          title: '正在读取当前学期课表',
          message: '正在从教务课表恢复数据；页面、校历入口和返回路径保持可用。',
          contextLabel: '只读访问 · 当前学期',
        ),
      );
    }
    if (_result == null) {
      return statePanel(
        _ScheduleStatePanel(
          symbol: '→',
          statusLabel: '尚未开始',
          title: '准备读取课程表',
          message: '首次读取只访问当前 OA 登录态下的课表；由你决定何时开始。',
          contextLabel: '只读访问 · 当前学期',
          primaryActionLabel: '开始读取',
          onPrimaryAction: _loadCourseTable,
          onCalendar: _openAcademicCalendar,
        ),
      );
    }
    if (!_result!.isSuccess || courseTable == null) {
      return statePanel(
        _ScheduleStatePanel(
          symbol: '!',
          statusLabel: '需要处理',
          title: _result!.message,
          message: _result!.detail,
          contextLabel: '已有缓存不会被清空',
          primaryActionLabel: '检查后重试',
          onPrimaryAction: _loadCourseTable,
          onCalendar: _openAcademicCalendar,
        ),
      );
    }
    final courseView = _CourseScheduleAdaptiveView(
      courseTable: courseTable,
      currentWeekday: _now.weekday,
      selectedMobileWeekday: _selectedMobileWeekday,
      onSelectedMobileWeekdayChanged: (weekday) {
        setState(() => _selectedMobileWeekday = weekday);
      },
    );
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
          fillHeight
              ? Center(
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
              : Padding(
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
          courseView,
      ],
    );
  }

  String _formatCheckedTime(DateTime checkedAt) {
    return '${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}
