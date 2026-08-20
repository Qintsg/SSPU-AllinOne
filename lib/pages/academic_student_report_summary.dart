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
    this.metricAccent,
    this.prominentMetrics = false,
    this.comfortableCategories = false,
  });

  final SecondClassroomCreditSummary summary;
  final List<_CategoryProgress> categories;
  final double metricMinWidth;
  final int categoryColumns;
  final Color? metricAccent;
  final bool prominentMetrics;
  final bool comfortableCategories;

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
        hero: prominentMetrics,
        valueColor: metricAccent,
      ),
      _SummaryMetric(
        label: '总必修积分',
        value: _formatNullableCredit(totals?.totalRequiredCredit),
        emphasized: prominentMetrics,
        brandEmphasis: !prominentMetrics,
      ),
      _SummaryMetric(
        label: '总体通过情况',
        value: _emptyAsUnread(status),
        valueColor: _statusTextColor(context, status),
        emphasized: prominentMetrics,
        brandEmphasis: !prominentMetrics,
      ),
      _SummaryMetric(
        label: prominentMetrics ? '证据记录' : '详情记录',
        value: '${_detailCount(summary)} 项',
        emphasized: prominentMetrics,
        brandEmphasis: !prominentMetrics,
      ),
    ];
    final useExpandedPadding =
        prominentMetrics &&
        MediaQuery.sizeOf(context).width >= theme.breakpoint.compact;
    final panelPadding = useExpandedPadding ? theme.spacing.l : theme.spacing.m;
    final sectionSpacing = prominentMetrics
        ? theme.spacing.m + theme.spacing.xs
        : theme.spacing.s;
    return DecoratedBox(
      decoration: _summaryPanelDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prominentMetrics)
              _ProminentSummaryMetricGrid(metrics: metrics)
            else
              _SummaryMetricWrap(metrics: metrics, minWidth: metricMinWidth),
            SizedBox(height: sectionSpacing),
            Container(height: theme.layout.divider, color: theme.color.border),
            SizedBox(height: sectionSpacing),
            _CategoryProgressStrip(
              categories: categories,
              columnCount: categoryColumns,
              comfortable: comfortableCategories,
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

class _ProminentSummaryMetricGrid extends StatelessWidget {
  const _ProminentSummaryMetricGrid({required this.metrics});

  final List<_SummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final columns = MediaQuery.sizeOf(context).width < theme.breakpoint.compact
        ? 2
        : 4;
    final rows = <Widget>[];
    for (var start = 0; start < metrics.length; start += columns) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: theme.spacing.m));
      final end = math.min(start + columns, metrics.length);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = start; index < end; index++) ...[
              if (index > start) SizedBox(width: theme.spacing.m),
              Expanded(child: metrics[index]),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
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
    this.hero = false,
    this.brandEmphasis = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;
  final bool hero;
  final bool brandEmphasis;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style:
              (hero
                      ? theme.typography.display
                      : emphasized
                      ? theme.typography.h2
                      : theme.typography.body)
                  .copyWith(
                    color:
                        valueColor ??
                        (emphasized && brandEmphasis
                            ? theme.color.brandStrong
                            : null),
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
    this.comfortable = false,
  });

  final List<_CategoryProgress> categories;
  final int columnCount;
  final bool comfortable;

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
                  _CategoryProgressPill(
                    category: categories[itemIndex],
                    comfortable: comfortable,
                  ),
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
  const _CategoryProgressPill({
    required this.category,
    this.comfortable = false,
  });

  final _CategoryProgress category;
  final bool comfortable;

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
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: comfortable ? theme.control.compact : 0,
      ),
      child: DecoratedBox(
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
                    text: comfortable
                        ? category.displayValue.replaceAll('/', ' / ')
                        : category.displayValue,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
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
  final normalizedSource = _normalizeCategory(source);
  final normalizedTarget = _normalizeCategory(target);
  if (normalizedSource == normalizedTarget) return true;
  if (normalizedSource.contains(normalizedTarget)) return true;
  if (normalizedTarget.contains(normalizedSource) &&
      normalizedSource.length >= 4) {
    return true;
  }
  return normalizedTarget == '创新创业活动' && normalizedSource.contains('创新创业');
}

String _normalizeCategory(String value) {
  return value.replaceAll(RegExp(r'[\s与、]'), '');
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

class _RuleItemGroup {
  const _RuleItemGroup({required this.item, required this.rules});

  final String item;
  final List<SecondClassroomCreditRuleRow> rules;

  /// 将同一类别中的来源规则按项目归并。
  ///
  /// :param rules: 同一类别的来源规则行。
  /// :returns: 保持项目首次出现顺序的规则分组。
  static List<_RuleItemGroup> fromRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final items = <String, List<SecondClassroomCreditRuleRow>>{};
    for (final rule in rules) {
      items.putIfAbsent(rule.item, () => []).add(rule);
    }
    return [
      for (final entry in items.entries)
        _RuleItemGroup(item: entry.key, rules: entry.value),
    ];
  }
}

class _RuleCategoryGroup {
  const _RuleCategoryGroup({
    required this.category,
    required this.requiredCredit,
    required this.passStatus,
    required this.items,
  });

  final String category;
  final double? requiredCredit;
  final String passStatus;
  final List<_RuleItemGroup> items;

  /// 将来源规则按首次出现的类别归并。
  ///
  /// :param rules: 第二课堂来源规则行。
  /// :returns: 保持类别首次出现顺序的规则分组。
  static List<_RuleCategoryGroup> fromRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final categories = <String, List<SecondClassroomCreditRuleRow>>{};
    for (final rule in rules) {
      categories.putIfAbsent(rule.category, () => []).add(rule);
    }
    return [
      for (final entry in categories.entries)
        _RuleCategoryGroup(
          category: entry.key,
          requiredCredit: _representativeNumber(
            entry.value.map((rule) => rule.requiredCredit),
          ),
          passStatus: _representativeRuleStatus(
            entry.value.map((rule) => rule.passStatus),
          ),
          items: _RuleItemGroup.fromRules(entry.value),
        ),
    ];
  }
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
  if (text.endsWith('.00')) return text.substring(0, text.length - 3);
  if (text.endsWith('0')) return text.substring(0, text.length - 1);
  return text;
}

String _emptyAsUnread(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '未读取' : normalized;
}

String _emptyAsDash(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '-' : normalized;
}
