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
    final categories = _categoryProgressList(summary);
    return LayoutBuilder(
      builder: (context, constraints) {
        return _SecondClassroomCompactSummary(
          summary: summary,
          categories: categories,
          minCategoryWidth: constraints.maxWidth < 560 ? 150 : 196,
        );
      },
    );
  }
}

class _SecondClassroomCompactSummary extends StatelessWidget {
  const _SecondClassroomCompactSummary({
    required this.summary,
    required this.categories,
    this.minCategoryWidth = 168,
    this.showTotalCredit = false,
    this.title,
  });

  final SecondClassroomCreditSummary summary;
  final List<_CategoryProgress> categories;
  final double minCategoryWidth;
  final bool showTotalCredit;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final totals = summary.totals;
    final theme = FluentTheme.of(context);
    final status = totals?.passStatus;
    final metrics = [
      if (showTotalCredit)
        _SummaryMetric(
          label: '总积分',
          value: _formatNullableCredit(totals?.totalCredit),
        ),
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
        padding: const EdgeInsets.all(FluentSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.typography.bodyStrong),
              const SizedBox(height: FluentSpacing.s),
            ],
            _SummaryMetricWrap(metrics: metrics),
            const SizedBox(height: FluentSpacing.s),
            Container(
              height: 1,
              color: FluentTheme.of(context).resources.cardStrokeColorDefault,
            ),
            const SizedBox(height: FluentSpacing.s),
            _CategoryProgressStrip(
              categories: categories,
              minItemWidth: minCategoryWidth,
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

class _SummaryMetricWrap extends StatelessWidget {
  const _SummaryMetricWrap({required this.metrics});

  final List<_SummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth < 560 ? 96.0 : 112.0;
        return Wrap(
          spacing: FluentSpacing.l,
          runSpacing: FluentSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final metric in metrics)
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth),
                child: metric,
              ),
          ],
        );
      },
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
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style:
              (emphasized
                      ? theme.typography.title
                      : theme.typography.bodyStrong)
                  ?.copyWith(
                    color:
                        valueColor ??
                        (emphasized
                            ? theme.accentColor.defaultBrushFor(
                                theme.brightness,
                              )
                            : null),
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
    );
  }
}

class _CategoryProgressStrip extends StatelessWidget {
  const _CategoryProgressStrip({
    required this.categories,
    required this.minItemWidth,
  });

  final List<_CategoryProgress> categories;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = FluentSpacing.s;
        final columnCount = _categoryColumnCount(
          constraints.maxWidth,
          minItemWidth,
          spacing,
          categories.length,
        );
        final totalGap = spacing * (columnCount - 1);
        final tileWidth = (constraints.maxWidth - totalGap) / columnCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: tileWidth,
                child: _CategoryProgressPill(category: category),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryProgressPill extends StatelessWidget {
  const _CategoryProgressPill({required this.category});

  final _CategoryProgress category;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final colors = context.fluentColors;
    final textColor = _categoryColor(context, category.status);
    final borderColor = textColor.withValues(alpha: 0.48);
    final backgroundColor = _isFailStatus(category.status)
        ? colors.statusDangerBackground
        : _isPassStatus(category.status)
        ? colors.statusSuccessBackground
        : theme.resources.subtleFillColorSecondary;
    return FluentCard(
      bordered: true,
      elevated: false,
      padding: EdgeInsets.zero,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FluentSpacing.s,
          vertical: FluentSpacing.xs,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final label = _CategoryProgressLabel(
              text: category.label,
              color: textColor,
            );
            final value = _CategoryProgressValue(
              text: category.displayValue,
              color: textColor,
            );
            if (constraints.maxWidth < 228) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  label,
                  const SizedBox(height: FluentSpacing.xxs),
                  value,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: FluentSpacing.s),
                Align(alignment: Alignment.centerRight, child: value),
              ],
            );
          },
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
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.visible,
      style: FluentTheme.of(
        context,
      ).typography.caption?.copyWith(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _CategoryProgressValue extends StatelessWidget {
  const _CategoryProgressValue({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        style: FluentTheme.of(context).typography.bodyStrong?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

int _categoryColumnCount(
  double maxWidth,
  double minItemWidth,
  double spacing,
  int itemCount,
) {
  if (itemCount <= 1) return itemCount;
  final fourColumnWidth = minItemWidth * 4 + spacing * 3;
  final twoColumnWidth = minItemWidth * 2 + spacing;
  if (itemCount >= 4 && maxWidth >= fourColumnWidth) return 4;
  if (itemCount >= 2 && maxWidth >= twoColumnWidth) return 2;
  return 1;
}

BoxDecoration _summaryPanelDecoration(BuildContext context) {
  final theme = FluentTheme.of(context);
  final colors = context.fluentColors;
  return BoxDecoration(
    color: theme.resources.controlAltFillColorSecondary,
    borderRadius: BorderRadius.circular(context.fluentRadii.medium),
    border: Border.all(color: colors.neutralStroke2),
  );
}

class _SecondClassroomWarningText extends StatelessWidget {
  const _SecondClassroomWarningText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      message,
      style: theme.typography.caption?.copyWith(
        color: context.fluentColors.statusWarningForeground,
      ),
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
  return _statusTextColor(context, status) ??
      FluentTheme.of(context).resources.textFillColorSecondary;
}

Color? _statusTextColor(BuildContext context, String? status) {
  if (_isFailStatus(status)) return context.fluentColors.statusDangerForeground;
  if (_isPassStatus(status)) {
    return context.fluentColors.statusSuccessForeground;
  }
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
