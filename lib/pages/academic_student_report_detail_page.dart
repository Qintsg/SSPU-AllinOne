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
    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('第二课堂详情'),
        commandBar: FluentButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ),
      children: [
        _SecondClassroomTotalsPanel(summary: summary),
        const SizedBox(height: FluentSpacing.m),
        _SecondClassroomDetailRecordsPanel(summary: summary),
        const SizedBox(height: FluentSpacing.m),
        _SecondClassroomRuleMatrix(summary: summary),
      ],
    );
  }
}

class _SecondClassroomTotalsPanel extends StatelessWidget {
  const _SecondClassroomTotalsPanel({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final categories = _categoryProgressList(summary);
    return LayoutBuilder(
      builder: (context, constraints) {
        return _SecondClassroomCompactSummary(
          summary: summary,
          categories: categories,
          title: '总计',
          minCategoryWidth: constraints.maxWidth < 640 ? 136 : 156,
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
    final details = widget.summary.detailRecords;
    const headers = ['名称', '类别', '项目', '等级', '参与情况', '获得积分'];
    if (details.isNotEmpty) {
      return _CollapsibleReportRowsPanel(
        title: '已获积分详情',
        expanded: _expanded,
        onToggle: _toggleExpanded,
        minTableWidth: 840,
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
        minTableWidth: 760,
        headers: headers,
        rows: const [],
        emptyMessage: '暂无已获积分详情。',
      );
    }

    return _CollapsibleReportRowsPanel(
      title: '已获积分详情',
      expanded: _expanded,
      onToggle: _toggleExpanded,
      minTableWidth: 760,
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
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CollapsiblePanelHeader(
              title: title,
              expanded: expanded,
              onToggle: onToggle,
            ),
            if (expanded) ...[
              const SizedBox(height: FluentSpacing.m),
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
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FluentIconButton(
          key: const Key('academic-student-report-detail-collapse'),
          icon: Icon(
            expanded ? FluentIcons.chevronDown : FluentIcons.chevronRight,
          ),
          tooltip: expanded ? '收起已获积分详情' : '展开已获积分详情',
          size: 28,
          iconSize: 16,
          onPressed: onToggle,
        ),
        const SizedBox(width: FluentSpacing.xs),
        Text(title, style: theme.typography.bodyStrong),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
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
    final theme = FluentTheme.of(context);
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: _reportTableBorderColor(context)),
      columnWidths: {
        for (var index = 0; index < headers.length; index++)
          index: _columnWidthFor(index),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.resources.controlAltFillColorSecondary,
          ),
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

  TableColumnWidth _columnWidthFor(int index) {
    if (headers.length == 6) {
      return switch (index) {
        0 => const FlexColumnWidth(1.5),
        1 || 2 => const FixedColumnWidth(132),
        3 || 4 => const FixedColumnWidth(116),
        5 => const FixedColumnWidth(104),
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
    final borderColor = _reportTableBorderColor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(context.fluentRadii.medium),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _ReportRecordListItem(headers: headers, row: rows[index]),
            if (index != rows.length - 1)
              Container(height: 1, color: borderColor),
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
    final theme = FluentTheme.of(context);
    final title = row.isEmpty ? '-' : _emptyAsDash(row.first);
    return Padding(
      padding: const EdgeInsets.all(FluentSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.s),
          Wrap(
            spacing: FluentSpacing.l,
            runSpacing: FluentSpacing.s,
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
    final theme = FluentTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: FluentSpacing.xxs),
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
    final theme = FluentTheme.of(context);
    final baseStyle = header
        ? theme.typography.bodyStrong
        : theme.typography.body;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.s,
      ),
      child: Text(
        _emptyAsDash(text),
        textAlign: alignCenter ? TextAlign.center : TextAlign.start,
        style: baseStyle?.copyWith(fontWeight: header ? FontWeight.w700 : null),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      message,
      style: theme.typography.caption?.copyWith(
        color: theme.resources.textFillColorSecondary,
      ),
    );
  }
}

Color _reportTableBorderColor(BuildContext context) {
  return context.fluentColors.neutralStroke1;
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.typography.bodyStrong),
            const SizedBox(height: FluentSpacing.s),
            Text(
              message,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
