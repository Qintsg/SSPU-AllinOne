/*
 * 体育考勤详情页 — 使用表格展示课外活动与晨跑明细
 * @Project : SSPU-AllinOne
 * @File : academic_sports_attendance_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'academic_page.dart';

/// 体育部课外活动考勤明细二级页面。
class SportsAttendanceDetailPage extends StatelessWidget {
  /// 已读取的考勤汇总与明细。
  final SportsAttendanceSummary summary;

  const SportsAttendanceDetailPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('课外活动考勤记录'),
        commandBar: FluentButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ),
      children: [
        _SportsAttendanceSummaryPanel(summary: summary),
        const SizedBox(height: FluentSpacing.m),
        _SportsAttendanceRecordsPanel(summary: summary),
      ],
    );
  }
}

class _SportsAttendanceSummaryPanel extends StatelessWidget {
  const _SportsAttendanceSummaryPanel({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('汇总表', style: FluentTheme.of(context).typography.bodyStrong),
            const SizedBox(height: FluentSpacing.m),
            _AdaptiveSportsAttendanceTable(
              minWidth: 640,
              child: _SportsAttendanceTable(
                headers: const ['总次数', '晨跑次数', '课外活动', '体育长廊', '次数调整', '明细条数'],
                rows: [
                  [
                    '${summary.totalCount} 次',
                    '${summary.morningExerciseCount} 次',
                    '${summary.extracurricularActivityCount} 次',
                    '${summary.sportsCorridorCount} 次',
                    '${summary.countAdjustmentCount} 次',
                    '${summary.records.length} 条',
                  ],
                ],
                centerColumns: const {0, 1, 2, 3, 4, 5},
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                  3: FlexColumnWidth(),
                  4: FlexColumnWidth(),
                  5: FlexColumnWidth(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportsAttendanceRecordsPanel extends StatelessWidget {
  const _SportsAttendanceRecordsPanel({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.records.isEmpty) {
      return const FluentInfoBar(
        title: Text('暂无明细记录'),
        content: Text('体育部页面返回了汇总次数，但没有可展示的考勤明细。'),
        severity: FluentInfoSeverity.info,
      );
    }

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('明细表', style: FluentTheme.of(context).typography.bodyStrong),
            const SizedBox(height: FluentSpacing.m),
            _AdaptiveSportsAttendanceTable(
              minWidth: 860,
              child: _SportsAttendanceTable(
                headers: const ['类别', '日期/时间', '项目', '地点', '备注', '次数', '原始记录'],
                rows: [
                  for (final record in summary.records)
                    [
                      record.category.label,
                      record.occurredAt ?? '',
                      record.project ?? '',
                      record.location ?? '',
                      record.remark ?? '',
                      '${record.count} 次',
                      record.cells.join(' / '),
                    ],
                ],
                centerColumns: const {0, 5},
                columnWidths: const {
                  0: FlexColumnWidth(1.05),
                  1: FlexColumnWidth(1.45),
                  2: FlexColumnWidth(1.12),
                  3: FlexColumnWidth(1.12),
                  4: FlexColumnWidth(1.25),
                  5: FlexColumnWidth(0.84),
                  6: FlexColumnWidth(2.65),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveSportsAttendanceTable extends StatelessWidget {
  const _AdaptiveSportsAttendanceTable({
    required this.minWidth,
    required this.child,
  });

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: tableWidth, child: child),
        );
      },
    );
  }
}

class _SportsAttendanceTable extends StatelessWidget {
  const _SportsAttendanceTable({
    required this.headers,
    required this.rows,
    this.centerColumns = const {},
    this.columnWidths,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final Set<int> centerColumns;
  final Map<int, TableColumnWidth>? columnWidths;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: context.fluentColors.neutralStroke1),
      columnWidths:
          columnWidths ??
          {
            for (var index = 0; index < headers.length; index++)
              index: const FlexColumnWidth(),
          },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.resources.controlAltFillColorSecondary,
          ),
          children: [
            for (var index = 0; index < headers.length; index++)
              _SportsAttendanceTableCell(
                headers[index],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (var index = 0; index < headers.length; index++)
                _SportsAttendanceTableCell(
                  index < row.length ? row[index] : '',
                  alignCenter: centerColumns.contains(index),
                ),
            ],
          ),
      ],
    );
  }
}

class _SportsAttendanceTableCell extends StatelessWidget {
  const _SportsAttendanceTableCell(
    this.text, {
    this.header = false,
    this.alignCenter = false,
  });

  final String text;
  final bool header;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = header ? theme.typography.bodyStrong : theme.typography.body;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.s,
      ),
      child: Text(
        _sportsAttendanceEmptyAsDash(text),
        textAlign: alignCenter ? TextAlign.center : TextAlign.start,
        style: style?.copyWith(fontWeight: header ? FontWeight.w700 : null),
      ),
    );
  }
}

String _sportsAttendanceEmptyAsDash(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}
