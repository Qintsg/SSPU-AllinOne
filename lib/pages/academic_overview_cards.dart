/*
 * 教务总览事实卡片 — 指标、考试、档案与培养完成度
 * @Project : SSPU-AllinOne
 * @File : academic_overview_cards.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_page.dart';

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
  const _AcademicNextExamCard({
    required this.nextExam,
    required this.onOpenSchedule,
  });

  final AcademicExamRecord? nextExam;
  final VoidCallback? onOpenSchedule;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (nextExam == null)
            const _AcademicInlineEmpty(text: '考试日期尚未发布')
          else
            _AcademicActionRow(
              icon: YhIcons.calendar,
              title: nextExam!.courseName,
              detail: detail,
              trail: dayLabel?.replaceAll(' ', ''),
            ),
          SizedBox(height: context.yhTheme.spacing.m),
          YhButton(
            key: const Key('academic-open-course-schedule'),
            label: '查看课表与考试',
            variant: YhButtonVariant.secondary,
            onTap: onOpenSchedule,
          ),
        ],
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
    required this.icon,
    required this.title,
    required this.detail,
    this.trail,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? trail;

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
      child: content,
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
