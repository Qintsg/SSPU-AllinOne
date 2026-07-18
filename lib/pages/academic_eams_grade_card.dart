/* 教务中心本专科成绩卡片 — 仅展示 GPA 与成绩门数概览。 */

part of 'academic_page.dart';

class AcademicEamsGradeCard extends StatelessWidget {
  const AcademicEamsGradeCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.onOpenDetail,
  });

  final AcademicEamsQueryResult? result;
  final bool isLoading;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = result?.snapshot?.grades;
    return YhCard(
      key: const Key('academic-eams-grade-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AcademicGradeCardHeader(
            isLoading: isLoading,
            onOpenDetail: onOpenDetail,
          ),
          SizedBox(height: theme.spacing.m),
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: theme.spacing.xl2 * 2,
                  child: const YhProgress(
                    showPercent: false,
                    semanticLabel: '正在读取成绩',
                  ),
                ),
                SizedBox(width: theme.spacing.s),
                const Expanded(child: Text('正在读取成绩...')),
              ],
            )
          else if (result == null)
            Text(
              '随本专科教务刷新读取成绩，或点击右上角查看详情。',
              style: theme.typography.body.copyWith(color: theme.color.muted),
            )
          else if (result!.isSuccess && snapshot != null)
            _AcademicGradeMetrics(
              gpa: snapshot.weightedGpaForTerm(null),
              courseCount: snapshot.allRecords.length,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result!.message,
                  style: theme.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                YhBanner(
                  text: result!.detail,
                  kind: _academicGradeBannerKind(result!.status),
                ),
              ],
            ),
        ],
      ),
    );
  }

  YhBannerKind _academicGradeBannerKind(AcademicEamsQueryStatus status) {
    return switch (status) {
      AcademicEamsQueryStatus.success => YhBannerKind.success,
      AcademicEamsQueryStatus.partialSuccess ||
      AcademicEamsQueryStatus.missingOaAccount ||
      AcademicEamsQueryStatus.missingOaPassword ||
      AcademicEamsQueryStatus.campusNetworkUnavailable => YhBannerKind.warn,
      _ => YhBannerKind.danger,
    };
  }
}

class _AcademicGradeCardHeader extends StatelessWidget {
  const _AcademicGradeCardHeader({
    required this.isLoading,
    required this.onOpenDetail,
  });

  final bool isLoading;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.color.sunken,
            border: Border.all(color: accent),
            borderRadius: BorderRadius.circular(theme.radius.s),
          ),
          child: SizedBox.square(
            dimension: theme.control.compact,
            child: Icon(YhIcons.certificate, color: accent),
          ),
        ),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('成绩', style: theme.typography.h3),
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                isLoading ? '正在同步成绩' : '成绩与绩点',
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.s),
        YhTooltip(
          message: '查看成绩详情',
          child: YhIconButton(
            key: const Key('academic-eams-grade-detail'),
            icon: YhIcons.chevronRight,
            semanticLabel: '查看成绩详情',
            onTap: onOpenDetail,
          ),
        ),
      ],
    );
  }
}

class _AcademicGradeMetrics extends StatelessWidget {
  const _AcademicGradeMetrics({required this.gpa, required this.courseCount});

  final double? gpa;
  final int courseCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (courseCount == 0) {
      return Text(
        '当前账号暂无可展示的成绩。',
        style: theme.typography.caption.copyWith(color: theme.color.muted),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _AcademicGradeMetricTile(
            value: gpa == null ? '—' : gpa!.toStringAsFixed(2),
            label: '平均绩点 GPA',
          ),
        ),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: _AcademicGradeMetricTile(
            value: courseCount.toString(),
            suffix: '门',
            label: '成绩门数',
          ),
        ),
      ],
    );
  }
}

class _AcademicGradeMetricTile extends StatelessWidget {
  const _AcademicGradeMetricTile({
    required this.value,
    required this.label,
    this.suffix = '',
  });

  final String value;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceAcademic;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.input),
        border: Border.all(color: theme.color.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.h2.copyWith(color: accent),
                  ),
                ),
                if (suffix.isNotEmpty) ...[
                  SizedBox(width: theme.spacing.xs),
                  Text(
                    suffix,
                    style: theme.typography.caption.copyWith(color: accent),
                  ),
                ],
              ],
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatGradeCredit(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

String _gradeText(String? value, {String placeholder = '-'}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? placeholder : text;
}
