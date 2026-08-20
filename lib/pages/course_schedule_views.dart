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

/// 返回紧凑端日期带使用的两字视觉标签。
String _compactWeekdayLabel(int weekday, {required bool isCurrentWeekday}) {
  return isCurrentWeekday ? '今天' : _weekdayLabel(weekday);
}
