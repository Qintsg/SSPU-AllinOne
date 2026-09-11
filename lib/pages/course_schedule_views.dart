/*
 * 课程表响应式视图 — 日期带、周网格与课程块绘制
 * @Project : SSPU-AllinOne
 * @File : course_schedule_views.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'course_schedule_page.dart';

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
                label: compact
                    ? _compactWeekdayLabel(
                        weekday,
                        isCurrentWeekday: weekday == currentWeekday,
                      )
                    : weekday == currentWeekday
                    ? '${_weekdayLabel(weekday)} · 今天'
                    : _weekdayLabel(weekday),
                semanticLabel: weekday == currentWeekday
                    ? '${_weekdayLabel(weekday)}，今天'
                    : _weekdayLabel(weekday),
              ),
          ],
          value: selectedMobileWeekday,
          onChanged: onSelectedMobileWeekdayChanged,
          distributeEvenly: compact,
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
            _buildRow(
              group,
              periodTable,
              periodColumnWidth,
              cellMinHeight,
              theme,
            ),
        ],
      ),
    );
  }

  /// 构建单个固定密度的节次组行。
  Widget _buildRow(
    int group,
    CoursePeriodTable periodTable,
    double periodColumnWidth,
    double cellMinHeight,
    YhTheme theme,
  ) {
    return IntrinsicHeight(
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

class _AcademicAgendaView extends StatelessWidget {
  const _AcademicAgendaView({
    required this.events,
    required this.now,
    required this.showWholeTerm,
    required this.onShowWholeTermChanged,
  });

  final List<AcademicCalendarEvent> events;
  final DateTime now;
  final bool showWholeTerm;
  final ValueChanged<bool> onShowWholeTermChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final visibleEvents = showWholeTerm
        ? events
        : events
              .where(
                (event) =>
                    !event.start.isBefore(weekStart) &&
                    event.start.isBefore(weekEnd),
              )
              .toList(growable: false);
    return Column(
      key: const Key('academic-integrated-agenda'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YhTabs<bool>(
          tabs: const [
            YhTab(value: false, label: '本周'),
            YhTab(value: true, label: '整学期'),
          ],
          value: showWholeTerm,
          onChanged: onShowWholeTermChanged,
        ),
        SizedBox(height: theme.spacing.m),
        if (visibleEvents.isEmpty)
          YhCard(
            child: YhEmptyState(
              icon: YhIcons.calendar,
              title: showWholeTerm ? '本学期暂无日历事件' : '本周暂无课程或考试',
              message: showWholeTerm
                  ? '课表和考试安排中没有可定位到具体日期的记录。'
                  : '可切换到整学期查看后续课程与考试。',
            ),
          )
        else
          for (var index = 0; index < visibleEvents.length; index++) ...[
            _AcademicAgendaEventCard(event: visibleEvents[index]),
            if (index != visibleEvents.length - 1)
              SizedBox(height: theme.spacing.s),
          ],
      ],
    );
  }
}

class _AcademicAgendaEventCard extends StatelessWidget {
  const _AcademicAgendaEventCard({required this.event});

  final AcademicCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final isExam = event.type == AcademicCalendarEventType.exam;
    return YhCard(
      padding: EdgeInsets.all(theme.spacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: theme.control.regular * 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.start.month}月${event.start.day}日',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                    fontFamily: YhTypographyTokens.fontFamilyMono,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  _agendaTimeRange(event),
                  style: theme.typography.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: theme.spacing.s,
                  runSpacing: theme.spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    YhStatusPill(
                      label: isExam ? '考试' : '课程',
                      kind: isExam ? YhStatusKind.warning : YhStatusKind.info,
                    ),
                    Text(event.title, style: theme.typography.h3),
                  ],
                ),
                if (event.location.isNotEmpty) ...[
                  SizedBox(height: theme.spacing.s),
                  Text(
                    event.location,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
                if (event.description.isNotEmpty) ...[
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    event.description,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _agendaTimeRange(AcademicCalendarEvent event) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(event.start.hour)}:${two(event.start.minute)}–'
      '${two(event.end.hour)}:${two(event.end.minute)}';
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

/// 返回紧凑端日期带使用的两字视觉标签。
String _compactWeekdayLabel(int weekday, {required bool isCurrentWeekday}) {
  return isCurrentWeekday ? '今天' : _weekdayLabel(weekday);
}
