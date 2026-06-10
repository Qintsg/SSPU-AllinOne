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
    final theme = FluentTheme.of(context);
    final totals = summary.totals;
    final categories = _categoryProgressList(summary);
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总计', style: theme.typography.bodyStrong),
            const SizedBox(height: FluentSpacing.s),
            Wrap(
              spacing: FluentSpacing.xl,
              runSpacing: FluentSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _InlineMetric(
                  label: '总积分',
                  value: _formatNullableCredit(totals?.totalCredit),
                ),
                _InlineMetric(
                  label: '总已获分数',
                  value: _formatNullableCredit(totals?.totalEarnedCredit),
                ),
                _InlineMetric(
                  label: '总必修积分',
                  value: _formatNullableCredit(totals?.totalRequiredCredit),
                ),
                _InlineMetric(
                  label: '总体通过情况',
                  value: _emptyAsUnread(totals?.passStatus),
                  valueColor: _statusTextColor(context, totals?.passStatus),
                ),
                _InlineMetric(
                  label: '详情记录',
                  value: '${_detailCount(summary)} 项',
                ),
              ],
            ),
            const SizedBox(height: FluentSpacing.m),
            Wrap(
              spacing: FluentSpacing.l,
              runSpacing: FluentSpacing.s,
              children: [
                for (final category in categories)
                  _InlineMetric(
                    label: category.label,
                    value: category.displayValue,
                    valueColor: _statusTextColor(context, category.status),
                  ),
              ],
            ),
            if (summary.warning != null) ...[
              const SizedBox(height: FluentSpacing.s),
              _SecondClassroomWarningText(summary.warning!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.typography.bodyStrong?.copyWith(color: valueColor),
        ),
        const SizedBox(height: FluentSpacing.xxs),
        Text(
          label,
          style: theme.typography.caption?.copyWith(
            color: theme.resources.textFillColorSecondary,
          ),
        ),
      ],
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

class _SecondClassroomRuleMatrix extends StatelessWidget {
  const _SecondClassroomRuleMatrix({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final rules = summary.rules;
    if (rules.isEmpty) {
      return const _EmptyPanel(title: '规则矩阵', message: '暂无规则矩阵，等待下次刷新补全。');
    }
    return _ReportTablePanel(
      title: '规则矩阵',
      minTableWidth: 980,
      headers: const ['类别', '项目', '等级', '参与情况', '积分', '已获积分', '必修积分', '通过情况'],
      rows: [
        for (final rule in rules)
          [
            rule.category,
            rule.item,
            rule.level,
            rule.participation,
            _formatNullableCredit(rule.credit),
            _formatNullableCredit(rule.earnedCredit),
            _formatNullableCredit(rule.requiredCredit),
            rule.passStatus,
          ],
      ],
      statusColumnIndex: 7,
    );
  }
}

class _ReportTablePanel extends StatelessWidget {
  const _ReportTablePanel({
    required this.title,
    required this.headers,
    required this.rows,
    required this.minTableWidth,
    this.statusColumnIndex,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final double minTableWidth;
  final int? statusColumnIndex;

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
                  foreground: index == statusColumnIndex
                      ? _statusTextColor(
                          context,
                          index < row.length ? row[index] : '',
                        )
                      : null,
                  bold: index == statusColumnIndex,
                ),
            ],
          ),
      ],
    );
  }

  TableColumnWidth _columnWidthFor(int index) {
    if (headers.length == 8) {
      return switch (index) {
        0 => const FixedColumnWidth(124),
        1 => const FixedColumnWidth(156),
        2 => const FixedColumnWidth(124),
        3 => const FlexColumnWidth(1.35),
        4 || 5 || 6 => const FixedColumnWidth(92),
        7 => const FixedColumnWidth(112),
        _ => const FlexColumnWidth(),
      };
    }
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
    this.foreground,
    this.bold = false,
  });

  final String text;
  final bool header;
  final bool alignCenter;
  final Color? foreground;
  final bool bold;

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
        style: baseStyle?.copyWith(
          color: foreground,
          fontWeight: bold || header ? FontWeight.w700 : null,
        ),
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
