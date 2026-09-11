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
    if (!compact) {
      return _CourseWeekGridView(
        entries: courseTable.entries,
        currentWeekday: currentWeekday,
      );
    }
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
        _CourseDayScheduleView(
          entries: _entriesForWeekday(
            courseTable.entries,
            selectedMobileWeekday,
          ),
          selectedWeekday: selectedMobileWeekday,
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
    final timelineWidth = theme.control.regular + theme.spacing.l;
    final headerHeight = theme.control.regular + theme.spacing.s;
    final periodHeight = theme.control.minimumTarget + theme.spacing.m;
    final totalHeight =
        headerHeight + periodHeight * periodTable.periods.length;
    final minimumGridWidth = theme.control.regular * 19;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = math.max(constraints.maxWidth, minimumGridWidth);
        final dayWidth = (gridWidth - timelineWidth) / 7;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: gridWidth,
            height: totalHeight,
            child: YhCard(
              padding: EdgeInsets.zero,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: timelineWidth,
                    height: headerHeight,
                    child: _CourseGridHeaderCell(
                      label: '时间',
                      highlighted: false,
                    ),
                  ),
                  for (var weekday = 1; weekday <= 7; weekday++)
                    Positioned(
                      key: ValueKey('course-week-header-$weekday'),
                      left: timelineWidth + (weekday - 1) * dayWidth,
                      top: 0,
                      width: dayWidth,
                      height: headerHeight,
                      child: _CourseGridHeaderCell(
                        label: _weekdayLabel(weekday),
                        highlighted: weekday == currentWeekday,
                      ),
                    ),
                  for (
                    var index = 0;
                    index < periodTable.periods.length;
                    index++
                  )
                    Positioned(
                      key: ValueKey(
                        'course-period-${periodTable.periods[index].unit}',
                      ),
                      left: 0,
                      top: headerHeight + index * periodHeight,
                      width: timelineWidth,
                      height: periodHeight,
                      child: _CourseTimelineCell(
                        period: periodTable.periods[index],
                      ),
                    ),
                  for (
                    var periodIndex = 0;
                    periodIndex < periodTable.periods.length;
                    periodIndex++
                  )
                    for (var weekday = 1; weekday <= 7; weekday++)
                      Positioned(
                        left: timelineWidth + (weekday - 1) * dayWidth,
                        top: headerHeight + periodIndex * periodHeight,
                        width: dayWidth,
                        height: periodHeight,
                        child: _CourseGridBackgroundCell(
                          highlighted: weekday == currentWeekday,
                        ),
                      ),
                  for (final entry in entries)
                    if (entry.weekday >= 1 && entry.weekday <= 7)
                      Positioned(
                        key: ValueKey(
                          'course-week-block-${entry.weekday}-${entry.startUnit}-${entry.courseName}',
                        ),
                        left:
                            timelineWidth +
                            (entry.weekday - 1) * dayWidth +
                            theme.spacing.xs,
                        top:
                            headerHeight +
                            (entry.startUnit.clamp(
                                      1,
                                      periodTable.periods.length,
                                    ) -
                                    1) *
                                periodHeight +
                            theme.spacing.xs,
                        width: dayWidth - theme.spacing.xs * 2,
                        height:
                            (entry.endUnit.clamp(
                                      entry.startUnit.clamp(
                                        1,
                                        periodTable.periods.length,
                                      ),
                                      periodTable.periods.length,
                                    ) -
                                    entry.startUnit.clamp(
                                      1,
                                      periodTable.periods.length,
                                    ) +
                                    1) *
                                periodHeight -
                            theme.spacing.xs * 2,
                        child: _CourseWeekBlock(entry: entry),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CourseGridHeaderCell extends StatelessWidget {
  const _CourseGridHeaderCell({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? theme.color.brandTint : theme.color.sunken,
        border: BorderDirectional(
          start: BorderSide(color: theme.color.border),
          bottom: BorderSide(color: theme.color.border),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: theme.typography.body.copyWith(
            color: highlighted ? theme.color.brandInk : theme.color.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CourseTimelineCell extends StatelessWidget {
  const _CourseTimelineCell({required this.period});

  final CoursePeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        border: BorderDirectional(
          end: BorderSide(color: theme.color.border),
          bottom: BorderSide(color: theme.color.border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${period.unit}',
              style: theme.typography.body.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: YhTypographyTokens.fontFamilyMono,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              period.startTime,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
                fontFamily: YhTypographyTokens.fontFamilyMono,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseGridBackgroundCell extends StatelessWidget {
  const _CourseGridBackgroundCell({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? theme.color.brandTint : theme.color.surface,
        border: BorderDirectional(
          end: BorderSide(color: theme.color.border),
          bottom: BorderSide(color: theme.color.border),
        ),
      ),
    );
  }
}

class _CourseWeekBlock extends StatelessWidget {
  const _CourseWeekBlock({required this.entry});

  final AcademicCourseTableEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final colors = <Color>[
      theme.color.serviceSchedule,
      theme.color.serviceAcademic,
      theme.color.serviceMail,
      theme.color.serviceNews,
      theme.color.serviceSports,
      theme.color.serviceSecondClass,
      theme.color.serviceFinance,
    ];
    final accent =
        colors[(entry.courseName.hashCode & 0x7fffffff) % colors.length];
    final span = math.max(1, entry.endUnit - entry.startUnit + 1);
    final detail = <String>[
      if (entry.location?.trim().isNotEmpty == true) entry.location!.trim(),
      if (entry.teacher?.trim().isNotEmpty == true) entry.teacher!.trim(),
      CoursePeriodTable.standard.rangeText(entry.startUnit, entry.endUnit),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.16),
          theme.color.surface,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.courseName,
              maxLines: span == 1 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.small.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (span > 1 && detail.isNotEmpty) ...[
              SizedBox(height: theme.spacing.xs),
              Text(
                detail.join('\n'),
                maxLines: math.min(3, span + 1),
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption.copyWith(
                  color: theme.color.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
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
