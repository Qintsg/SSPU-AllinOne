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
          showTotalCredit: true,
          minCategoryWidth: constraints.maxWidth < 640 ? 136 : 156,
        );
      },
    );
  }
}

class _SecondClassroomDetailRecordsPanel extends StatelessWidget {
  const _SecondClassroomDetailRecordsPanel({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final details = summary.detailRecords;
    if (details.isNotEmpty) {
      return _ReportTablePanel(
        title: '已获积分详情',
        minTableWidth: 840,
        headers: const ['名称', '类别', '项目', '等级', '参与情况', '获得积分'],
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

    if (summary.records.isEmpty) {
      return const _EmptyPanel(title: '已获积分详情', message: '暂无已获积分详情。');
    }

    return _ReportTablePanel(
      title: '已获积分详情',
      minTableWidth: 760,
      headers: const ['名称', '类别', '项目', '等级', '参与情况', '获得积分'],
      rows: [
        for (final record in summary.records)
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
}

class _ReportTablePanel extends StatelessWidget {
  const _ReportTablePanel({
    required this.title,
    required this.headers,
    required this.rows,
    required this.minTableWidth,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final double minTableWidth;

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
            const SizedBox(height: FluentSpacing.m),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < minTableWidth
                          ? minTableWidth
                          : constraints.maxWidth,
                    ),
                    child: _buildTable(context),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final theme = FluentTheme.of(context);
    final borderSide = BorderSide(
      color: theme.resources.cardStrokeColorDefault,
    );
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: borderSide.color),
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
