/*
 * 体育考勤详情的展示面板 — 汇总指标、证据记录与纯格式化辅助
 * @Project : SSPU-AllinOne
 * @File : academic_sports_attendance_detail_panels.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'academic_page.dart';

class _SportsAttendanceSummaryPanel extends StatelessWidget {
  const _SportsAttendanceSummaryPanel({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final metrics = [
      ('总次数', summary.totalCount),
      ('晨跑次数', summary.morningExerciseCount),
      ('课外活动', summary.extracurricularActivityCount),
      ('体育长廊', summary.sportsCorridorCount),
      ('次数调整', summary.countAdjustmentCount),
    ];
    return DecoratedBox(
      decoration: _summaryPanelDecoration(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? theme.spacing.m : theme.spacing.l,
          theme.spacing.l,
          compact ? theme.spacing.m : theme.spacing.l,
          compact ? theme.spacing.m : theme.spacing.l,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < theme.breakpoint.compact;
            return Wrap(
              spacing: theme.spacing.l,
              runSpacing: theme.spacing.m,
              children: [
                for (var index = 0; index < metrics.length; index++)
                  SizedBox(
                    width: compact
                        ? (constraints.maxWidth - theme.spacing.l) / 2
                        : null,
                    child: _SportsAttendanceMetric(
                      label: metrics[index].$1,
                      value: '${metrics[index].$2}',
                      emphasized: index == 0,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SportsAttendanceMetric extends StatelessWidget {
  const _SportsAttendanceMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: (emphasized ? theme.typography.display : theme.typography.h2)
              .copyWith(
                color: emphasized ? theme.color.serviceSports : null,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          label,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
      ],
    );
  }
}

class _SportsAttendanceRecordsPanel extends StatelessWidget {
  const _SportsAttendanceRecordsPanel({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.records.isEmpty) {
      return const YhBanner(text: '暂无明细记录：体育部页面返回了汇总次数，但没有可展示的考勤明细。');
    }

    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    return YhCard(
      padding: EdgeInsets.fromLTRB(
        compact ? theme.spacing.m : theme.spacing.l,
        theme.spacing.l,
        compact ? theme.spacing.m : theme.spacing.l,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本学期运动证据',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.serviceSports,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text('考勤明细', style: theme.typography.h2),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '${summary.records.length} 条记录',
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本学期运动证据',
                        style: theme.typography.caption.copyWith(
                          color: theme.color.serviceSports,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text('考勤明细', style: theme.typography.h2),
                    ],
                  ),
                ),
                Text(
                  '${summary.records.length} 条记录',
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          SizedBox(height: theme.spacing.m),
          Container(height: theme.layout.divider, color: theme.color.border),
          for (final record in summary.records)
            _SportsAttendanceEvidenceRecord(record: record),
        ],
      ),
    );
  }
}

class _SportsAttendanceEvidenceRecord extends StatelessWidget {
  const _SportsAttendanceEvidenceRecord({required this.record});

  final SportsAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final occurred = _sportsAttendanceDateParts(record.occurredAt);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoint.compact;
        final date = SizedBox(
          width: theme.control.regular + theme.spacing.s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                occurred.$1,
                style: theme.typography.h3.copyWith(
                  color: theme.color.serviceSports,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                occurred.$2,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.project?.trim().isNotEmpty == true
                  ? record.project!.trim()
                  : record.category.label,
              style: theme.typography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              '${record.category.label} · ${_sportsAttendanceEmptyAsDash(record.location ?? '')}',
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              _sportsAttendanceEmptyAsDash(record.remark ?? ''),
              style: theme.typography.caption.copyWith(
                color: theme.color.foreground,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              '原始记录已保留：${record.cells.join(' / ')}',
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        );
        final count = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              '${record.count} 次',
              style: theme.typography.h3.copyWith(
                color: theme.color.serviceSports,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              '原始记录已保留',
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        );
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    date,
                    SizedBox(height: theme.spacing.s),
                    count,
                    SizedBox(height: theme.spacing.s),
                    details,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    date,
                    SizedBox(width: theme.spacing.m),
                    Expanded(child: details),
                    SizedBox(width: theme.spacing.m),
                    count,
                  ],
                ),
        );
      },
    );
  }
}

(String, String) _sportsAttendanceDateParts(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return ('—', '—');
  final parts = normalized.split(RegExp(r'\s+'));
  final dateParts = parts.first.split('-');
  final date = dateParts.length == 3
      ? '${dateParts[1]}·${dateParts[2]}'
      : parts.first;
  return (date, parts.length > 1 ? parts.sublist(1).join(' ') : '—');
}

String _sportsAttendanceEmptyAsDash(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}
