/*
 * 教务总览事实卡片 — 指标、考试、档案与培养完成度
 * @Project : SSPU-AllinOne
 * @File : academic_overview_cards.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

class _AcademicOverviewCard extends StatelessWidget {
  const _AcademicOverviewCard({
    required this.compact,
    required this.balanced,
    required this.termLabel,
    required this.gpa,
    required this.earnedCredits,
    required this.gradeCount,
  });

  final bool compact;
  final bool balanced;
  final String termLabel;
  final double? gpa;
  final double? earnedCredits;
  final int? gradeCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final metrics = [
      ('平均绩点', gpa == null ? '—' : gpa!.toStringAsFixed(2)),
      ('已获学分', earnedCredits == null ? '—' : earnedCredits!.toStringAsFixed(1)),
      ('已读成绩', gradeCount == null ? '—' : '$gradeCount 门'),
    ];
    return _AcademicSectionCard(
      title: '本学期概览',
      summary: termLabel,
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(
                    child: SizedBox(
                      height: theme.control.regular + theme.spacing.s,
                      child: _AcademicMetricBox(
                        label: metrics[index].$1,
                        value: metrics[index].$2,
                        balanced: balanced,
                        compact: true,
                      ),
                    ),
                  ),
                  if (index != metrics.length - 1)
                    SizedBox(width: theme.spacing.s),
                ],
              ],
            )
          : Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(
                    child: _AcademicMetricBox(
                      label: metrics[index].$1,
                      value: metrics[index].$2,
                      balanced: balanced,
                      compact: false,
                    ),
                  ),
                  if (index != metrics.length - 1)
                    SizedBox(width: theme.spacing.s),
                ],
              ],
            ),
    );
  }
}

class _AcademicMetricBox extends StatelessWidget {
  const _AcademicMetricBox({
    required this.label,
    required this.value,
    required this.balanced,
    required this.compact,
  });

  final String label;
  final String value;
  final bool balanced;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact
              ? theme.spacing.s
              : balanced
              ? theme.spacing.s + theme.spacing.xs
              : theme.spacing.m,
          vertical: compact ? theme.spacing.s : theme.spacing.m,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: compact
                ? theme.control.regular + theme.spacing.s
                : theme.control.regular +
                      theme.spacing.xl +
                      theme.spacing.xs +
                      (balanced ? theme.spacing.m : 0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: compact ? theme.spacing.xs : theme.spacing.s),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact ? theme.typography.h3 : theme.typography.h2)
                    .copyWith(
                      color: theme.color.foreground,
                      fontWeight: FontWeight.w600,
                      height: YhTypographyTokens.compactLineHeight,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicNextExamCard extends StatelessWidget {
  const _AcademicNextExamCard({required this.nextExam});

  final AcademicExamRecord? nextExam;

  @override
  Widget build(BuildContext context) {
    final now =
        context
            .findAncestorWidgetOfExactType<AcademicPage>()
            ?.academicTermNow ??
        DateTime.now();
    final date = DateTime.tryParse(nextExam?.displayExamDate ?? '');
    final days = date == null
        ? null
        : DateTime(
            date.year,
            date.month,
            date.day,
          ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final dayLabel = days == null || days < 0 ? null : '$days 天';
    final detail = [
      if (date != null) '${date.month} 月 ${date.day} 日',
      if ((nextExam?.displayExamArrange ?? '').isNotEmpty)
        nextExam!.displayExamArrange!,
      if ((nextExam?.displayExamLocation ?? '').isNotEmpty)
        nextExam!.displayExamLocation!,
    ].join(' · ');
    return _AcademicSectionCard(
      title: '下一场考试',
      summary: dayLabel == null ? '当前没有已发布日期的考试' : '离考试还有 $dayLabel',
      child: nextExam == null
          ? const _AcademicInlineEmpty(text: '考试日期尚未发布')
          : _AcademicActionRow(
              passive: true,
              icon: YhIcons.calendar,
              title: nextExam!.courseName,
              detail: detail,
              trail: dayLabel?.replaceAll(' ', ''),
            ),
    );
  }
}

class _AcademicArchiveCard extends StatelessWidget {
  const _AcademicArchiveCard({
    required this.onOpenGrades,
    required this.onOpenExams,
    required this.onOpenSchedule,
    required this.onOpenProgramPlan,
    required this.onOpenFreeClassrooms,
  });

  final VoidCallback? onOpenGrades;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenSchedule;
  final VoidCallback? onOpenProgramPlan;
  final VoidCallback? onOpenFreeClassrooms;

  @override
  Widget build(BuildContext context) {
    return _AcademicSectionCard(
      title: '学习档案',
      summary: '进入详情后仍保留来源、学期和返回上下文。',
      child: Column(
        children: [
          _AcademicActionRow(
            key: const ValueKey('academic-overview-grade'),
            icon: YhIcons.academic,
            title: '课程成绩',
            detail: '按学期查看成绩与过程分',
            trail: '›',
            onTap: onOpenGrades,
          ),
          _AcademicActionRow(
            key: const ValueKey('academic-overview-exam'),
            icon: YhIcons.calendar,
            title: '考试安排',
            detail: '时间、地点与考试类型',
            trail: '›',
            onTap: onOpenExams,
          ),
          _AcademicActionRow(
            key: const ValueKey('academic-overview-schedule'),
            icon: YhIcons.info,
            title: '课程表',
            detail: '当前周次、节次和上课地点',
            trail: '›',
            onTap: onOpenSchedule,
          ),
          _AcademicActionRow(
            key: const ValueKey('academic-overview-program-plan'),
            icon: YhIcons.academic,
            title: '培养方案',
            detail: '模块学分进度与课程要求',
            trail: '›',
            onTap: onOpenProgramPlan,
          ),
          _AcademicActionRow(
            key: const ValueKey('academic-overview-free-classrooms'),
            icon: YhIcons.location,
            title: '空闲教室',
            detail: '按日期与节次查找学习空间',
            trail: '›',
            onTap: onOpenFreeClassrooms,
          ),
        ],
      ),
    );
  }
}

class _AcademicCompletionCard extends StatelessWidget {
  const _AcademicCompletionCard({
    required this.value,
    required this.completedCredits,
    required this.totalCredits,
  });

  final double value;
  final double? completedCredits;
  final double totalCredits;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final creditLabel = completedCredits == null || totalCredits <= 0
        ? '—'
        : '${completedCredits!.toStringAsFixed(0)}/${totalCredits.toStringAsFixed(0)}';
    return _AcademicSectionCard(
      title: '完成度',
      summary: '状态色只表达完成情况，不替代教务域色。',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.sunken,
          borderRadius: BorderRadius.circular(theme.radius.m),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '毕业要求',
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.s),
              Text(
                '${(value * 100).round()}%',
                style: theme.typography.h2.copyWith(
                  color: theme.color.foreground,
                  fontWeight: FontWeight.w600,
                  height: YhTypographyTokens.compactLineHeight,
                  fontFamily: YhTypographyTokens.fontFamilyMono,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Row(
                children: [
                  Expanded(
                    child: YhProgressBar(
                      value: value,
                      semanticLabel: '毕业要求完成度',
                    ),
                  ),
                  SizedBox(width: theme.spacing.s),
                  Text(
                    creditLabel,
                    style: theme.typography.small.copyWith(
                      color: theme.color.muted,
                      fontWeight: FontWeight.w600,
                      fontFamily: YhTypographyTokens.fontFamilyMono,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicSectionCard extends StatelessWidget {
  const _AcademicSectionCard({
    required this.title,
    required this.summary,
    required this.child,
  });

  final String title;
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      padding: EdgeInsets.all(theme.spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.typography.h3.copyWith(
              color: theme.color.foreground,
              fontWeight: FontWeight.w600,
              height: theme.typography.h3.height,
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            summary,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          child,
        ],
      ),
    );
  }
}

class _AcademicActionRow extends StatelessWidget {
  const _AcademicActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.trail,
    this.onTap,
    this.passive = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? trail;
  final VoidCallback? onTap;
  final bool passive;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final content = Padding(
      padding: EdgeInsets.all(theme.spacing.s),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.brandTint,
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: SizedBox.square(
              dimension: theme.control.compact,
              child: Icon(
                icon,
                size: theme.control.compact / 2,
                color: theme.color.brandStrong,
              ),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.copyWith(
                    color: theme.color.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
          if (trail != null) ...[
            SizedBox(width: theme.spacing.s),
            Text(
              trail!,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        ],
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            theme.control.minimumTarget +
            (MediaQuery.sizeOf(context).width >= theme.breakpoint.medium &&
                    MediaQuery.sizeOf(context).width < theme.breakpoint.expanded
                ? theme.spacing.m + theme.spacing.xs
                : theme.spacing.s + theme.layout.divider * 2),
      ),
      child: onTap == null && !passive
          ? Opacity(opacity: theme.opacity.disabled, child: content)
          : onTap == null
          ? content
          : YhPressable(
              semanticLabel: '$title，$detail',
              onPressed: onTap,
              builder: (context, state, child) => DecoratedBox(
                decoration: BoxDecoration(
                  color: state.hovered || state.pressed
                      ? theme.color.sunken
                      : theme.color.surface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(theme.radius.input),
                ),
                child: child,
              ),
              child: content,
            ),
    );
  }
}

class _AcademicInlineEmpty extends StatelessWidget {
  const _AcademicInlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.yhTheme.typography.small.copyWith(
      color: context.yhTheme.color.muted,
    ),
  );
}
