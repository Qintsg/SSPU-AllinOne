/*
 * 独立课程表页面 — 展示本专科教务系统只读课表数据
 * @Project : SSPU-AllinOne
 * @File : course_schedule_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

import 'dart:async';

import '../design/fluent_ui.dart';

import '../models/academic_eams.dart';
import '../models/course_period.dart';
import '../services/academic_credentials_service.dart';
import '../services/academic_calendar_service.dart';
import '../services/academic_eams_service.dart';
import '../theme/fluent_tokens.dart';
import '../utils/course_week_parser.dart';
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
      FluentPageRoute(
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
    final canPop = Navigator.of(context).canPop();
    final snapshot = _result?.snapshot;
    final courseTable = snapshot?.courseTable;

    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('课程表'),
        commandBar: Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.xs,
          alignment: WrapAlignment.end,
          children: [
            if (canPop)
              FluentButton.outline(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            FluentButton.outlineIcon(
              key: const Key('open-academic-calendar'),
              onPressed: _openAcademicCalendar,
              icon: const Icon(FluentIcons.calendarWeek, size: 14),
              label: const Text('校历'),
            ),
            FluentButton.primaryIcon(
              key: const Key('course-schedule-refresh'),
              onPressed: _isLoading ? null : _loadCourseTable,
              icon: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.refresh, size: 14),
              label: const Text('刷新课表'),
            ),
          ],
        ),
      ),
      children: [
        FluentSurface(
          padding: const EdgeInsets.all(FluentSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FluentSectionHeader(
                title: '课程表说明',
                subtitle: '只展示课程名称、时间、地点、教师和周次，不提供写入型入口。',
                icon: FluentIcons.calendar,
              ),
              const SizedBox(height: FluentSpacing.m),
              Text(
                _autoRefreshEnabled
                    ? '自动刷新已开启，每 $_autoRefreshIntervalMinutes 分钟更新一次；也可手动刷新。'
                    : '自动刷新未开启。点击“刷新课表”可手动读取；本专科教务需要校园网或学校 VPN。',
              ),
            ],
          ),
        ),
        const SizedBox(height: FluentSpacing.m),
        if (_isLoading && _result == null)
          const FluentSurface(
            padding: EdgeInsets.all(FluentSpacing.xl),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取当前学期课表...'),
              ],
            ),
          )
        else if (_result == null)
          const FluentInfoBar(
            title: Text('尚未读取课表'),
            content: Text('点击“刷新课表”即可按当前 OA 登录态只读获取本学期课表。'),
            severity: FluentInfoSeverity.info,
          )
        else if (!_result!.isSuccess || courseTable == null)
          FluentInfoBar(
            title: Text(_result!.message),
            content: Text(_result!.detail),
            severity: _severityOf(_result!.status),
          )
        else ...[
          _CourseScheduleSummaryCard(
            snapshot: snapshot!,
            checkedAt: _result!.checkedAt,
          ),
          const SizedBox(height: FluentSpacing.m),
          _CourseScheduleAdaptiveView(
            courseTable: courseTable,
            selectedMobileWeekday: _selectedMobileWeekday,
            onSelectedMobileWeekdayChanged: (weekday) {
              setState(() => _selectedMobileWeekday = weekday);
            },
          ),
        ],
      ],
    );
  }

  FluentInfoSeverity _severityOf(AcademicEamsQueryStatus status) {
    return switch (status) {
      AcademicEamsQueryStatus.success => FluentInfoSeverity.success,
      AcademicEamsQueryStatus.partialSuccess ||
      AcademicEamsQueryStatus.missingOaAccount ||
      AcademicEamsQueryStatus.missingOaPassword ||
      AcademicEamsQueryStatus.campusNetworkUnavailable =>
        FluentInfoSeverity.warning,
      AcademicEamsQueryStatus.oaLoginRequired ||
      AcademicEamsQueryStatus.systemUnavailable ||
      AcademicEamsQueryStatus.readOnlyEntryUnavailable ||
      AcademicEamsQueryStatus.queryFormUnavailable ||
      AcademicEamsQueryStatus.parseFailed ||
      AcademicEamsQueryStatus.networkError ||
      AcademicEamsQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
  }
}

class _CourseScheduleSummaryCard extends StatelessWidget {
  const _CourseScheduleSummaryCard({
    required this.snapshot,
    required this.checkedAt,
  });

  final AcademicEamsSnapshot snapshot;
  final DateTime checkedAt;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final profile = snapshot.profile;
    final courseTable = snapshot.courseTable!;
    final completion = snapshot.programCompletion;

    return FluentSurface(
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本学期概览', style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.s),
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
            children: [
              _CourseSummaryTag(
                label: '学期',
                value: courseTable.termName ?? '当前学期',
              ),
              _CourseSummaryTag(
                label: '课程数',
                value: '${courseTable.entries.length} 门',
              ),
              _CourseSummaryTag(
                label: '刷新时间',
                value:
                    '${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}',
              ),
              if (completion != null)
                _CourseSummaryTag(
                  label: '培养计划',
                  value:
                      '${completion.completedCredits.toStringAsFixed(1)}/${(completion.completedCredits + completion.pendingCredits).toStringAsFixed(1)} 学分',
                ),
            ],
          ),
          if (profile != null && profile.hasAnyValue) ...[
            const SizedBox(height: FluentSpacing.m),
            Text(
              [
                if (profile.name != null && profile.name!.isNotEmpty)
                  '姓名：${profile.name}',
                if (profile.department != null &&
                    profile.department!.isNotEmpty)
                  '院系：${profile.department}',
                if (profile.major != null && profile.major!.isNotEmpty)
                  '专业：${profile.major}',
                if (profile.className != null && profile.className!.isNotEmpty)
                  '班级：${profile.className}',
              ].join('  ·  '),
            ),
          ],
          if (snapshot.warnings.isNotEmpty) ...[
            const SizedBox(height: FluentSpacing.m),
            FluentInfoBar(
              title: const Text('课表已可用，部分教务模块仍在降级'),
              content: Text(snapshot.warnings.join('；')),
              severity: FluentInfoSeverity.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseSummaryTag extends StatelessWidget {
  const _CourseSummaryTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.m,
        vertical: FluentSpacing.s,
      ),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.16)),
      ),
      child: Text('$label：$value'),
    );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
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
    final colors = context.fluentColors;
    final metrics = context.appMetrics;
    const periodTable = CoursePeriodTable.standard;
    final nowWeekday = DateTime.now().weekday;
    final minWidth = metrics.schedulePeriodColumnWidth + 7 * 156;

    return FluentSurface(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        primary: false,
        child: SizedBox(
          width: minWidth,
          child: Column(
            children: [
              _CourseGridHeader(currentWeekday: nowWeekday),
              for (final period in periodTable.periods)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CoursePeriodCell(period: period),
                      for (var weekday = 1; weekday <= 7; weekday++)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: weekday == nowWeekday
                                  ? colors.brandStroke2.withValues(alpha: 0.10)
                                  : null,
                              border: Border(
                                left: BorderSide(
                                  color: colors.neutralStrokeDivider,
                                ),
                                top: BorderSide(
                                  color: colors.neutralStrokeDivider,
                                ),
                              ),
                            ),
                            constraints: BoxConstraints(
                              minHeight: metrics.scheduleCellMinHeight,
                            ),
                            padding: const EdgeInsets.all(FluentSpacing.xs),
                            child: _CourseGridCell(
                              entries: _entriesStartingAt(
                                entries,
                                weekday,
                                period.unit,
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
  const _CourseGridHeader({required this.currentWeekday});

  final int currentWeekday;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final metrics = context.appMetrics;
    return Row(
      children: [
        SizedBox(
          width: metrics.schedulePeriodColumnWidth,
          child: Padding(
            padding: const EdgeInsets.all(FluentSpacing.s),
            child: Text('节次', style: type.caption1Strong),
          ),
        ),
        for (var weekday = 1; weekday <= 7; weekday++)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(FluentSpacing.s),
              decoration: BoxDecoration(
                color: weekday == currentWeekday
                    ? colors.brandStroke2.withValues(alpha: 0.16)
                    : colors.neutralBackground2,
                border: Border(
                  left: BorderSide(color: colors.neutralStrokeDivider),
                ),
              ),
              child: Text(
                _weekdayLabel(weekday),
                textAlign: TextAlign.center,
                style: type.body1Strong.copyWith(
                  color: weekday == currentWeekday
                      ? colors.brandForeground1
                      : colors.neutralForeground1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CoursePeriodCell extends StatelessWidget {
  const _CoursePeriodCell({required this.period});

  final CoursePeriod period;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final metrics = context.appMetrics;
    return Container(
      width: metrics.schedulePeriodColumnWidth,
      constraints: BoxConstraints(minHeight: metrics.scheduleCellMinHeight),
      padding: const EdgeInsets.all(FluentSpacing.s),
      decoration: BoxDecoration(
        color: colors.neutralBackground2,
        border: Border(top: BorderSide(color: colors.neutralStrokeDivider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${period.unit}', style: type.body1Strong),
          const SizedBox(height: FluentSpacing.xxs),
          Text(period.timeRange, style: type.caption2),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(child: _CourseBlock(entry: entries[i], compact: true)),
          if (i < entries.length - 1) const SizedBox(width: FluentSpacing.xs),
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
    return FluentSurface(
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FluentSpacing.xs,
            runSpacing: FluentSpacing.xs,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                ToggleButton(
                  checked: weekday == selectedWeekday,
                  onChanged: (_) => onWeekdayChanged(weekday),
                  child: Text(_weekdayLabel(weekday)),
                ),
            ],
          ),
          const SizedBox(height: FluentSpacing.l),
          if (entries.isEmpty)
            Text(
              '${_weekdayLabel(selectedWeekday)}暂无课程',
              style: context.fluentType.body1.copyWith(
                color: context.fluentColors.neutralForeground2,
              ),
            )
          else
            Column(
              children: [
                for (final entry in entries) ...[
                  _CourseBlock(entry: entry),
                  if (entry != entries.last)
                    const SizedBox(height: FluentSpacing.s),
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
    final colors = context.fluentColors;
    final type = context.fluentType;
    final radii = context.fluentRadii;
    final color = context.fluentCoursePalette.colorFor(entry.courseName);
    const periodTable = CoursePeriodTable.standard;
    final timeRange = periodTable.rangeText(entry.startUnit, entry.endUnit);
    final weekResult = CourseWeekParser.parse(entry.weekDescription);
    final parsedWeeks = weekResult.weeks.isEmpty
        ? entry.weekDescription
        : '${weekResult.weeks.length}周';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? FluentSpacing.s : FluentSpacing.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: radii.largeBorder,
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.courseName,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: type.body1Strong.copyWith(color: color),
          ),
          const SizedBox(height: FluentSpacing.xs),
          Wrap(
            spacing: compact ? FluentSpacing.xs : FluentSpacing.s,
            runSpacing: FluentSpacing.xs,
            children: [
              _buildMeta(
                context,
                FluentIcons.clock,
                '$timeRange · ${entry.timeText}',
                compact: compact,
              ),
              if (entry.location != null && entry.location!.isNotEmpty)
                _buildMeta(
                  context,
                  FluentIcons.location,
                  entry.location!,
                  compact: compact,
                ),
              if (entry.teacher != null && entry.teacher!.isNotEmpty)
                _buildMeta(
                  context,
                  FluentIcons.contact,
                  entry.teacher!,
                  compact: compact,
                ),
              if (parsedWeeks != null && parsedWeeks.isNotEmpty)
                _buildMeta(
                  context,
                  FluentIcons.calendarWeek,
                  parsedWeeks,
                  compact: compact,
                ),
            ],
          ),
          if (entry.location == null &&
              entry.teacher == null &&
              entry.weekDescription == null)
            Padding(
              padding: const EdgeInsets.only(top: FluentSpacing.xs),
              child: Text(
                entry.rawText,
                style: type.caption1.copyWith(color: colors.neutralForeground3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeta(
    BuildContext context,
    IconData icon,
    String text, {
    required bool compact,
  }) {
    final colors = context.fluentColors;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 112 : 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.neutralForeground3),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.fluentType.caption1.copyWith(
                color: colors.neutralForeground3,
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
