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
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecondClassroomTotalOverview(summary: summary),
              const SizedBox(height: FluentSpacing.m),
              _CategoryProgressGrid(categories: categories),
            ],
          );
        }

        var categoryWidth = constraints.maxWidth * 0.46;
        if (categoryWidth > 560) categoryWidth = 560;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SecondClassroomTotalOverview(summary: summary)),
            const SizedBox(width: FluentSpacing.xl),
            SizedBox(
              width: categoryWidth,
              child: _CategoryProgressGrid(categories: categories),
            ),
          ],
        );
      },
    );
  }
}

class _SecondClassroomTotalOverview extends StatelessWidget {
  const _SecondClassroomTotalOverview({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final totals = summary.totals;
    final status = totals?.passStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: FluentSpacing.xl,
          runSpacing: FluentSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _TotalValue(
              label: '总已获分数',
              value: _formatNullableCredit(totals?.totalEarnedCredit),
            ),
            _CompactValue(
              label: '总必修积分',
              value: _formatNullableCredit(totals?.totalRequiredCredit),
            ),
            _CompactValue(
              label: '总体通过情况',
              value: _emptyAsUnread(status),
              valueColor: _statusTextColor(context, status),
            ),
            _CompactValue(label: '详情记录', value: '${_detailCount(summary)} 项'),
          ],
        ),
        if (summary.warning != null) ...[
          const SizedBox(height: FluentSpacing.s),
          _SecondClassroomWarningText(summary.warning!),
        ],
      ],
    );
  }
}

class _TotalValue extends StatelessWidget {
  const _TotalValue({required this.label, required this.value});

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
          style: theme.typography.title?.copyWith(
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
    );
  }
}

class _CompactValue extends StatelessWidget {
  const _CompactValue({
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

class _CategoryProgressGrid extends StatelessWidget {
  const _CategoryProgressGrid({required this.categories});

  final List<_CategoryProgress> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 360;
        final spacing = FluentSpacing.s;
        final tileWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: tileWidth,
                child: _CategoryProgressTile(category: category),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryProgressTile extends StatelessWidget {
  const _CategoryProgressTile({required this.category});

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
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.m,
        vertical: FluentSpacing.s,
      ),
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: SizedBox(
        height: 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                category.displayValue,
                style: theme.typography.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    earned: _representativeNumber(matched.map((rule) => rule.earnedCredit)),
    required: _representativeNumber(matched.map((rule) => rule.requiredCredit)),
    status: _representativeStatus(matched.map((rule) => rule.passStatus)),
  );
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
