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
    required this.balanced,
    required this.onRefresh,
  });

  final bool compact;
  final bool balanced;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final copy = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '教务中心',
            style: theme.typography.small.copyWith(
              color: theme.color.brandInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Semantics(
            header: true,
            child: Text(
              compact ? '学习进度' : '学习进度，一处看全。',
              style: theme.typography.h1.copyWith(
                color: theme.color.foreground,
              ),
            ),
          ),
          SizedBox(height: theme.spacing.s),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: balanced
                  ? theme.control.regular * 9
                  : theme.layout.formContentWidth,
            ),
            child: Text(
              '成绩、考试、培养方案与体育考勤保持只读，原始来源和更新时间始终可见。',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: balanced ? theme.spacing.xl : theme.spacing.l,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copy,
          SizedBox(width: theme.spacing.m),
          if (compact)
            YhIconButton(
              key: const ValueKey('academic-overview-refresh'),
              icon: YhIcons.refresh,
              semanticLabel: '刷新教务数据',
              onTap: onRefresh,
              disabled: onRefresh == null,
            )
          else
            YhButton(
              key: const ValueKey('academic-overview-refresh'),
              label: '刷新教务数据',
              variant: YhButtonVariant.secondary,
              onTap: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _AcademicContentGrid extends StatelessWidget {
  const _AcademicContentGrid({
    required this.compact,
    required this.balanced,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
    required this.nextExam,
    required this.completionValue,
    required this.completedCredits,
    required this.totalCredits,
    required this.onOpenGrades,
    required this.onOpenExams,
    required this.onOpenSchedule,
  });

  final bool compact;
  final bool balanced;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;
  final AcademicExamRecord? nextExam;
  final double completionValue;
  final double? completedCredits;
  final double totalCredits;
  final VoidCallback? onOpenGrades;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final overview = _AcademicOverviewCard(
      compact: compact,
      balanced: balanced,
      termLabel: termLabel,
      gpa: gpa,
      earnedCredits: earnedCredits,
      gradeCount: gradeCount,
    );
    final exam = _AcademicNextExamCard(nextExam: nextExam);
    final archive = _AcademicArchiveCard(
      onOpenGrades: onOpenGrades,
      onOpenExams: onOpenExams,
      onOpenSchedule: onOpenSchedule,
    );
    final completion = _AcademicCompletionCard(
      value: completionValue,
      completedCredits: completedCredits,
      totalCredits: totalCredits,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          overview,
          SizedBox(height: theme.spacing.m),
          exam,
          SizedBox(height: theme.spacing.m),
          archive,
          SizedBox(height: theme.spacing.m),
          completion,
        ],
      );
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: balanced ? 1 : 8, child: overview),
            SizedBox(width: theme.spacing.m),
            Expanded(flex: balanced ? 1 : 4, child: exam),
          ],
        ),
        SizedBox(height: theme.spacing.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: balanced ? 1 : 7, child: archive),
            SizedBox(width: theme.spacing.m),
            Expanded(flex: balanced ? 1 : 5, child: completion),
          ],
        ),
      ],
    );
  }
}
