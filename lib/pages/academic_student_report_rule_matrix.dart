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

  static double categoryWidth(YhTheme theme) =>
      theme.control.compact * 3 + theme.spacing.xs;
  static double itemWidth(YhTheme theme) =>
      theme.control.compact * 4 - theme.spacing.xs;
  static double levelWidth(YhTheme theme) => categoryWidth(theme);
  static double creditWidth(YhTheme theme) =>
      theme.spacing.xl2 * 2 - theme.spacing.xs;
  static double earnedWidth(YhTheme theme) => creditWidth(theme);
  static double requiredWidth(YhTheme theme) => creditWidth(theme);
  static double statusWidth(YhTheme theme) =>
      theme.spacing.xl2 * 2 + theme.spacing.m;
  static double minimumParticipationWidth(YhTheme theme) =>
      theme.breakpoint.compact / 2 - theme.spacing.l + theme.spacing.xs;

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final rules = summary.rules;
    if (rules.isEmpty) {
      return const _EmptyPanel(title: '规则矩阵', message: '暂无规则矩阵，等待下次刷新补全。');
    }
    final categoryGroups = _RuleCategoryGroup.fromRules(rules);
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('规则矩阵', style: theme.typography.h3),
          SizedBox(height: theme.spacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <
                  theme.breakpoint.medium - theme.spacing.xl2) {
                return _RuleMatrixMobileList(groups: categoryGroups);
              }
              final fixedWidth =
                  categoryWidth(theme) +
                  itemWidth(theme) +
                  levelWidth(theme) +
                  creditWidth(theme) +
                  earnedWidth(theme) +
                  requiredWidth(theme) +
                  statusWidth(theme);
              final minimumTableWidth =
                  fixedWidth + minimumParticipationWidth(theme);
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
    );
  }
}

class _RuleMatrixMobileList extends StatelessWidget {
  const _RuleMatrixMobileList({required this.groups});

  final List<_RuleCategoryGroup> groups;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final borderColor = _ruleMatrixBorderColor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Column(
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            _RuleCategoryMobileSection(group: groups[index]),
            if (index != groups.length - 1)
              Container(height: theme.layout.divider, color: borderColor),
          ],
        ],
      ),
    );
  }
}

class _RuleCategoryMobileSection extends StatelessWidget {
  const _RuleCategoryMobileSection({required this.group});

  final _RuleCategoryGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final borderColor = _ruleMatrixBorderColor(context);
    final statusColor = _statusTextColor(context, group.passStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColoredBox(
          color: theme.color.sunken,
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.m),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _emptyAsDash(group.category),
                    style: theme.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: theme.spacing.s),
                _RuleCategoryBadge(
                  label: '必修',
                  value: _formatNullableCredit(group.requiredCredit),
                ),
                SizedBox(width: theme.spacing.s),
                _RuleCategoryBadge(
                  label: '通过',
                  value: _emptyAsDash(group.passStatus),
                  foreground: statusColor,
                ),
              ],
            ),
          ),
        ),
        for (var index = 0; index < group.items.length; index++) ...[
          _RuleItemMobileSection(group: group.items[index]),
          if (index != group.items.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
              child: Container(
                height: theme.layout.divider,
                color: borderColor,
              ),
            ),
        ],
      ],
    );
  }
}

class _RuleCategoryBadge extends StatelessWidget {
  const _RuleCategoryBadge({
    required this.label,
    required this.value,
    this.foreground,
  });

  final String label;
  final String value;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          value,
          style: theme.typography.body.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RuleItemMobileSection extends StatelessWidget {
  const _RuleItemMobileSection({required this.group});

  final _RuleItemGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final borderColor = _ruleMatrixBorderColor(context);
    return Padding(
      padding: EdgeInsets.all(theme.spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _emptyAsDash(group.item),
            style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing.s),
          for (var index = 0; index < group.rules.length; index++) ...[
            _RuleLeafMobileRow(rule: group.rules[index]),
            if (index != group.rules.length - 1) ...[
              SizedBox(height: theme.spacing.s),
              Container(height: theme.layout.divider, color: borderColor),
              SizedBox(height: theme.spacing.s),
            ],
          ],
        ],
      ),
    );
  }
}

class _RuleLeafMobileRow extends StatelessWidget {
  const _RuleLeafMobileRow({required this.rule});

