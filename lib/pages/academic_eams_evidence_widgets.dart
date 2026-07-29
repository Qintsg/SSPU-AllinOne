/* 教务 EAMS 证据页共享展示模块 — 筛选、指标与原始记录。 */

part of 'academic_page.dart';

class _AcademicEvidenceMetric {
  const _AcademicEvidenceMetric(this.value, this.label);

  final String value;
  final String label;
}

class _AcademicEamsFilterPanel extends StatelessWidget {
  const _AcademicEamsFilterPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width <= theme.breakpoint.medium;
    return YhCard(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.m + (compact ? theme.layout.controlBorder : 0),
      ),
      child: Wrap(
        spacing: theme.spacing.s,
        runSpacing: theme.spacing.s,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: children,
      ),
    );
  }
}

class _AcademicEvidenceMetricsPanel extends StatelessWidget {
  const _AcademicEvidenceMetricsPanel({required this.metrics});

  final List<_AcademicEvidenceMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.l,
        vertical: theme.spacing.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0) SizedBox(width: theme.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metrics[index].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (index == 0
                                ? theme.typography.display
                                : theme.typography.h2)
                            .copyWith(
                              color: index == 0
                                  ? theme.color.serviceAcademic
                                  : theme.color.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    metrics[index].label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcademicEvidenceRecordsPanel extends StatelessWidget {
  const _AcademicEvidenceRecordsPanel({
    required this.kicker,
    required this.title,
    required this.trailing,
    this.action,
    required this.children,
  });

  final String kicker;
  final String title;
  final String trailing;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.serviceAcademic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(title, style: theme.typography.h2),
                SizedBox(height: theme.spacing.s),
                Text(
                  trailing,
                  style: theme.typography.small.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                if (action != null) ...[
                  SizedBox(height: theme.spacing.s),
                  action!,
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker,
                        style: theme.typography.caption.copyWith(
                          color: theme.color.serviceAcademic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(title, style: theme.typography.h2),
                    ],
                  ),
                ),
                SizedBox(width: theme.spacing.m),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trailing,
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                    if (action != null) ...[
                      SizedBox(height: theme.spacing.s),
                      action!,
                    ],
                  ],
                ),
              ],
            ),
          SizedBox(height: theme.spacing.m),
          for (var index = 0; index < children.length; index++) ...[
            Container(height: theme.layout.divider, color: theme.color.border),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _AcademicEvidenceRecord extends StatelessWidget {
  const _AcademicEvidenceRecord({
    this.leading,
    required this.title,
    required this.meta,
    this.detail,
    required this.value,
    required this.status,
    this.extra,
  });

  final Widget? leading;
  final String title;
  final String meta;
  final String? detail;
  final String value;
  final String status;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.compact;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          meta,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
        if (detail != null && detail!.trim().isNotEmpty) ...[
          SizedBox(height: theme.spacing.xs),
          Text(
            detail!,
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
        ],
        if (extra != null) ...[SizedBox(height: theme.spacing.s), extra!],
      ],
    );
    final trailing = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: theme.typography.h3.copyWith(
            color: theme.color.serviceAcademic,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          status,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading ??
              Container(
                width: theme.spacing.s,
                height: theme.spacing.xl,
                decoration: BoxDecoration(
                  color: theme.color.serviceAcademic,
                  borderRadius: BorderRadius.circular(theme.radius.full),
                ),
              ),
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      SizedBox(height: theme.spacing.s),
                      trailing,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: copy),
                      SizedBox(width: theme.spacing.m),
                      trailing,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AcademicEvidenceChips extends StatelessWidget {
  const _AcademicEvidenceChips({required this.items});

  final List<AcademicGradeProcessItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
      children: [
        for (final item in items)
          Container(
            constraints: BoxConstraints(minHeight: theme.spacing.xl),
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.s,
              vertical: theme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.color.serviceAcademic.withValues(
                alpha: theme.opacity.evidenceTint,
              ),
              border: Border.all(
                color: theme.color.serviceAcademic.withValues(
                  alpha: theme.opacity.evidenceBorder,
                ),
              ),
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
                SizedBox(width: theme.spacing.xs),
                Text(
                  item.value,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.serviceAcademic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

bool _isAcademicEamsStale(AcademicEamsQueryResult? result) {
  if (result == null || !result.isSuccess) return false;
  return result.status == AcademicEamsQueryStatus.partialSuccess ||
      result.snapshot?.warnings.isNotEmpty == true ||
      result.message.contains('缓存');
}

String _academicEamsFailureDescription(
  AcademicEamsQueryResult? result, {
  required String fallback,
}) {
  final message = result?.message.trim() ?? '';
  final detail = result?.detail.trim() ?? '';
  if (message.isEmpty && detail.isEmpty) return fallback;
  if (message.isEmpty) return detail;
  if (detail.isEmpty) return message;
  return '$message：$detail';
}

String _academicEamsSnapshotNotice(AcademicEamsQueryResult result) {
  final hasCacheContext = result.message.contains('缓存');
  if (!hasCacheContext) {
    return '当前快照包含未完成来源；有效记录和筛选范围保持可用，可在原位置重新读取。';
  }
  final checkedAt = result.checkedAt.toLocal();
  final month = checkedAt.month.toString().padLeft(2, '0');
  final day = checkedAt.day.toString().padLeft(2, '0');
  final hour = checkedAt.hour.toString().padLeft(2, '0');
  final minute = checkedAt.minute.toString().padLeft(2, '0');
  return '正在显示 $month-$day $hour:$minute 缓存；刷新失败不会删除当前筛选范围与以下原始记录。';
}
