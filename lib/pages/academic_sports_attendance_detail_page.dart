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
  /// 最近一次体育考勤查询结果；加载首帧可为空。
  final SportsAttendanceQueryResult? result;

  /// 兼容旧路由的已读取汇总。
  final SportsAttendanceSummary? summary;

  /// 是否正在读取体育考勤详情。
  final bool isLoading;

  const SportsAttendanceDetailPage({
    super.key,
    this.result,
    this.summary,
    this.isLoading = false,
  }) : assert(result != null || summary != null || isLoading);

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final summary = result?.summary ?? this.summary;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '课外活动考勤记录',
        leading: YhButton(
          label: '返回',
          leadingIcon: YhIcons.back,
          variant: YhButtonVariant.text,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(context, theme, summary),
    );
  }

  Widget _buildBody(
    BuildContext context,
    YhTheme theme,
    SportsAttendanceSummary? summary,
  ) {
    if (isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.spacing.xl2 * 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const YhProgress(showPercent: false, semanticLabel: '正在读取体育考勤详情'),
              SizedBox(height: theme.spacing.m),
              Text('正在读取体育考勤详情...', style: theme.typography.body),
            ],
          ),
        ),
      );
    }

    final current = result;
    if ((current != null && !current.isSuccess) || summary == null) {
      return YhEmptyState(
        icon: YhIcons.warning,
        title: current?.message ?? '尚未读取体育考勤详情',
        message: current?.detail ?? '返回教务中心刷新体育考勤后再试。',
        action: YhButton(
          label: '返回教务中心刷新',
          leadingIcon: YhIcons.back,
          variant: YhButtonVariant.secondary,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    if (summary.totalCount == 0 && summary.records.isEmpty) {
      return YhEmptyState(
        icon: YhIcons.sports,
        title: '暂无体育考勤记录',
        message: '当前查询没有可展示的汇总或明细；返回教务中心刷新后可再次查看。',
        action: YhButton(
          label: '返回教务中心刷新',
          leadingIcon: YhIcons.back,
          variant: YhButtonVariant.secondary,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final showCacheNotice = current?.message.contains('缓存') ?? false;
    return SingleChildScrollView(
      padding: EdgeInsets.all(theme.spacing.m),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.breakpoint.expanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCacheNotice) ...[
                YhBanner(text: current!.detail, kind: YhBannerKind.warn),
                SizedBox(height: theme.spacing.m),
              ],
              _SportsAttendanceSummaryPanel(summary: summary),
              SizedBox(height: theme.spacing.m),
              _SportsAttendanceRecordsPanel(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportsAttendanceSummaryPanel extends StatelessWidget {
  const _SportsAttendanceSummaryPanel({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('汇总表', style: theme.typography.h3),
          SizedBox(height: theme.spacing.m),
          _AdaptiveSportsAttendanceTable(
            minWidth: theme.breakpoint.compact + theme.control.compact,
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
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('明细表', style: theme.typography.h3),
          SizedBox(height: theme.spacing.m),
          _AdaptiveSportsAttendanceTable(
            minWidth:
                theme.breakpoint.medium +
                theme.spacing.xl2 +
                theme.spacing.m +
                theme.spacing.l +
                theme.spacing.xs,
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
    final theme = context.yhTheme;
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: theme.color.border),
      columnWidths:
          columnWidths ??
          {
            for (var index = 0; index < headers.length; index++)
              index: const FlexColumnWidth(),
          },
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.color.sunken),
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
    final theme = context.yhTheme;
    final style = theme.typography.body.copyWith(
      fontWeight: header ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.s,
      ),
      child: Text(
        _sportsAttendanceEmptyAsDash(text),
        textAlign: alignCenter ? TextAlign.center : TextAlign.start,
        style: style,
      ),
    );
  }
}

String _sportsAttendanceEmptyAsDash(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}