  final SecondClassroomCreditRuleRow rule;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.l,
      runSpacing: theme.spacing.s,
      children: [
        _ReportRecordField(label: '等级', value: rule.level),
        _ReportRecordField(label: '参与情况', value: rule.participation),
        _ReportRecordField(
          label: '积分',
          value: _formatNullableCredit(rule.credit),
        ),
        _ReportRecordField(
          label: '已获积分',
          value: _formatNullableCredit(rule.earnedCredit),
        ),
      ],
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
    final borderColor = _ruleMatrixBorderColor(context);
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
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.color.sunken),
      child: Row(
        children: [
          _RuleMatrixCell(
            '类别',
            width: _SecondClassroomRuleMatrix.categoryWidth(theme),
            header: true,
          ),
          _RuleMatrixCell(
            '项目',
            width: _SecondClassroomRuleMatrix.itemWidth(theme),
            header: true,
          ),
          _RuleMatrixCell(
            '等级',
            width: _SecondClassroomRuleMatrix.levelWidth(theme),
            header: true,
          ),
          _RuleMatrixCell('参与情况', width: participationWidth, header: true),
          _RuleMatrixCell(
            '积分',
            width: _SecondClassroomRuleMatrix.creditWidth(theme),
            header: true,
          ),
          _RuleMatrixCell(
            '已获积分',
            width: _SecondClassroomRuleMatrix.earnedWidth(theme),
            header: true,
          ),
          _RuleMatrixCell(
            '必修积分',
            width: _SecondClassroomRuleMatrix.requiredWidth(theme),
            header: true,
          ),
          _RuleMatrixCell(
            '通过情况',
            width: _SecondClassroomRuleMatrix.statusWidth(theme),
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
    final theme = context.yhTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuleMatrixCell(
            group.category,
            width: _SecondClassroomRuleMatrix.categoryWidth(theme),
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
          _RuleMatrixCell(
            _formatNullableCredit(group.requiredCredit),
            width: _SecondClassroomRuleMatrix.requiredWidth(theme),
            merged: true,
          ),
          _RuleMatrixCell(
            group.passStatus,
            width: _SecondClassroomRuleMatrix.statusWidth(theme),
            foreground: _statusTextColor(context, group.passStatus),
            bold: true,
            merged: true,
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
    final theme = context.yhTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuleMatrixCell(
            group.item,
            width: _SecondClassroomRuleMatrix.itemWidth(theme),
            merged: true,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (group.rules.length == 1)
                  Expanded(
                    child: _RuleMatrixLeafRow(
                      rule: group.rules.single,
                      participationWidth: participationWidth,
                    ),
                  )
                else
                  for (final rule in group.rules)
                    _RuleMatrixLeafRow(
                      rule: rule,
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

class _RuleMatrixLeafRow extends StatelessWidget {
  const _RuleMatrixLeafRow({
    required this.rule,
    required this.participationWidth,
  });

  final SecondClassroomCreditRuleRow rule;
  final double participationWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuleMatrixCell(
            rule.level,
            width: _SecondClassroomRuleMatrix.levelWidth(theme),
          ),
          _RuleMatrixCell(rule.participation, width: participationWidth),
          _RuleMatrixCell(
            _formatNullableCredit(rule.credit),
            width: _SecondClassroomRuleMatrix.creditWidth(theme),
          ),
          _RuleMatrixCell(
            _formatNullableCredit(rule.earnedCredit),
            width: _SecondClassroomRuleMatrix.earnedWidth(theme),
          ),
        ],
      ),
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
    final theme = context.yhTheme;
    final borderColor = _ruleMatrixBorderColor(context);
    return Container(
      width: width,
      constraints: BoxConstraints(
        minHeight: merged
            ? theme.control.regular - theme.spacing.xs / 2
            : theme.control.compact + theme.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.s,
      ),
      child: Text(
        _emptyAsDash(text),
        textAlign: TextAlign.center,
        style: theme.typography.body.copyWith(
          color: foreground,
          fontWeight: header || bold ? FontWeight.w700 : null,
        ),
      ),
    );
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
          requiredCredit: _representativeNumber(
            categoryRules.map((rule) => rule.requiredCredit),
          ),
          passStatus: _representativeStatus(
            categoryRules.map((rule) => rule.passStatus),
          ),
          items: _RuleItemGroup.fromRules(categoryRules),
        ),
      );
    }
    return groups;
  }
}

class _RuleItemGroup {
  const _RuleItemGroup({required this.item, required this.rules});

  final String item;
  final List<SecondClassroomCreditRuleRow> rules;

  static List<_RuleItemGroup> fromRules(
    List<SecondClassroomCreditRuleRow> rules,
  ) {
    final groups = <_RuleItemGroup>[];
    for (final itemRules in _groupConsecutive(rules, (rule) => rule.item)) {
      groups.add(_RuleItemGroup(item: itemRules.first.item, rules: itemRules));
    }
    return groups;
  }
}

Color _ruleMatrixBorderColor(BuildContext context) {
  return context.yhTheme.color.border;
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
