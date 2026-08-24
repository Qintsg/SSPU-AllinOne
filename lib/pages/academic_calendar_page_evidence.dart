/*
 * 校历页面证据 — 学期边界、特殊日期与通知
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_evidence.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_calendar_page.dart';

class _CalendarEvidence extends StatelessWidget {
  const _CalendarEvidence({required this.entry, required this.compact});

  final AcademicCalendarCacheEntry? entry;
  final bool compact;

  String _dateRange(DateTime start, DateTime end) {
    String part(DateTime value) =>
        '${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
    return '${part(start)}—${part(end)}';
  }

  int _teachingWeeks(AcademicCalendarTermSchedule schedule) => schedule
      .summerSegments
      .fold(0, (sum, segment) => sum + segment.endWeek - segment.startWeek + 1);

  @override
  Widget build(BuildContext context) {
    final schedule = entry?.schedule;
    if (schedule == null) return const SizedBox.shrink();
    final theme = context.yhTheme;
    final fall = _dateRange(schedule.fallStart, schedule.fallEnd);
    final spring = _dateRange(schedule.springStart, schedule.springEnd);
    final summer = '${_teachingWeeks(schedule)} 个教学周';
    final notices = <String>[
      ...schedule.dayTags.map((tag) => tag.sourceText),
      ...schedule.pendingHolidayNotices.map((notice) => notice.sourceText),
    ];
    if (compact) {
      return Semantics(
        label: '学期边界：秋季 $fall，春季 $spring，夏季 $summer。${notices.join('；')}',
        child: Container(
          constraints: BoxConstraints(minHeight: theme.control.touch),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
            vertical: theme.spacing.s,
          ),
          decoration: BoxDecoration(
            color: theme.color.sunken,
            border: Border.all(color: theme.color.border),
            borderRadius: BorderRadius.circular(theme.radius.m),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_yearLabel(entry!)} · 秋季 $fall · 春季 $spring · 夏季 $summer',
                style: theme.typography.small.copyWith(
                  color: theme.color.foreground,
                  fontWeight: theme.typography.semibold,
                ),
              ),
              if (notices.isNotEmpty) ...[
                SizedBox(height: theme.spacing.xs),
                Text(
                  notices.join('；'),
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
      key: const Key('academic-calendar-evidence-card'),
      padding: EdgeInsets.only(
        left: theme.spacing.m,
        top: theme.spacing.l,
        right: theme.spacing.m,
        bottom: theme.spacing.m,
      ),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '学期边界',
            style: theme.typography.caption.copyWith(
              color: theme.color.brandStrong,
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            _yearLabel(entry!),
            style: theme.typography.h3.copyWith(
              color: theme.color.foreground,
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: theme.spacing.m),
          _CalendarEvidenceRow(label: '秋季', value: fall),
          _CalendarEvidenceRow(label: '春季', value: spring),
          _CalendarEvidenceRow(label: '夏季', value: summer),
          if (notices.isNotEmpty) ...[
            SizedBox(height: theme.spacing.s),
            Container(height: theme.layout.divider, color: theme.color.border),
            SizedBox(height: theme.spacing.s),
            for (final notice in notices)
              Padding(
                padding: EdgeInsets.only(bottom: theme.spacing.xs),
                child: Text(
                  notice,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CalendarEvidenceRow extends StatelessWidget {
  const _CalendarEvidenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: theme.spacing.xl,
            child: Text(
              label,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.typography.body.copyWith(
                color: theme.color.foreground,
                fontWeight: theme.typography.semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
