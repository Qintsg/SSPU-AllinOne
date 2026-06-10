/*
 * 教务中心第二课堂学分卡片 — 展示学工报表只读查询结果
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'academic_page.dart';

/// 教务中心第二课堂学分卡片。
class AcademicStudentReportCard extends StatelessWidget {
  /// 最近一次学工报表查询结果。
  final StudentReportQueryResult? result;

  /// 当前是否正在读取学工报表系统。
  final bool isLoading;

  /// 是否已开启自动刷新。
  final bool autoRefreshEnabled;

  /// 手动刷新回调。
  final VoidCallback onRefresh;

  const AcademicStudentReportCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final summary = result?.summary;

    return FluentSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FluentSectionHeader(
            title: '第二课堂学分',
            subtitle: '数据来自学工报表系统，通过 OA 登录态只读读取第二课堂学分。',
            icon: FluentIcons.education,
          ),
          const SizedBox(height: FluentSpacing.l),
          if (isLoading) ...[
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取第二课堂学分...'),
              ],
            ),
          ] else if (result == null) ...[
            Text(
              autoRefreshEnabled
                  ? '自动刷新已开启，等待下一次读取；也可点击右上角刷新。'
                  : '自动刷新未开启。点击右上角刷新图标可手动读取；学工报表需要校园网或学校 VPN。',
            ),
          ] else if (result!.isSuccess && summary != null) ...[
            _SecondClassroomSummaryView(summary: summary),
          ] else ...[
            FluentInfoBar(
              title: Text(result!.message),
              content: Text(result!.detail),
              severity: _studentReportSeverity(result!.status),
            ),
          ],
          const SizedBox(height: FluentSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: FluentSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _studentReportLastRefreshLabel(result),
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                FluentIconButton(
                  key: const Key('academic-student-report-refresh'),
                  tooltip: '手动刷新第二课堂学分',
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: FluentProgressRing(strokeWidth: 2),
                        )
                      : const Icon(FluentIcons.refresh),
                  onPressed: isLoading ? null : onRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FluentInfoSeverity _studentReportSeverity(StudentReportQueryStatus status) {
    return switch (status) {
      StudentReportQueryStatus.success => FluentInfoSeverity.success,
      StudentReportQueryStatus.missingOaAccount ||
      StudentReportQueryStatus.missingOaPassword ||
      StudentReportQueryStatus.campusNetworkUnavailable =>
        FluentInfoSeverity.warning,
      StudentReportQueryStatus.oaLoginRequired ||
      StudentReportQueryStatus.reportSystemUnavailable ||
      StudentReportQueryStatus.secondClassroomEntryUnavailable ||
      StudentReportQueryStatus.parseFailed ||
      StudentReportQueryStatus.networkError ||
      StudentReportQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
  }

  String _studentReportLastRefreshLabel(StudentReportQueryResult? result) {
    final checkedAt = result?.checkedAt;
    if (checkedAt == null) return '上次刷新：未刷新';
    return '上次刷新：${checkedAt.year.toString().padLeft(4, '0')}-'
        '${checkedAt.month.toString().padLeft(2, '0')}-'
        '${checkedAt.day.toString().padLeft(2, '0')} '
        '${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}

class _SecondClassroomSummaryView extends StatelessWidget {
  const _SecondClassroomSummaryView({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final totals = summary.totals;
    final earned = totals?.totalEarnedCredit;
    final required = totals?.totalRequiredCredit;
    final status = totals?.passStatus;
    final detailCount = summary.detailRecords.isNotEmpty
        ? summary.detailRecords.length
        : summary.records.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: FluentSpacing.m,
          runSpacing: FluentSpacing.s,
          children: [
            _SummaryMetric(
              label: '已获分数',
              value: earned == null ? '未读取' : _formatCredit(earned),
            ),
            _SummaryMetric(
              label: '必修积分',
              value: required == null ? '未读取' : _formatCredit(required),
            ),
            _SummaryMetric(label: '通过情况', value: _emptyAsUnread(status)),
            _SummaryMetric(label: '详情记录', value: '$detailCount 项'),
          ],
        ),
        if (summary.warning != null) ...[
          const SizedBox(height: FluentSpacing.s),
          Text(
            summary.warning!,
            style: theme.typography.caption?.copyWith(
              color: context.fluentColors.statusWarningForeground,
            ),
          ),
        ],
        const SizedBox(height: FluentSpacing.m),
        Text(
          summary.rules.isEmpty
              ? '显示学工报表返回的已获分数详情；旧缓存将自动等待下次刷新补全规则矩阵。'
              : '已读取规则矩阵、总计和已获分数详情。',
          style: theme.typography.caption?.copyWith(
            color: theme.resources.textFillColorSecondary,
          ),
        ),
        const SizedBox(height: FluentSpacing.l),
        FluentButton.primary(
          onPressed: () => Navigator.of(context).push(
            FluentPageRoute(
              builder: (_) => StudentReportDetailPage(summary: summary),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.list, size: 14),
              SizedBox(width: 6),
              Text('查看第二课堂详情'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 116),
      child: FluentCard(
        bordered: true,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: FluentSpacing.m,
          vertical: FluentSpacing.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.typography.bodyLarge?.copyWith(
                color: theme.accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FluentSpacing.xxs),
            Text(
              label,
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
        _SecondClassroomRuleMatrix(summary: summary),
        const SizedBox(height: FluentSpacing.m),
        _SecondClassroomDetailRecordsPanel(summary: summary),
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
              spacing: FluentSpacing.l,
              runSpacing: FluentSpacing.s,
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
                ),
                _InlineMetric(
                  label: '详情记录',
                  value: '${_detailCount(summary)} 项',
                ),
              ],
            ),
            if (summary.warning != null) ...[
              const SizedBox(height: FluentSpacing.s),
              Text(
                summary.warning!,
                style: theme.typography.caption?.copyWith(
                  color: context.fluentColors.statusWarningForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.typography.bodyStrong?.copyWith(
            color: theme.accentColor,
          ),
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

class _SecondClassroomRuleMatrix extends StatelessWidget {
  const _SecondClassroomRuleMatrix({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final rules = summary.rules;
    if (rules.isEmpty) {
      return _EmptyPanel(title: '规则矩阵', message: '暂无规则矩阵，等待下次刷新补全。');
    }
    return _ResponsiveDataPanel(
      title: '规则矩阵',
      minTableWidth: 900,
      headers: const ['类别', '项目', '等级', '参与情况', '积分', '已获分数', '必修积分', '通过情况'],
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
      return _ResponsiveDataPanel(
        title: '已获分数详情',
        minTableWidth: 760,
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
      return _EmptyPanel(title: '已获分数详情', message: '暂无已获分数详情。');
    }

    return _ResponsiveDataPanel(
      title: '已获分数详情',
      minTableWidth: 720,
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

class _ResponsiveDataPanel extends StatelessWidget {
  const _ResponsiveDataPanel({
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
                final compact = constraints.maxWidth < 720;
                if (compact) return _buildStackedRows(context);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minTableWidth),
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
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: theme.resources.cardStrokeColorDefault,
        ),
      ),
      columnWidths: {
        for (var index = 0; index < headers.length; index++)
          index: const IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.resources.subtleFillColorTertiary,
          ),
          children: [
            for (final header in headers) _TableCellText(header, header: true),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (var index = 0; index < headers.length; index++)
                _TableCellText(index < row.length ? row[index] : ''),
            ],
          ),
      ],
    );
  }

  Widget _buildStackedRows(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: FluentSpacing.s),
            child: FluentCard(
              bordered: true,
              elevated: false,
              padding: const EdgeInsets.all(FluentSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < headers.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : FluentSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headers[index],
                            style: theme.typography.caption?.copyWith(
                              color: theme.resources.textFillColorSecondary,
                            ),
                          ),
                          const SizedBox(height: FluentSpacing.xxs),
                          Text(
                            index < row.length ? _emptyAsDash(row[index]) : '-',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TableCellText extends StatelessWidget {
  const _TableCellText(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.s,
      ),
      child: Text(
        _emptyAsDash(text),
        style: header
            ? theme.typography.caption?.copyWith(fontWeight: FontWeight.w700)
            : null,
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

int _detailCount(SecondClassroomCreditSummary summary) {
  return summary.detailRecords.isNotEmpty
      ? summary.detailRecords.length
      : summary.records.length;
}

String _formatNullableCredit(double? credit) {
  return credit == null ? '-' : _formatCredit(credit);
}

String _formatCredit(double credit) {
  final text = credit.toStringAsFixed(2);
  return text
      .replaceFirst(RegExp(r'\.0+$'), '')
      .replaceFirst(RegExp(r'0$'), '');
}

String _emptyAsUnread(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '未读取' : normalized;
}

String _emptyAsDash(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '-' : normalized;
}
