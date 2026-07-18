/*
 * 独立课程表页面 — 展示本专科教务系统只读课表数据
 * @Project : SSPU-AllinOne
 * @File : course_schedule_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/academic_eams.dart';
import '../models/course_period.dart';
import '../services/academic_calendar_service.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_eams_service.dart';
import '../utils/course_week_parser.dart';
import 'academic_calendar_page.dart';
import 'course_schedule_summary_card.dart';

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

  /// 校历客户端，测试中可替换为 fake。
  final AcademicCalendarClient? academicCalendarService;

  const CourseSchedulePage({
    super.key,
    this.academicEamsService,
    this.initialResult,
    this.autoRefreshEnabledOverride,
    this.autoRefreshIntervalOverride,
    this.academicCalendarService,
  });

  @override
  State<CourseSchedulePage> createState() => _CourseSchedulePageState();
}

class _CourseSchedulePageState extends State<CourseSchedulePage> {
  AcademicEamsQueryResult? _result;
  bool _isLoading = false;
  bool _autoRefreshEnabled = false;
  int _autoRefreshIntervalMinutes =
      AcademicEamsService.defaultAutoRefreshIntervalMinutes;
  Timer? _autoRefreshTimer;
  StreamSubscription<int>? _credentialChangeSubscription;
  int _selectedMobileWeekday = DateTime.now().weekday;

  AcademicEamsClient get _academicEamsService {
    return widget.academicEamsService ?? AcademicEamsService.instance;
  }

  @override
  void initState() {
    super.initState();
    _credentialChangeSubscription = AcademicCredentialsService.instance.changes
        .listen((_) => _clearAuthenticatedState());
    _result = widget.initialResult;
    _loadCacheAndAutoRefreshSettings();
  }

  void _clearAuthenticatedState() {
    if (!mounted) return;
    setState(() {
      _result = null;
      _isLoading = false;
    });
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
    setState(() {
      _autoRefreshEnabled = enabled;
      _autoRefreshIntervalMinutes = interval;
    });
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
    final cachedResult = await _academicEamsService
        .readLatestCachedCourseTable();
    if (mounted && cachedResult != null && !_hasUsableCourseTable(_result)) {
      setState(() => _result = cachedResult);
    }
    await _loadAutoRefreshSettings();
  }

  bool _hasUsableCourseTable(AcademicEamsQueryResult? result) {
    final entries = result?.snapshot?.courseTable?.entries;
    return result?.isSuccess == true && entries != null && entries.isNotEmpty;
  }

  Future<void> _loadCourseTable({bool silent = false}) async {
    if (_isLoading) return;
    if (!silent) setState(() => _isLoading = true);

    final result = await _academicEamsService.fetchCourseTable(
      requireCampusNetwork: silent,
    );
    if (!mounted) return;
    if (silent && !result.isSuccess) return;
    setState(() {
      _result = result;
      if (!silent) _isLoading = false;
    });
  }

  bool _shouldAutoRefresh(DateTime? fetchedAt, int intervalMinutes) {
    if (intervalMinutes <= 0) return false;
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) >=
        Duration(minutes: intervalMinutes);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final canPop = Navigator.of(context).canPop();
    final snapshot = _result?.snapshot;
    final courseTable = snapshot?.courseTable;

    return YhPageScaffold(
      appBar: YhAppBar(
        title: '课程表',
        leading: canPop
            ? YhButton(
                label: '返回',
                leadingIcon: YhIcons.back,
                variant: YhButtonVariant.text,
                onTap: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          YhButton(
            key: const Key('open-academic-calendar'),
            label: '校历',
            leadingIcon: YhIcons.calendar,
            variant: YhButtonVariant.secondary,
            onTap: _openAcademicCalendar,
          ),
          YhButton(
            key: const Key('course-schedule-refresh'),
            label: _isLoading ? '读取中' : '刷新课表',
            leadingIcon: _isLoading ? null : YhIcons.refresh,
            onTap: _isLoading ? null : _loadCourseTable,
          ),
        ],
      ),
      body: SingleChildScrollView(
        primary: true,
        padding: EdgeInsets.all(theme.spacing.m),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.expanded),
            child: _buildContent(snapshot, courseTable),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    AcademicEamsSnapshot? snapshot,
    AcademicCourseTableSnapshot? courseTable,
  ) {
    final theme = context.yhTheme;
    if (_isLoading && _result == null) {
      return YhCard(
        child: Row(
          children: [
            SizedBox(
              width: theme.spacing.xl2 * 2,
              child: const YhProgress(showPercent: false),
            ),
            SizedBox(width: theme.spacing.m),
            const Expanded(child: Text('正在读取当前学期课表...')),
          ],
        ),
      );
    }
    if (_result == null) {
      return const YhBanner(text: '尚未读取课表：点击“刷新课表”即可按当前 OA 登录态只读获取本学期课表。');
    }
    if (!_result!.isSuccess || courseTable == null) {
      return YhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(_result!.message, style: theme.typography.h3),
            ),
            SizedBox(height: theme.spacing.s),
            YhBanner(
              text: _result!.detail,
              kind: _bannerKindOf(_result!.status),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseScheduleSummaryCard(
          snapshot: snapshot!,
          checkedAt: _result!.checkedAt,
          autoRefreshEnabled: _autoRefreshEnabled,
          autoRefreshIntervalMinutes: _autoRefreshIntervalMinutes,
        ),
        SizedBox(height: theme.spacing.m),
        _CourseScheduleAdaptiveView(
          courseTable: courseTable,
          selectedMobileWeekday: _selectedMobileWeekday,
          onSelectedMobileWeekdayChanged: (weekday) {
            setState(() => _selectedMobileWeekday = weekday);
          },
        ),
      ],
    );
  }

  YhBannerKind _bannerKindOf(AcademicEamsQueryStatus status) {
    return switch (status) {
      AcademicEamsQueryStatus.success => YhBannerKind.success,
      AcademicEamsQueryStatus.partialSuccess ||
      AcademicEamsQueryStatus.missingOaAccount ||
      AcademicEamsQueryStatus.missingOaPassword ||
      AcademicEamsQueryStatus.campusNetworkUnavailable => YhBannerKind.warn,
      AcademicEamsQueryStatus.oaLoginRequired ||
      AcademicEamsQueryStatus.systemUnavailable ||
      AcademicEamsQueryStatus.readOnlyEntryUnavailable ||
      AcademicEamsQueryStatus.queryFormUnavailable ||
      AcademicEamsQueryStatus.parseFailed ||
      AcademicEamsQueryStatus.networkError ||
      AcademicEamsQueryStatus.unexpectedError => YhBannerKind.danger,
    };
  }
}

class _CourseScheduleAdaptiveView extends StatelessWidget {
  const _CourseScheduleAdaptiveView({
    required this.courseTable,
    required this.selectedMobileWeekday,
    required this.onSelectedMobileWeekdayChanged,
  });

  final AcademicCourseTableSnapshot courseTable;
  final int selectedMobileWeekday;
  final ValueChanged<int> onSelectedMobileWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            theme.breakpoint.medium - theme.spacing.xl2) {
          return _CourseDayScheduleView(
            entries: _entriesForWeekday(
              courseTable.entries,
              selectedMobileWeekday,
            ),
            selectedWeekday: selectedMobileWeekday,
            onWeekdayChanged: onSelectedMobileWeekdayChanged,
          );
        }
        return _CourseWeekGridView(entries: courseTable.entries);
      },
    );
  }
}

class _CourseWeekGridView extends StatelessWidget {
  const _CourseWeekGridView({required this.entries});

  final List<AcademicCourseTableEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    const periodTable = CoursePeriodTable.standard;
    final nowWeekday = DateTime.now().weekday;
    final periodColumnWidth =
        theme.spacing.xl2 + theme.spacing.xl + theme.spacing.xs / 2;
    final weekdayColumnWidth =
        theme.spacing.xl2 * 3 + theme.spacing.s + theme.spacing.xs;
    final cellMinHeight =
        theme.spacing.xl2 + theme.spacing.l + theme.spacing.xs;
    final minWidth = periodColumnWidth + 7 * weekdayColumnWidth;

    return YhCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        primary: false,
        child: SizedBox(
          width: minWidth,
          child: Column(
            children: [
              _CourseGridHeader(
                currentWeekday: nowWeekday,
                periodColumnWidth: periodColumnWidth,
              ),
              for (final period in periodTable.periods)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CoursePeriodCell(
                        period: period,
                        width: periodColumnWidth,
                        minHeight: cellMinHeight,
                      ),
                      for (var weekday = 1; weekday <= 7; weekday++)
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: weekday == nowWeekday
                                  ? theme.color.brandTint
                                  : theme.color.surface,
                              border: BorderDirectional(
                                start: BorderSide(color: theme.color.border),
                                top: BorderSide(color: theme.color.border),
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: cellMinHeight,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(theme.spacing.xs),
                                child: _CourseGridCell(
                                  entries: _entriesStartingAt(
                                    entries,
                                    weekday,
                                    period.unit,
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
        ),
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
    return Row(
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
    );
  }
}

class _CoursePeriodCell extends StatelessWidget {
  const _CoursePeriodCell({
    required this.period,
    required this.width,
    required this.minHeight,
  });

  final CoursePeriod period;
  final double width;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
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
                  '${period.unit}',
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  period.timeRange,
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
          Expanded(child: _CourseBlock(entry: entries[i], compact: true)),
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
    required this.onWeekdayChanged,
  });

  final List<AcademicCourseTableEntry> entries;
  final int selectedWeekday;
  final ValueChanged<int> onWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: theme.spacing.xs,
            runSpacing: theme.spacing.xs,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                YhChip(
                  label: _weekdayLabel(weekday),
                  selected: weekday == selectedWeekday,
                  onTap: () => onWeekdayChanged(weekday),
                ),
            ],
          ),
          SizedBox(height: theme.spacing.l),
          if (entries.isEmpty)
            YhBanner(text: '${_weekdayLabel(selectedWeekday)}暂无课程')
          else
            Column(
              children: [
                for (final entry in entries) ...[
                  _CourseBlock(entry: entry),
                  if (entry != entries.last) SizedBox(height: theme.spacing.s),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CourseBlock extends StatelessWidget {
  const _CourseBlock({required this.entry, this.compact = false});

  final AcademicCourseTableEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceSchedule;
    const periodTable = CoursePeriodTable.standard;
    final timeRange = periodTable.rangeText(entry.startUnit, entry.endUnit);
    final weekResult = CourseWeekParser.parse(entry.weekDescription);
    final parsedWeeks = weekResult.weeks.isEmpty
        ? entry.weekDescription
        : '${weekResult.weeks.length}周';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.input),
        border: Border.all(color: accent),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(compact ? theme.spacing.s : theme.spacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.courseName,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Wrap(
                spacing: compact ? theme.spacing.xs : theme.spacing.s,
                runSpacing: theme.spacing.xs,
                children: [
                  _buildMeta(
                    context,
                    YhIcons.clock,
                    '$timeRange · ${entry.timeText}',
                    compact: compact,
                  ),
                  if (entry.location != null && entry.location!.isNotEmpty)
                    _buildMeta(
                      context,
                      YhIcons.location,
                      entry.location!,
                      compact: compact,
                    ),
                  if (entry.teacher != null && entry.teacher!.isNotEmpty)
                    _buildMeta(
                      context,
                      YhIcons.profile,
                      entry.teacher!,
                      compact: compact,
                    ),
                  if (parsedWeeks != null && parsedWeeks.isNotEmpty)
                    _buildMeta(
                      context,
                      YhIcons.calendar,
                      parsedWeeks,
                      compact: compact,
                    ),
                ],
              ),
              if (entry.location == null &&
                  entry.teacher == null &&
                  entry.weekDescription == null)
                Padding(
                  padding: EdgeInsets.only(top: theme.spacing.xs),
                  child: Text(
                    entry.rawText,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(
    BuildContext context,
    IconData icon,
    String text, {
    required bool compact,
  }) {
    final theme = context.yhTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact
            ? theme.control.regular * 2 + theme.spacing.m
            : theme.breakpoint.compact / 2 - theme.spacing.xl - theme.spacing.s,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: theme.spacing.m, color: theme.color.muted),
          SizedBox(width: theme.spacing.xs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ),
        ],
      ),
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

List<AcademicCourseTableEntry> _entriesStartingAt(
  List<AcademicCourseTableEntry> entries,
  int weekday,
  int startUnit,
) {
  final filtered = entries
      .where(
        (entry) => entry.weekday == weekday && entry.startUnit == startUnit,
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
