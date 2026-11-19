/*
 * 教务总览内容网格 — 断点下的学程事实编排
 * @Project : SSPU-AllinOne
 * @File : academic_overview_content_grid.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

class _AcademicHeading extends StatelessWidget {
  const _AcademicHeading({
    required this.compact,
    required this.termLabel,
    required this.profile,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
    required this.nextExam,
    required this.onOpenSchedule,
  });

  final bool compact;
  final String termLabel;
  final AcademicEamsProfile? profile;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;
  final AcademicExamRecord? nextExam;
  final VoidCallback? onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildLayout(
        context,
        compact || constraints.maxWidth < context.yhTheme.breakpoint.medium,
      ),
    );
  }

  Widget _buildLayout(BuildContext context, bool compact) {
    final theme = context.yhTheme;
    final overview = YhMiuixCard(
      padding: EdgeInsets.all(theme.spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile?.hasAnyValue == true) ...[
            _AcademicIdentityGrid(profile: profile!, compact: compact),
            SizedBox(height: theme.spacing.l),
          ],
          _AcademicMetricsRow(
            compact: compact,
            termLabel: termLabel,
            gpa: gpa,
            earnedCredits: earnedCredits,
            gradeCount: gradeCount,
          ),
        ],
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          overview,
          SizedBox(height: theme.spacing.m),
          _AcademicNextExamCard(
            nextExam: nextExam,
            onOpenSchedule: onOpenSchedule,
          ),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: overview),
          SizedBox(width: theme.spacing.m),
          Expanded(
            flex: 4,
            child: _AcademicNextExamCard(
              nextExam: nextExam,
              onOpenSchedule: onOpenSchedule,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicIdentityGrid extends StatelessWidget {
  const _AcademicIdentityGrid({required this.profile, required this.compact});

  final AcademicEamsProfile profile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final items = <(String, String)>[
      if (profile.name?.trim().isNotEmpty == true) ('姓名', profile.name!.trim()),
      if (profile.studentId?.trim().isNotEmpty == true)
        ('学号', profile.studentId!.trim()),
      if (profile.department?.trim().isNotEmpty == true)
        ('院系', profile.department!.trim()),
      if (profile.major?.trim().isNotEmpty == true)
        ('专业', profile.major!.trim()),
      if (profile.className?.trim().isNotEmpty == true)
        ('班级', profile.className!.trim()),
    ];
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final gap = theme.spacing.m;
          final itemWidth = (constraints.maxWidth - gap) / 2;
          final double width = MediaQuery.textScalerOf(context).scale(16) > 24
              ? constraints.maxWidth
              : itemWidth;
          return Wrap(
            spacing: gap,
            runSpacing: theme.spacing.s,
            children: [
              for (final (label, value) in items)
                SizedBox(
                  width: width,
                  child: _AcademicIdentityItem(label: label, value: value),
                ),
            ],
          );
        },
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(
            child: _AcademicIdentityItem(
              label: items[index].$1,
              value: items[index].$2,
            ),
          ),
          if (index != items.length - 1) SizedBox(width: theme.spacing.s),
        ],
      ],
    );
  }
}

class _AcademicIdentityItem extends StatelessWidget {
  const _AcademicIdentityItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.copyWith(
            color: theme.color.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AcademicMetricsRow extends StatelessWidget {
  const _AcademicMetricsRow({
    required this.compact,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
  });

  final bool compact;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final metrics = <(String, String, String)>[
      ('term', '学期', termLabel),
      ('gpa', '平均绩点', gpa == null ? '—' : gpa!.toStringAsFixed(2)),
      (
        'earned-credits',
        '已获学分',
        earnedCredits == null ? '—' : earnedCredits!.toStringAsFixed(1),
      ),
      ('grade-count', '已读成绩', gradeCount == null ? '—' : '$gradeCount 门'),
    ];
    Widget metricBox((String, String, String) metric) => _AcademicMetricBox(
      label: metric.$2,
      value: metric.$3,
      balanced: true,
      compact: compact,
    );
    if (!compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('academic-metric-${metrics[index].$1}'),
                child: metricBox(metrics[index]),
              ),
            ),
            if (index != metrics.length - 1) SizedBox(width: theme.spacing.s),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            compact && constraints.maxWidth < theme.breakpoint.compact
            ? 2
            : compact
            ? 4
            : 4;
        final gap = theme.spacing.s;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                key: ValueKey('academic-metric-${metric.$1}'),
                width: itemWidth,
                child: metricBox(metric),
              ),
          ],
        );
      },
    );
  }
}
