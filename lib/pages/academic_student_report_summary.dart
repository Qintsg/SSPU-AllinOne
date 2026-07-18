/*
 * 教务中心第二课堂摘要 — 首页卡片总览和类别进度
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_summary.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

part of 'academic_page.dart';

class _SecondClassroomSummaryView extends StatelessWidget {
  const _SecondClassroomSummaryView({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final categories = _categoryProgressList(summary);
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    return _SecondClassroomCompactSummary(
      summary: summary,
      categories: categories,
      metricMinWidth: compact
          ? theme.spacing.xl2 * 2
          : theme.spacing.xl2 * 2 + theme.spacing.m,
      categoryColumns: compact ? 1 : 2,
    );
  }
}

class _SecondClassroomCompactSummary extends StatelessWidget {
  const _SecondClassroomCompactSummary({
    required this.summary,
    required this.categories,
    required this.metricMinWidth,
    required this.categoryColumns,
    this.title,
  });

  final SecondClassroomCreditSummary summary;
  final List<_CategoryProgress> categories;
  final double metricMinWidth;
  final int categoryColumns;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final totals = summary.totals;
    final theme = context.yhTheme;
    final status = totals?.passStatus;
    final metrics = [
      _SummaryMetric(
        label: '总已获分数',
        value: _formatNullableCredit(totals?.totalEarnedCredit),
        emphasized: true,
      ),
      _SummaryMetric(
        label: '总必修积分',
        value: _formatNullableCredit(totals?.totalRequiredCredit),
      ),
      _SummaryMetric(
        label: '总体通过情况',
        value: _emptyAsUnread(status),
        valueColor: _statusTextColor(context, status),
      ),
      _SummaryMetric(label: '详情记录', value: '${_detailCount(summary)} 项'),
    ];
    return DecoratedBox(
      decoration: _summaryPanelDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.typography.h3),
              SizedBox(height: theme.spacing.s),
            ],
            _SummaryMetricWrap(metrics: metrics, minWidth: metricMinWidth),
            SizedBox(height: theme.spacing.s),
            Container(height: theme.layout.divider, color: theme.color.border),
            SizedBox(height: theme.spacing.s),
            _CategoryProgressStrip(
              categories: categories,
              columnCount: categoryColumns,
            ),
            if (summary.warning != null) ...[
              SizedBox(height: theme.spacing.s),
              _SecondClassroomWarningText(summary.warning!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricWrap extends StatelessWidget {
  const _SummaryMetricWrap({required this.metrics, required this.minWidth});

  final List<_SummaryMetric> metrics;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.l,
      runSpacing: theme.spacing.s,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final metric in metrics)
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: metric,
          ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
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
          style: (emphasized ? theme.typography.h2 : theme.typography.body)
              .copyWith(
                color:
                    valueColor ?? (emphasized ? theme.color.brandStrong : null),
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

class _CategoryProgressStrip extends StatelessWidget {
  const _CategoryProgressStrip({
    required this.categories,
    required this.columnCount,
  });

  final List<_CategoryProgress> categories;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final effectiveColumnCount = categories.isEmpty
        ? 1
        : columnCount.clamp(1, categories.length).toInt();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var columnIndex = 0;
          columnIndex < effectiveColumnCount;
          columnIndex++
        ) ...[
          if (columnIndex > 0) SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              children: [
                for (
                  var itemIndex = columnIndex;
                  itemIndex < categories.length;
                  itemIndex += effectiveColumnCount
                ) ...[
                  if (itemIndex != columnIndex)
                    SizedBox(height: theme.spacing.s),
                  _CategoryProgressPill(category: categories[itemIndex]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryProgressPill extends StatelessWidget {
  const _CategoryProgressPill({required this.category});

  final _CategoryProgress category;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final textColor = _categoryColor(context, category.status);
    final borderColor = textColor.withValues(alpha: 0.48);
    final backgroundColor = _isFailStatus(category.status)
        ? theme.color.dangerTint
        : _isPassStatus(category.status)
        ? theme.color.successTint
        : theme.color.sunken;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.s,
          vertical: theme.spacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: _CategoryProgressLabel(
                text: category.label,
                color: textColor,
              ),
            ),
            SizedBox(width: theme.spacing.s),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _CategoryProgressValue(
                  text: category.displayValue,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryProgressLabel extends StatelessWidget {
  const _CategoryProgressLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.visible,
      style: theme.typography.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CategoryProgressValue extends StatelessWidget {
  const _CategoryProgressValue({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        style: theme.typography.body.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

BoxDecoration _summaryPanelDecoration(BuildContext context) {
  final theme = context.yhTheme;
  return BoxDecoration(
    color: theme.color.sunken,
    borderRadius: BorderRadius.circular(theme.radius.m),
    border: Border.all(color: theme.color.border),
  );
}

class _SecondClassroomWarningText extends StatelessWidget {
  const _SecondClassroomWarningText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Text(
      message,
      style: theme.typography.caption.copyWith(color: theme.color.warning),
    );
  }
}

class _CategoryProgress {
  const _CategoryProgress({
    required this.label,
    required this.earned,
    required this.required,
    required this.status,
  });

  final String label;
  final double? earned;
  final double? required;
  final String status;

  String get displayValue {
    if (earned == null && required == null) return '-';
    return '${_formatFixedCredit(earned)}/${_formatFixedCredit(required)}';
  }
}

List<_CategoryProgress> _categoryProgressList(
  SecondClassroomCreditSummary summary,
) {
  const targets = ['社会实践', '报告与讲座', '校园文化活动', '创新创业活动'];
  return [
    for (final target in targets) _categoryProgress(summary.rules, target),
  ];
}

_CategoryProgress _categoryProgress(
  List<SecondClassroomCreditRuleRow> rules,
  String target,
) {
  final matched = rules
      .where((rule) => _categoryMatches(rule.category, target))
      .toList();
  return _CategoryProgress(
    label: target,
    earned: _sumNumbers(matched.map((rule) => rule.earnedCredit)),
    required: _representativeNumber(matched.map((rule) => rule.requiredCredit)),
    status: _representativeStatus(matched.map((rule) => rule.passStatus)),
  );
}

double? _sumNumbers(Iterable<double?> values) {
  var hasValue = false;
  var total = 0.0;
  for (final value in values.whereType<double>()) {
    hasValue = true;
    total += value;
  }
  return hasValue ? total : null;
}

double? _representativeNumber(Iterable<double?> values) {
  double? result;
  for (final value in values.whereType<double>()) {
    if (result == null || value > result) result = value;
  }
  return result;
}

String _representativeStatus(Iterable<String> values) {
  var passed = '';
  for (final value in values) {
    if (_isFailStatus(value)) return value;
    if (passed.isEmpty && _isPassStatus(value)) passed = value;
  }
  return passed;
}

bool _categoryMatches(String source, String target) {
  final normalizedSource = source.replaceAll(RegExp(r'\s+'), '');
  final normalizedTarget = target.replaceAll(RegExp(r'\s+'), '');
  if (normalizedSource == normalizedTarget) return true;
  if (normalizedSource.contains(normalizedTarget)) return true;
  if (normalizedTarget.contains(normalizedSource) &&
      normalizedSource.length >= 4) {
    return true;
  }
  return normalizedTarget == '创新创业活动' && normalizedSource.contains('创新创业');
}

Color _categoryColor(BuildContext context, String status) {
  return _statusTextColor(context, status) ?? context.yhTheme.color.muted;
}

Color? _statusTextColor(BuildContext context, String? status) {
  if (_isFailStatus(status)) return context.yhTheme.color.danger;
  if (_isPassStatus(status)) return context.yhTheme.color.success;
  return null;
}

bool _isPassStatus(String? status) {
  final normalized = _normalizeStatusText(status);
  return normalized == '通过' ||
      normalized == '已通过' ||
      normalized == '合格' ||
      normalized == '完成' ||
      normalized == '已完成';
}

bool _isFailStatus(String? status) {
  final normalized = _normalizeStatusText(status);
  return normalized == '未通过' ||
      normalized == '不通过' ||
      normalized == '不合格' ||
      normalized == '失败';
}

String _normalizeStatusText(String? status) {
  return status?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
}

int _detailCount(SecondClassroomCreditSummary summary) {
  return summary.detailRecords.isNotEmpty
      ? summary.detailRecords.length
      : summary.records.length;
}

String _formatNullableCredit(double? credit) {
  return credit == null ? '-' : _formatCredit(credit);
}

String _formatFixedCredit(double? credit) {
  return credit == null ? '-' : credit.toStringAsFixed(2);
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
