/*
 * 教务第二课堂摘要的类别进度与规则归并辅助 — 展示无关的纯数据与格式化
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_progress_helpers.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'academic_page.dart';

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
