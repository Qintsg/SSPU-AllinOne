/*
 * 第二课堂详情页 — 展示积分详情与规则矩阵
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

part of 'academic_page.dart';

/// 第二课堂得分明细二级页面。
class StudentReportDetailPage extends StatelessWidget {
  /// 已读取的第二课堂学分汇总与明细。
  final SecondClassroomCreditSummary summary;

  const StudentReportDetailPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '第二课堂详情',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.expanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SecondClassroomTotalsPanel(summary: summary),
                SizedBox(height: theme.spacing.m),
                _SecondClassroomDetailRecordsPanel(summary: summary),
                SizedBox(height: theme.spacing.m),
                _SecondClassroomRuleMatrix(summary: summary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondClassroomTotalsPanel extends StatelessWidget {
  const _SecondClassroomTotalsPanel({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final categories = _categoryProgressList(summary);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth <
            theme.breakpoint.compact + theme.control.compact;
        return _SecondClassroomCompactSummary(
          summary: summary,
          categories: categories,
          title: '总计',
          metricMinWidth: narrow
              ? theme.spacing.xl2 * 2
              : theme.spacing.xl2 * 2 + theme.spacing.m,
          categoryColumns: narrow ? 1 : 2,
        );
      },
    );
  }
}

class _SecondClassroomDetailRecordsPanel extends StatefulWidget {
  const _SecondClassroomDetailRecordsPanel({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  State<_SecondClassroomDetailRecordsPanel> createState() =>
      _SecondClassroomDetailRecordsPanelState();
}

class _SecondClassroomDetailRecordsPanelState
    extends State<_SecondClassroomDetailRecordsPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final details = widget.summary.detailRecords;
    const headers = ['名称', '类别', '项目', '等级', '参与情况', '获得积分'];
    if (details.isNotEmpty) {
      return _CollapsibleReportRowsPanel(
        title: '已获积分详情',
        expanded: _expanded,
        onToggle: _toggleExpanded,
        minTableWidth:
            theme.breakpoint.medium + theme.spacing.xl2 + theme.spacing.l,
        headers: headers,
        rows: [
          for (final detail in details)
            [
              detail.name,
              detail.category,
              detail.item,
              detail.level,
              detail.participation,
              _formatNullableCredit(detail.earnedCredit),
            ],
        ],
      );
    }

    if (widget.summary.records.isEmpty) {
      return _CollapsibleReportRowsPanel(
        title: '已获积分详情',
        expanded: _expanded,
        onToggle: _toggleExpanded,
        minTableWidth: theme.breakpoint.medium - theme.spacing.s,
        headers: headers,
        rows: const [],
        emptyMessage: '暂无已获积分详情。',
      );
    }

    return _CollapsibleReportRowsPanel(
      title: '已获积分详情',
      expanded: _expanded,
      onToggle: _toggleExpanded,
      minTableWidth: theme.breakpoint.medium - theme.spacing.s,
      headers: headers,
      rows: [
        for (final record in widget.summary.records)
          [
            record.itemName,
            record.category,
            '',
            '',
            record.status ?? '',
            _formatCredit(record.credit),
          ],
      ],
    );
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }
}

class _CollapsibleReportRowsPanel extends StatelessWidget {
  const _CollapsibleReportRowsPanel({
    required this.title,
    required this.headers,
    required this.rows,
    required this.minTableWidth,
    required this.expanded,
    required this.onToggle,
    this.emptyMessage,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final double minTableWidth;
  final bool expanded;
  final VoidCallback onToggle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CollapsiblePanelHeader(
            title: title,
            expanded: expanded,
            onToggle: onToggle,
          ),
          if (expanded) ...[
            SizedBox(height: theme.spacing.m),
            if (rows.isEmpty)
              _InlineEmptyState(message: emptyMessage ?? '暂无数据。')
            else
              _ResponsiveReportRows(
                headers: headers,
                rows: rows,
                minTableWidth: minTableWidth,
              ),
          ],
        ],
      ),
    );
  }
}

class _CollapsiblePanelHeader extends StatelessWidget {
  const _CollapsiblePanelHeader({
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        YhTooltip(
          message: expanded ? '收起已获积分详情' : '展开已获积分详情',
          child: AnimatedRotation(
            turns: expanded ? 0.25 : 0,
            duration: theme.motion.base,
            curve: theme.motion.curve,
            child: YhIconButton(
              key: const Key('academic-student-report-detail-collapse'),
              icon: YhIcons.chevronRight,
              semanticLabel: expanded ? '收起已获积分详情' : '展开已获积分详情',
              variant: YhIconButtonVariant.ghost,
              onTap: onToggle,
            ),
          ),
        ),
        SizedBox(width: theme.spacing.xs),
        Text(title, style: theme.typography.h3),
      ],
    );
  }
}

class _ResponsiveReportRows extends StatelessWidget {
  const _ResponsiveReportRows({
    required this.headers,
    required this.rows,
    required this.minTableWidth,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final double minTableWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            theme.breakpoint.compact + theme.control.compact) {
          return _ReportRecordList(headers: headers, rows: rows);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth,
            ),
            child: _ReportDesktopTable(headers: headers, rows: rows),
          ),
        );
      },
    );
  }
}

class _ReportDesktopTable extends StatelessWidget {
  const _ReportDesktopTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: _reportTableBorderColor(context)),
      columnWidths: {
        for (var index = 0; index < headers.length; index++)
          index: _columnWidthFor(index, theme),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.color.sunken),
          children: [
            for (final header in headers)
              _TableCellText(header, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (var index = 0; index < headers.length; index++)
                _TableCellText(
                  index < row.length ? row[index] : '',
                  alignCenter: index >= 2,
                ),
            ],
          ),
      ],
    );
  }

  TableColumnWidth _columnWidthFor(int index, YhTheme theme) {
    if (headers.length == 6) {
      return switch (index) {
        0 => const FlexColumnWidth(1.5),
        1 || 2 => FixedColumnWidth(
          theme.control.regular * 3 - theme.spacing.s - theme.spacing.xs,
        ),
        3 ||
        4 => FixedColumnWidth(theme.control.compact * 3 - theme.spacing.xs),
        5 => FixedColumnWidth(theme.spacing.xl2 * 2 + theme.spacing.s),
        _ => const FlexColumnWidth(),
      };
    }
    return const IntrinsicColumnWidth();
  }
}

class _ReportRecordList extends StatelessWidget {
  const _ReportRecordList({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final borderColor = _reportTableBorderColor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _ReportRecordListItem(headers: headers, row: rows[index]),
            if (index != rows.length - 1)
              Container(height: theme.layout.divider, color: borderColor),
          ],
        ],
      ),
    );
  }
}

class _ReportRecordListItem extends StatelessWidget {
  const _ReportRecordListItem({required this.headers, required this.row});

  final List<String> headers;
  final List<String> row;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final title = row.isEmpty ? '-' : _emptyAsDash(row.first);
    return Padding(
      padding: EdgeInsets.all(theme.spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing.s),
          Wrap(
            spacing: theme.spacing.l,
            runSpacing: theme.spacing.s,
            children: [
              for (var index = 1; index < headers.length; index++)
                _ReportRecordField(
                  label: headers[index],
                  value: index < row.length ? row[index] : '',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportRecordField extends StatelessWidget {
  const _ReportRecordField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: theme.spacing.xl2 * 2,
        maxWidth:
            theme.breakpoint.compact / 3 + theme.spacing.m + theme.spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(_emptyAsDash(value), style: theme.typography.body),
        ],
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  const _TableCellText(
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.s,
      ),
      child: Text(
        _emptyAsDash(text),
        textAlign: alignCenter ? TextAlign.center : TextAlign.start,
        style: theme.typography.body.copyWith(
          fontWeight: header ? FontWeight.w700 : null,
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Text(
      message,
      style: theme.typography.caption.copyWith(color: theme.color.muted),
    );
  }
}

Color _reportTableBorderColor(BuildContext context) {
  return context.yhTheme.color.border;
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          Text(
            message,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}
