/*
 * 第二课堂积分规则页 — 规则导航、空态与进度辅助组件
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_rules_page.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

/// 第二课堂规则矩阵独立页面。
class StudentReportRulesPage extends StatelessWidget {
  const StudentReportRulesPage({super.key, required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhTaskPage(
      title: '第二课堂积分规则',
      kicker: '计算说明',
      summary: '先看还差多少，再按类别找到可补齐的项目；规则缺失时不推测最终学分。',
      source: '第二课堂 · 本地快照',
      sourceSymbol: '学',
      sourceTimestamp: _academicDetailTimestamp(summary.fetchedAt),
      appBarTitle: _academicTaskAppBarTitle('第二课堂规则', summary.fetchedAt),
      primaryActionLabel: '返回成绩单',
      onPrimaryAction: () => Navigator.of(context).maybePop(),
      width: YhTaskPageWidth.reading,
      body: Padding(
        padding: EdgeInsets.only(
          top: summary.rules.isEmpty
              ? theme.layout.controlBorder * 2
              : theme.layout.controlBorder,
        ),
        child: summary.rules.isEmpty
            ? const _StudentRulesEmpty()
            : _SecondClassroomRuleMatrix(summary: summary),
      ),
    );
  }
}

class _StudentRulesEmpty extends StatelessWidget {
  const _StudentRulesEmpty();

  /// 构建保留来源上下文的紧凑规则空态。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 规则空态卡片。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
        child: YhCard(
          padding: EdgeInsets.all(theme.spacing.m),
          radius: theme.radius.m,
          borderWidth: theme.layout.controlBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '规则未同步',
                style: theme.typography.caption.copyWith(
                  color: theme.color.serviceSecondClass,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                '暂时没有可核验的积分规则',
                style: theme.typography.h2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                '返回成绩单刷新第二课堂数据；规则补全后，本页会优先显示还差多少和可补齐的类别。',
                style: theme.typography.body.copyWith(color: theme.color.muted),
              ),
              SizedBox(height: theme.spacing.l),
              Container(
                height: theme.layout.divider,
                color: theme.color.border,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: theme.control.minimumTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '总差额',
                        style: theme.typography.small.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    ),
                    Text(
                      '等待规则数据',
                      style: theme.typography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentRuleProgress extends StatelessWidget {
  const _StudentRuleProgress({
    required this.value,
    required this.color,
    required this.semanticLabel,
    this.compact = false,
  });

  final double value;
  final Color color;
  final String semanticLabel;
  final bool compact;

  /// 构建确定性规则进度条及其语义值。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 规则进度条。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final normalized = value.clamp(0.0, 1.0);
    final bar = FractionallySizedBox(
      widthFactor: normalized,
      child: ColoredBox(color: color),
    );
    return Semantics(
      label: semanticLabel,
      value: '${(normalized * 100).round()}%',
      child: SizedBox(
        height: compact ? theme.spacing.xs : theme.spacing.s,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.radius.full),
          child: ColoredBox(
            color: theme.color.sunken,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: bar,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveRuleCategoryIntent extends Intent {
  const _MoveRuleCategoryIntent(this.offset);

  final int offset;
}

class _RuleItemLedger extends StatelessWidget {
  const _RuleItemLedger({required this.group});

  final _RuleItemGroup group;

  /// 构建同一项目下的全部来源规则行。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 项目规则列表。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < group.rules.length; index++) ...[
          if (index > 0) SizedBox(height: theme.spacing.s),
          _RuleLeafLedgerRow(
            item: group.item,
            rule: group.rules[index],
            showItem: index == 0,
          ),
        ],
      ],
    );
  }
}

/// 选取类别状态，优先保留未完成或来源异常状态。
///
/// :param values: 同一类别的来源状态集合。
/// :returns: 可显示的代表状态；来源为空时返回空字符串。
String _representativeRuleStatus(Iterable<String> values) {
  final statuses = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);
  for (final status in statuses) {
    if (!_isPassStatus(status)) return status;
  }
  return statuses.isEmpty ? '' : statuses.first;
}
