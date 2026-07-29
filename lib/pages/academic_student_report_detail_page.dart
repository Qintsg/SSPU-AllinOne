/*
 * 第二课堂详情页 — 展示积分详情与规则矩阵
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

part of 'academic_page.dart';

/// 第二课堂得分明细二级页面。
class StudentReportDetailPage extends StatefulWidget {
  /// 最近一次第二课堂查询结果；加载首帧可为空。
  final StudentReportQueryResult? result;

  /// 兼容旧路由的已读取汇总。
  final SecondClassroomCreditSummary? summary;

  /// 是否正在读取第二课堂详情。
  final bool isLoading;

  /// 详情页原地刷新 seam；为空时保留只读兼容行为。
  final AcademicDetailRefreshTask<StudentReportQueryResult>? onRefresh;

  const StudentReportDetailPage({
    super.key,
    this.result,
    this.summary,
    this.isLoading = false,
    this.onRefresh,
  }) : assert(result != null || summary != null || isLoading);

  @override
  State<StudentReportDetailPage> createState() =>
      _StudentReportDetailPageState();
}

class _StudentReportDetailPageState extends State<StudentReportDetailPage> {
  late final AcademicDetailRefreshController<StudentReportQueryResult>
  _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AcademicDetailRefreshController(
      initialResult: widget.result,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.summary != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleRefreshChanged);
  }

  @override
  void didUpdateWidget(covariant StudentReportDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _refreshController.updateExternalResult(widget.result);
    }
  }

  void _handleRefreshChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshController
      ..removeListener(_handleRefreshChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final current = _refreshController.result;
    final summary = current?.summary ?? widget.summary;
    return YhTaskPage(
      title: '第二课堂成绩单',
      kicker: '课外成长',
      summary: '完成度、积分证据和规则分开呈现；刷新失败保留可核验的活动记录。',
      source: '第二课堂 · 本地快照',
      sourceSymbol: '学',
      appBarTitle: _academicTaskAppBarTitle(
        '第二课堂',
        summary?.fetchedAt ?? current?.checkedAt,
      ),
      sourceTimestamp: _academicDetailTimestamp(
        summary?.fetchedAt ?? current?.checkedAt,
      ),
      primaryActionLabel: _refreshController.isRefreshing ? '正在刷新…' : '刷新成绩单',
      onPrimaryAction:
          widget.onRefresh == null ||
              widget.isLoading ||
              _refreshController.isRefreshing
          ? null
          : () => unawaited(_refreshController.refresh(widget.onRefresh)),
      width: YhTaskPageWidth.reading,
      moreActions: [
        if (current != null && !current.isSuccess)
          YhTaskPageAction(
            label: '查看失败原因',
            onTap: () => unawaited(
              _showAcademicDetailFailure(
                context,
                title: '第二课堂读取未完成',
                message: current.message,
                detail: current.detail,
              ),
            ),
          ),
      ],
      body: _buildBody(context, theme, current, summary),
    );
  }

  Widget _buildBody(
    BuildContext context,
    YhTheme theme,
    StudentReportQueryResult? current,
    SecondClassroomCreditSummary? summary,
  ) {
    if (widget.isLoading) {
      return const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(
          title: '正在读取第二课堂成绩单',
          source: '第二课堂 · 本地快照',
        ),
      );
    }

    if ((current != null && !current.isSuccess) || summary == null) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '第二课堂成绩单暂不可用',
          message: '无法完成本次读取；检查账户或网络后可在本页重试，已有有效缓存不会被清空。',
          accent: theme.color.serviceSecondClass,
          actionLabel: '返回教务中心',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final hasNoDetails =
        summary.records.isEmpty &&
        summary.detailRecords.isEmpty &&
        summary.rules.isEmpty;
    if (hasNoDetails) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前没有第二课堂成绩单记录',
          message: '当前范围没有可展示的记录；可返回教务中心确认学期与账户后再次刷新。',
          accent: theme.color.serviceSecondClass,
          actionLabel: '返回教务中心',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final showCacheNotice = current?.message.contains('缓存') ?? false;
    final stateGap = MediaQuery.sizeOf(context).width < theme.breakpoint.compact
        ? theme.spacing.m
        : theme.spacing.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_refreshController.isRefreshing) ...[
          const YhBanner(text: '正在刷新成绩单；当前内容和返回路径保持可用，完成前已锁定重复刷新。'),
          SizedBox(height: stateGap),
        ] else if (_refreshController.retainedFailure case final failure?) ...[
          YhBanner(text: failure, kind: YhBannerKind.danger),
          SizedBox(height: stateGap),
        ] else if (showCacheNotice) ...[
          const YhBanner(
            text: '正在显示昨日缓存；刷新失败不会删除以下完成度与证据记录。',
            kind: YhBannerKind.warn,
          ),
          SizedBox(height: stateGap),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns =
                constraints.maxWidth >=
                theme.breakpoint.medium + theme.control.regular * 4;
            final summaryPanel = _SecondClassroomTotalsPanel(summary: summary);
            final recordsPanel = _StudentReportEvidencePanel(summary: summary);
            if (!useColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryPanel,
                  SizedBox(height: theme.spacing.m),
                  recordsPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 9, child: summaryPanel),
                SizedBox(width: theme.spacing.m),
                Expanded(flex: 13, child: recordsPanel),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentReportEvidencePanel extends StatelessWidget {
  const _StudentReportEvidencePanel({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final entries = _studentEvidenceEntries(summary);
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '积分证据',
          style: theme.typography.caption.copyWith(
            color: theme.color.serviceSecondClass,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        Text('已获积分记录', style: theme.typography.h2),
      ],
    );
    final action = YhButton(
      label: '查看积分规则',
      variant: YhButtonVariant.secondary,
      minWidth: compact ? double.infinity : null,
      onTap: () => Navigator.of(context).push(
        YhPageRoute(builder: (_) => StudentReportRulesPage(summary: summary)),
      ),
    );
    return YhCard(
      padding: EdgeInsets.fromLTRB(
        compact ? theme.spacing.m : theme.spacing.l,
        theme.spacing.l,
        compact ? theme.spacing.m : theme.spacing.l,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                SizedBox(height: theme.spacing.m),
                action,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: copy),
                SizedBox(width: theme.spacing.m),
                action,
              ],
            ),
          SizedBox(height: theme.spacing.m),
          Container(height: theme.layout.divider, color: theme.color.border),
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0)
              Container(
                height: theme.layout.divider,
                color: theme.color.border,
              ),
            _StudentReportEvidenceRow(entry: entries[index]),
          ],
        ],
      ),
    );
  }
}

class _StudentEvidenceEntry {
  const _StudentEvidenceEntry({
    required this.title,
    required this.meta,
    required this.detail,
    required this.credit,
    required this.status,
  });

  final String title;
  final String meta;
  final String detail;
  final String credit;
  final String status;
}

List<_StudentEvidenceEntry> _studentEvidenceEntries(
  SecondClassroomCreditSummary summary,
) {
  if (summary.detailRecords.isNotEmpty) {
    return [
      for (final detail in summary.detailRecords)
        _StudentEvidenceEntry(
          title: detail.name,
          meta: '${detail.category} · ${detail.item}',
          detail: [
            detail.level,
            detail.participation,
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          credit: '+${_formatNullableCredit(detail.earnedCredit)}',
          status: _studentEvidenceStatus(summary.records, detail.name),
        ),
    ];
  }
  return [
    for (final record in summary.records)
      _StudentEvidenceEntry(
        title: record.itemName,
        meta: record.category,
        detail: [record.semester, record.occurredAt]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(' · '),
        credit: '+${_formatCredit(record.credit)}',
        status: record.status ?? '已认定',
      ),
  ];
}

String _studentEvidenceStatus(
  List<SecondClassroomCreditRecord> records,
  String name,
) {
  for (final record in records) {
    if (record.itemName == name && record.status?.trim().isNotEmpty == true) {
      return record.status!.trim();
    }
  }
  return '已认定';
}

class _StudentReportEvidenceRow extends StatelessWidget {
  const _StudentReportEvidenceRow({required this.entry});

  final _StudentEvidenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: theme.spacing.s,
            height: theme.spacing.xl,
            decoration: BoxDecoration(
              color: theme.color.serviceSecondClass,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
          ),
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  entry.meta,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  entry.detail,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.foreground,
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
                entry.credit,
                style: theme.typography.h3.copyWith(
                  color: theme.color.serviceSecondClass,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                entry.status,
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 第二课堂规则矩阵独立页面。
class StudentReportRulesPage extends StatelessWidget {
  const StudentReportRulesPage({super.key, required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (summary.rules.isEmpty) {
      return YhPageScaffold(
        appBar: YhAppBar(
          title: '第二课堂规则',
          leading: YhIconButton(
            icon: YhIcons.back,
            semanticLabel: '返回',
            variant: YhIconButtonVariant.ghost,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: YhEmptyState(
          icon: YhIcons.library,
          title: '暂无规则矩阵',
          message: '返回教务中心刷新第二课堂学分，规则数据补全后可再次查看。',
          action: YhButton(
            label: '返回教务中心刷新',
            leadingIcon: YhIcons.back,
            variant: YhButtonVariant.secondary,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '第二课堂规则',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.expanded),
            child: _SecondClassroomRuleMatrix(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _SecondClassroomTotalsPanel extends StatelessWidget {
  const _SecondClassroomTotalsPanel({required this.summary});

  final SecondClassroomCreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final categories = _categoryProgressList(summary);
    const order = ['社会实践', '创新创业活动', '报告与讲座', '校园文化活动'];
    categories.sort(
      (left, right) =>
          order.indexOf(left.label).compareTo(order.indexOf(right.label)),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth <
            theme.breakpoint.compact + theme.control.compact;
        return _SecondClassroomCompactSummary(
          summary: summary,
          categories: categories,
          metricMinWidth: narrow
              ? theme.spacing.xl2 * 2
              : theme.spacing.xl2 * 2 + theme.spacing.m,
          categoryColumns: narrow ? 1 : 2,
          metricAccent: theme.color.serviceSecondClass,
          prominentMetrics: true,
          comfortableCategories: true,
        );
      },
    );
  }
}

class _ReportRecordField extends StatelessWidget {
  const _ReportRecordField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: theme.spacing.xl2 * 2,
        maxWidth:
            theme.breakpoint.compact / 3 + theme.spacing.m + theme.spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(_emptyAsDash(value), style: theme.typography.body),
        ],
      ),
    );
  }
}

String? _academicDetailTimestamp(DateTime? value) {
  if (value == null) return null;
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} · '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String _academicTaskAppBarTitle(String source, DateTime? value) {
  if (value == null) return '$source · 本地快照';
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '$source · ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          Text(
            message,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}
