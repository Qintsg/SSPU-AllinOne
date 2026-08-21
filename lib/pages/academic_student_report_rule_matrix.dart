/*
 * 第二课堂积分规则账本 — 先呈现完成差额，再按类别展示来源规则。
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_rule_matrix.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'academic_page.dart';

class _SecondClassroomRuleMatrix extends StatefulWidget {
  const _SecondClassroomRuleMatrix({required this.summary});

  final SecondClassroomCreditSummary summary;

  /// 创建规则矩阵的响应式交互状态。
  ///
  /// :returns: 规则矩阵状态对象。
  @override
  State<_SecondClassroomRuleMatrix> createState() =>
      _SecondClassroomRuleMatrixState();
}

class _SecondClassroomRuleMatrixState
    extends State<_SecondClassroomRuleMatrix> {
  late List<_RuleCategoryGroup> _groups;
  late List<FocusNode> _categoryFocusNodes;
  late int _selectedIndex;

  /// 初始化类别分组、焦点节点和首个未完成类别。
  ///
  /// :returns: 无返回值。
  @override
  void initState() {
    super.initState();
    _replaceGroups();
  }

  /// 在外部规则快照换代时重建页面状态。
  ///
  /// :param oldWidget: 换代前的规则矩阵组件。
  /// :returns: 无返回值。
  @override
  void didUpdateWidget(covariant _SecondClassroomRuleMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.summary.rules, widget.summary.rules)) {
      for (final node in _categoryFocusNodes) {
        node.dispose();
      }
      _replaceGroups();
    }
  }

  /// 重建类别分组，并把初始选择定位到首个未完成类别。
  ///
  /// :returns: 无返回值。
  void _replaceGroups() {
    final sourceGroups = _RuleCategoryGroup.fromRules(widget.summary.rules);
    _groups = [
      ...sourceGroups.where((group) => !_isPassStatus(group.passStatus)),
      ...sourceGroups.where((group) => _isPassStatus(group.passStatus)),
    ];
    _categoryFocusNodes = [
      for (final group in _groups)
        FocusNode(debugLabel: '第二课堂规则(${group.category})'),
    ];
    final incomplete = _groups.indexWhere(
      (group) => !_isPassStatus(group.passStatus),
    );
    _selectedIndex = incomplete < 0 ? 0 : incomplete;
  }

  /// 选择一个规则类别并按需归还键盘焦点。
  ///
  /// :param index: 目标类别索引。
  /// :param requestFocus: 是否把焦点移动到目标类别。
  /// :returns: 无返回值。
  void _selectCategory(int index, {bool requestFocus = false}) {
    if (index < 0 || index >= _groups.length) return;
    setState(() => _selectedIndex = index);
    if (requestFocus) _categoryFocusNodes[index].requestFocus();
  }

  /// 按相对位移循环切换规则类别。
  ///
  /// :param offset: 相对当前类别的移动量。
  /// :returns: 无返回值。
  void _moveCategory(int offset) {
    if (_groups.isEmpty) return;
    final focusedIndex = _categoryFocusNodes.indexWhere(
      (node) => node.hasFocus,
    );
    final current = focusedIndex < 0 ? _selectedIndex : focusedIndex;
    _selectCategory((current + offset) % _groups.length, requestFocus: true);
  }

  /// 释放类别键盘焦点节点。
  ///
  /// :returns: 无返回值。
  @override
  void dispose() {
    for (final node in _categoryFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// 构建连续账本或宽屏主从规则视图。
  ///
  /// :param context: 当前清源主题和媒体查询上下文。
  /// :returns: 响应式规则视图。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useMasterDetail =
            MediaQuery.sizeOf(context).width >= theme.breakpoint.medium &&
            constraints.maxWidth >=
                theme.breakpoint.compact + theme.spacing.xl2;
        if (!useMasterDetail) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StudentRulesOverall(
                summary: widget.summary,
                priorityCategory: _groups.first.category,
              ),
              SizedBox(height: theme.spacing.m + theme.layout.controlBorder),
              YhCard(
                padding: EdgeInsets.zero,
                radius: theme.radius.m,
                borderWidth: theme.layout.controlBorder,
                child: Column(
                  children: [
                    for (var index = 0; index < _groups.length; index++) ...[
                      _RuleCategoryLedgerSection(group: _groups[index]),
                      if (index != _groups.length - 1)
                        Container(
                          height: theme.layout.divider,
                          color: theme.color.border,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        final selectedGroup = _groups[_selectedIndex];
        final disableAnimations = MediaQuery.disableAnimationsOf(context);
        final duration = theme.motion.effective(
          theme.motion.base,
          disableAnimations: disableAnimations,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: theme.control.regular * 5 + theme.spacing.s,
              child: _StudentRulesOverall(
                summary: widget.summary,
                priorityCategory: _groups.first.category,
                groups: _groups,
                selectedIndex: _selectedIndex,
                focusNodes: _categoryFocusNodes,
                onSelected: _selectCategory,
                onMove: _moveCategory,
              ),
            ),
            SizedBox(width: theme.spacing.m),
            Expanded(
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: theme.motion.curve,
                switchOutCurve: theme.motion.curve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        disableAnimations
                            ? 0
                            : theme.spacing.xs * (1 - animation.value),
                      ),
                      child: child,
                    ),
                  ),
                ),
                child: YhCard(
                  key: ValueKey(selectedGroup.category),
                  padding: EdgeInsets.zero,
                  radius: theme.radius.m,
                  borderWidth: theme.layout.controlBorder,
                  child: _RuleCategoryLedgerSection(
                    group: selectedGroup,
                    kicker: '优先补齐',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentRulesOverall extends StatelessWidget {
  const _StudentRulesOverall({
    required this.summary,
    this.priorityCategory,
    this.groups = const [],
    this.selectedIndex,
    this.focusNodes = const [],
    this.onSelected,
    this.onMove,
  });

  final SecondClassroomCreditSummary summary;
  final String? priorityCategory;
  final List<_RuleCategoryGroup> groups;
  final int? selectedIndex;
  final List<FocusNode> focusNodes;
  final ValueChanged<int>? onSelected;
  final ValueChanged<int>? onMove;

  /// 构建完成差额以及可选的宽屏类别导航。
  ///
  /// :param context: 当前清源主题和媒体查询上下文。
  /// :returns: 完成差额卡片。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compactScreen =
        MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final earned = summary.totals?.totalEarnedCredit;
    final required = summary.totals?.totalRequiredCredit;
    final progress = earned != null && required != null && required > 0
        ? (earned / required).clamp(0.0, 1.0)
        : null;
    final gap = earned != null && required != null
        ? (required - earned).clamp(0.0, double.infinity)
        : null;
    return YhCard(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.m,
        compactScreen ? theme.spacing.m + theme.spacing.xs : theme.spacing.m,
        theme.spacing.m,
        compactScreen
            ? theme.spacing.m + theme.layout.controlBorder
            : theme.spacing.m,
      ),
      radius: theme.radius.m,
      borderWidth: theme.layout.controlBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '完成差额',
            style: theme.typography.caption.copyWith(
              color: theme.color.serviceSecondClass,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: compactScreen
                ? theme.spacing.s + theme.spacing.xs
                : theme.spacing.s,
          ),
          if (earned == null || required == null)
            Text(
              '总积分要求待来源补全',
              style: theme.typography.h3.copyWith(fontWeight: FontWeight.w600),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '${_formatCredit(earned)} / ${_formatCredit(required)}',
                    style: theme.typography.h1.copyWith(
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (gap != null)
                  Text(
                    gap > 0 ? '还差 ${_formatCredit(gap)} 分' : '已满足必修要求',
                    style: theme.typography.small.copyWith(
                      color: gap > 0
                          ? theme.color.serviceSecondClass
                          : theme.color.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          if (progress != null) ...[
            SizedBox(
              height: compactScreen
                  ? theme.spacing.m - theme.spacing.xs
                  : theme.spacing.m,
            ),
            _StudentRuleProgress(
              value: progress,
              color: theme.color.serviceSecondClass,
              semanticLabel: '第二课堂总完成度',
            ),
            SizedBox(height: theme.spacing.s),
            Text(
              '已完成 ${(progress * 100).round()}%，先补齐${priorityCategory ?? '未完成的计分类别'}。',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ],
          if (groups.isNotEmpty) ...[
            SizedBox(height: theme.spacing.m),
            Container(height: theme.layout.divider, color: theme.color.border),
            Shortcuts(
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.arrowDown):
                    _MoveRuleCategoryIntent(1),
                SingleActivator(LogicalKeyboardKey.arrowRight):
                    _MoveRuleCategoryIntent(1),
                SingleActivator(LogicalKeyboardKey.arrowUp):
                    _MoveRuleCategoryIntent(-1),
                SingleActivator(LogicalKeyboardKey.arrowLeft):
                    _MoveRuleCategoryIntent(-1),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _MoveRuleCategoryIntent:
                      CallbackAction<_MoveRuleCategoryIntent>(
                        onInvoke: (intent) {
                          onMove?.call(intent.offset);
                          return null;
                        },
                      ),
                },
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: '计分类别',
                  child: Column(
                    children: [
                      for (var index = 0; index < groups.length; index++)
                        _RuleCategoryNavigationRow(
                          group: groups[index],
                          selected: selectedIndex == index,
                          focusNode: focusNodes[index],
                          onPressed: () => onSelected?.call(index),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RuleCategoryNavigationRow extends StatelessWidget {
  const _RuleCategoryNavigationRow({
    required this.group,
    required this.selected,
    required this.focusNode,
    required this.onPressed,
  });

  final _RuleCategoryGroup group;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  /// 构建带互斥语义和焦点状态的类别行。
  ///
  /// :param context: 当前清源主题上下文。
  /// :returns: 可操作类别行。
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final earned = _sumNumbers(
      group.items.expand((item) => item.rules.map((rule) => rule.earnedCredit)),
    );
    return YhPressable(
      semanticLabel: '${group.category}规则',
      selected: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: focusNode,
      onPressed: onPressed,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: state.hovered ? theme.color.brandTint : null,
          border: Border(
            bottom: BorderSide(
              color: theme.color.border,
              width: theme.layout.divider,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.spacing.s),
          child: child,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: theme.motion.effective(
              theme.motion.fast,
              disableAnimations: MediaQuery.disableAnimationsOf(context),
            ),
            width: theme.spacing.xs,
            height: selected ? theme.control.compact - theme.spacing.s : 0,
            decoration: BoxDecoration(
              color: theme.color.serviceSecondClass,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
          ),
          if (selected) SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emptyAsDash(group.category),
                  style: theme.typography.body.copyWith(
                    color: selected
                        ? theme.color.serviceSecondClass
                        : theme.color.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  group.passStatus.trim().isEmpty ? '状态未提供' : group.passStatus,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Text(
            '${_formatNullableCredit(earned)} / ${_formatNullableCredit(group.requiredCredit)}',
            style: theme.typography.small.copyWith(
              color: selected
                  ? theme.color.serviceSecondClass
                  : theme.color.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
