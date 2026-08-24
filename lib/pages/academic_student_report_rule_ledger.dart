/*
 * 第二课堂规则账本明细 — 按类别呈现可核验的来源规则。
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_rule_ledger.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

class _RuleCategoryLedgerSection extends StatelessWidget {
  const _RuleCategoryLedgerSection({required this.group, this.kicker = '计分类别'});

  final _RuleCategoryGroup group;
  final String kicker;

  /// 构建一个类别的完成度与来源规则明细。
  ///
  /// :param context: 当前清源主题和媒体查询上下文。
  /// :returns: 类别账本分区。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compactScreen =
        MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final statusColor =
        _statusTextColor(context, group.passStatus) ?? theme.color.muted;
    final earned = _sumNumbers(
      group.items.expand((item) => item.rules.map((rule) => rule.earnedCredit)),
    );
    final progress =
        earned != null &&
            group.requiredCredit != null &&
            group.requiredCredit! > 0
        ? (earned / group.requiredCredit!).clamp(0.0, 1.0)
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.m,
        compactScreen ? theme.spacing.l : theme.spacing.m,
        theme.spacing.m,
        compactScreen ? theme.spacing.m + theme.spacing.xs : theme.spacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker,
                      style: theme.typography.caption.copyWith(
                        color: theme.color.serviceSecondClass,
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      _emptyAsDash(group.category),
                      style: theme.typography.h2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    group.requiredCredit == null
                        ? '必修要求未提供'
                        : '${_formatNullableCredit(earned)} / ${_formatCredit(group.requiredCredit!)}',
                    style:
                        (group.requiredCredit == null
                                ? theme.typography.small
                                : theme.typography.h3)
                            .copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    group.passStatus.trim().isEmpty
                        ? '状态未提供'
                        : group.passStatus,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (progress != null) ...[
            SizedBox(height: theme.spacing.m),
            _StudentRuleProgress(
              value: progress,
              color: _isPassStatus(group.passStatus)
                  ? theme.color.success
                  : theme.color.serviceSecondClass,
              semanticLabel: '${group.category}完成度',
              compact: true,
            ),
          ],
          SizedBox(
            height: compactScreen
                ? theme.spacing.m - theme.layout.controlBorder
                : theme.spacing.m,
          ),
          for (var index = 0; index < group.items.length; index++) ...[
            if (index > 0)
              Container(
                height: theme.layout.divider,
                color: theme.color.border,
              ),
            _RuleItemLedger(group: group.items[index]),
          ],
        ],
      ),
    );
  }
}

class _RuleLeafLedgerRow extends StatelessWidget {
  const _RuleLeafLedgerRow({
    required this.item,
    required this.rule,
    required this.showItem,
  });

  final String item;
  final SecondClassroomCreditRuleRow rule;
  final bool showItem;

  /// 构建一条不推测缺失字段的规则证据行。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 规则证据行。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final conditions = [
      rule.level.trim(),
      rule.participation.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: theme.control.minimumTarget + theme.spacing.l,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showItem)
                    Text(
                      _emptyAsDash(item),
                      style: theme.typography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (showItem) SizedBox(height: theme.spacing.xs),
                  Text(
                    conditions.isEmpty ? '条件待来源补全' : conditions,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.spacing.m),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rule.credit == null
                      ? '积分待来源补全'
                      : '+${_formatCredit(rule.credit!)}',
                  style:
                      (rule.credit == null
                              ? theme.typography.small
                              : theme.typography.h3)
                          .copyWith(
                            color: theme.color.serviceSecondClass,
                            fontWeight: FontWeight.w700,
                          ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  rule.earnedCredit == null
                      ? '尚无已获记录'
                      : '已获 ${_formatCredit(rule.earnedCredit!)}',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
