/*
 * 第二课堂规则矩阵表格 — 按源网页合并规则分组展示
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_rule_matrix.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

part of 'academic_page.dart';

class _SecondClassroomRuleMatrix extends StatelessWidget {
  const _SecondClassroomRuleMatrix({required this.summary});

  static const double _categoryWidth = 124;
  static const double _itemWidth = 156;
  static const double _levelWidth = 124;
  static const double _creditWidth = 92;
  static const double _earnedWidth = 92;
  static const double _requiredWidth = 92;
  static const double _statusWidth = 112;
  static const double _minimumParticipationWidth = 280;

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final rules = summary.rules;
    if (rules.isEmpty) {
      return const _EmptyPanel(title: '规则矩阵', message: '暂无规则矩阵，等待下次刷新补全。');
    }
    final categoryGroups = _RuleCategoryGroup.fromRules(rules);
    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('规则矩阵', style: FluentTheme.of(context).typography.bodyStrong),
            const SizedBox(height: FluentSpacing.m),
            LayoutBuilder(
              builder: (context, constraints) {
                const fixedWidth =
                    _categoryWidth +
                    _itemWidth +
                    _levelWidth +
                    _creditWidth +
                    _earnedWidth +
                    _requiredWidth +
                    _statusWidth;
                const minimumTableWidth =
                    fixedWidth + _minimumParticipationWidth;
                final tableWidth = constraints.maxWidth > minimumTableWidth
                    ? constraints.maxWidth
                    : minimumTableWidth;
                final participationWidth = tableWidth - fixedWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: _RuleMatrixTable(
                      groups: categoryGroups,
                      participationWidth: participationWidth,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleMatrixTable extends StatelessWidget {
  const _RuleMatrixTable({
    required this.groups,
    required this.participationWidth,
  });

  final List<_RuleCategoryGroup> groups;
  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final borderColor = theme.resources.cardStrokeColorDefault;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _RuleMatrixHeader(participationWidth: participationWidth),
          for (final group in groups)
            _RuleCategoryGroupView(
              group: group,
              participationWidth: participationWidth,
            ),
        ],
      ),
    );
  }
}

class _RuleMatrixHeader extends StatelessWidget {
  const _RuleMatrixHeader({required this.participationWidth});

  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.resources.controlAltFillColorSecondary,
      ),
      child: Row(
        children: [
          const _RuleMatrixCell(
            '类别',
            width: _SecondClassroomRuleMatrix._categoryWidth,
            header: true,
          ),
          const _RuleMatrixCell(
            '项目',
            width: _SecondClassroomRuleMatrix._itemWidth,
            header: true,
          ),
          const _RuleMatrixCell(
            '等级',
            width: _SecondClassroomRuleMatrix._levelWidth,
            header: true,
          ),
          _RuleMatrixCell('参与情况', width: participationWidth, header: true),
          const _RuleMatrixCell(
            '积分',
            width: _SecondClassroomRuleMatrix._creditWidth,
            header: true,
          ),
          const _RuleMatrixCell(
            '已获积分',
            width: _SecondClassroomRuleMatrix._earnedWidth,
            header: true,
          ),
          const _RuleMatrixCell(
            '必修积分',
            width: _SecondClassroomRuleMatrix._requiredWidth,
            header: true,
          ),
          const _RuleMatrixCell(
            '通过情况',
            width: _SecondClassroomRuleMatrix._statusWidth,
            header: true,
          ),
        ],
      ),
    );
  }
}

class _RuleCategoryGroupView extends StatelessWidget {
  const _RuleCategoryGroupView({
    required this.group,
    required this.participationWidth,
  });

  final _RuleCategoryGroup group;
  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuleMatrixCell(
            group.category,
            width: _SecondClassroomRuleMatrix._categoryWidth,
            merged: true,
          ),
          Expanded(
            child: Column(
              children: [
                for (final itemGroup in group.items)
                  _RuleItemGroupView(
                    group: itemGroup,
                    participationWidth: participationWidth,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItemGroupView extends StatelessWidget {
  const _RuleItemGroupView({
    required this.group,
    required this.participationWidth,
  });

  final _RuleItemGroup group;
  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuleMatrixCell(
            group.item,
            width: _SecondClassroomRuleMatrix._itemWidth,
            merged: true,
          ),
          Expanded(
            child: Column(
              children: [
                for (final requirementGroup in group.requirements)
                  _RuleRequirementGroupView(
                    group: requirementGroup,
                    participationWidth: participationWidth,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRequirementGroupView extends StatelessWidget {
  const _RuleRequirementGroupView({
    required this.group,
    required this.participationWidth,
  });

  final _RuleRequirementGroup group;
  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final rule in group.rules)
                  _RuleMatrixLeafRow(
                    rule: rule,
                    participationWidth: participationWidth,
                  ),
              ],
            ),
          ),
          _RuleMatrixCell(
            _formatNullableCredit(group.requiredCredit),
            width: _SecondClassroomRuleMatrix._requiredWidth,
            merged: true,
          ),
          _RuleMatrixCell(
            group.passStatus,
            width: _SecondClassroomRuleMatrix._statusWidth,
            foreground: _statusTextColor(context, group.passStatus),
            bold: true,
            merged: true,
          ),
        ],
      ),
    );
  }
}

class _RuleMatrixLeafRow extends StatelessWidget {
  const _RuleMatrixLeafRow({
    required this.rule,
    required this.participationWidth,
  });

  final SecondClassroomCreditRuleRow rule;
  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RuleMatrixCell(
          rule.level,
          width: _SecondClassroomRuleMatrix._levelWidth,
        ),
        _RuleMatrixCell(rule.participation, width: participationWidth),
        _RuleMatrixCell(
          _formatNullableCredit(rule.credit),
          width: _SecondClassroomRuleMatrix._creditWidth,
        ),
        _RuleMatrixCell(
          _formatNullableCredit(rule.earnedCredit),
          width: _SecondClassroomRuleMatrix._earnedWidth,
        ),
      ],
    );
  }
}

class _RuleMatrixCell extends StatelessWidget {
  const _RuleMatrixCell(
    this.text, {
    required this.width,
    this.header = false,
    this.merged = false,
    this.foreground,
    this.bold = false,
  });

  final String text;
  final double width;
  final bool header;
  final bool merged;
  final Color? foreground;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final borderColor = theme.resources.cardStrokeColorDefault;
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: merged ? 46 : 42),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.s,
      ),
      child: Text(
        _emptyAsDash(text),
        textAlign: TextAlign.center,
        style: (header ? theme.typography.bodyStrong : theme.typography.body)
            ?.copyWith(
              color: foreground,
              fontWeight: header || bold ? FontWeight.w700 : null,
            ),
      ),
    );
  }
}

class _RuleCategoryGroup {
  const _RuleCategoryGroup({required this.category, required this.items});

  final String category;
  final List<_RuleItemGroup> items;

  static List<_RuleCategoryGroup> fromRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final groups = <_RuleCategoryGroup>[];
    for (final categoryRules in _groupConsecutive(
      rules,
      (rule) => rule.category,
    )) {
      groups.add(
        _RuleCategoryGroup(
          category: categoryRules.first.category,
          items: _RuleItemGroup.fromRules(categoryRules),
        ),
      );
    }
    return groups;
  }
}

class _RuleItemGroup {
  const _RuleItemGroup({required this.item, required this.requirements});

  final String item;
  final List<_RuleRequirementGroup> requirements;

  static List<_RuleItemGroup> fromRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final groups = <_RuleItemGroup>[];
    for (final itemRules in _groupConsecutive(rules, (rule) => rule.item)) {
      groups.add(
        _RuleItemGroup(
          item: itemRules.first.item,
          requirements: _RuleRequirementGroup.fromRules(itemRules),
        ),
      );
    }
    return groups;
  }
}

class _RuleRequirementGroup {
  const _RuleRequirementGroup({
    required this.requiredCredit,
    required this.passStatus,
    required this.rules,
  });

  final double? requiredCredit;
  final String passStatus;
  final List<SecondClassroomCreditRuleRow> rules;

  static List<_RuleRequirementGroup> fromRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final groups = <_RuleRequirementGroup>[];
    for (final requirementRules in _groupConsecutive(
      rules,
      (rule) => '${rule.requiredCredit}|${rule.passStatus}',
    )) {
      final first = requirementRules.first;
      groups.add(
        _RuleRequirementGroup(
          requiredCredit: first.requiredCredit,
          passStatus: first.passStatus,
          rules: requirementRules,
        ),
      );
    }
    return groups;
  }
}

List<List<T>> _groupConsecutive<T>(
  List<T> values,
  String Function(T value) keyOf,
) {
  final groups = <List<T>>[];
  for (final value in values) {
    final key = keyOf(value);
    if (groups.isEmpty || keyOf(groups.last.last) != key) {
      groups.add([value]);
    } else {
      groups.last.add(value);
    }
  }
  return groups;
}
