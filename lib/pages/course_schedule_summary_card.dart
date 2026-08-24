/*
 * 课表概览卡片 — 展示当前课表摘要与学籍上下文
 * @Project : SSPU-AllinOne
 * @File : course_schedule_summary_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/academic_eams.dart';
import '../services/academic_term_service.dart';

/// 课程表页顶部的本学期概览卡片。
class CourseScheduleSummaryCard extends StatelessWidget {
  const CourseScheduleSummaryCard({
    super.key,
    required this.snapshot,
    required this.checkedAt,
    required this.autoRefreshEnabled,
    required this.autoRefreshIntervalMinutes,
  });

  /// 当前教务快照。
  final AcademicEamsSnapshot snapshot;

  /// 本次结果检查时间。
  final DateTime checkedAt;

  /// 是否开启课表自动刷新。
  final bool autoRefreshEnabled;

  /// 自动刷新间隔分钟。
  final int autoRefreshIntervalMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final profile = snapshot.profile;
    final courseTable = snapshot.courseTable!;
    final planText = _validProgramPlanText(snapshot.programCompletion);
    final metrics = [
      _CourseSummaryMetric(
        icon: YhIcons.calendar,
        label: '学期',
        value: _resolvedTermName(courseTable.termName),
      ),
      _CourseSummaryMetric(
        icon: YhIcons.education,
        label: '课程数',
        value: '${courseTable.entries.length} 门',
      ),
      _CourseSummaryMetric(
        icon: YhIcons.clock,
        label: '刷新时间',
        value: _formatTime(checkedAt),
      ),
      if (planText != null)
        _CourseSummaryMetric(
          icon: YhIcons.task,
          label: '培养计划',
          value: planText,
        ),
    ];

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CourseSummaryHeader(
            subtitle: autoRefreshEnabled
                ? '自动刷新每 $autoRefreshIntervalMinutes 分钟运行一次'
                : '自动刷新未开启，可使用右上角按钮手动读取',
          ),
          SizedBox(height: theme.spacing.m),
          _CourseSummaryMetricGrid(metrics: metrics),
          if (profile != null && profile.hasAnyValue) ...[
            SizedBox(height: theme.spacing.m),
            _CourseProfileStrip(profile: profile),
          ],
          if (snapshot.warnings.isNotEmpty) ...[
            SizedBox(height: theme.spacing.m),
            YhBanner(
              text: '课表已可用，部分教务模块仍在降级：${snapshot.warnings.join('；')}',
              kind: YhBannerKind.warn,
            ),
          ],
        ],
      ),
    );
  }

  String _resolvedTermName(String? termName) {
    final normalized = termName?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    final definition = AcademicCalendarResolver().definitionForContext(
      checkedAt,
    );
    if (definition != null) {
      return '${definition.choice.label}（按校历推断）';
    }
    return '当前日期学期未识别';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String? _validProgramPlanText(AcademicProgramCompletionSnapshot? completion) {
    if (completion == null) return null;
    final totalCredits =
        completion.completedCredits + completion.pendingCredits;
    final hasCredits = totalCredits > 0;
    final hasCourses =
        completion.completedCourseCount + completion.pendingCourseCount > 0;
    if (!hasCredits && !hasCourses) return null;
    if (!hasCredits) {
      return '${completion.completedCourseCount}/'
          '${completion.completedCourseCount + completion.pendingCourseCount} 门';
    }
    return '${completion.completedCredits.toStringAsFixed(1)}/'
        '${totalCredits.toStringAsFixed(1)} 学分';
  }
}

class _CourseSummaryHeader extends StatelessWidget {
  const _CourseSummaryHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceSchedule;
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
            dimension: theme.spacing.xl2,
            child: Icon(YhIcons.calendar, color: accent),
          ),
        ),
        SizedBox(width: theme.spacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('本学期概览', style: theme.typography.h3),
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                subtitle,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseSummaryMetricGrid extends StatelessWidget {
  const _CourseSummaryMetricGrid({required this.metrics});

  final List<_CourseSummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= theme.breakpoint.medium
            ? 4
            : width >= theme.breakpoint.compact
            ? 2
            : 1;
        final itemWidth = (width - theme.spacing.s * (columns - 1)) / columns;

        return Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          children: [
            for (final metric in metrics)
              SizedBox(width: itemWidth, child: metric),
          ],
        );
      },
    );
  }
}

class _CourseSummaryMetric extends StatelessWidget {
  const _CourseSummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceSchedule;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.input),
        border: Border.all(color: theme.color.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: theme.spacing.l, color: accent),
            SizedBox(width: theme.spacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    value,
                    softWrap: true,
                    style: theme.typography.body.copyWith(
                      color: theme.color.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseProfileStrip extends StatelessWidget {
  const _CourseProfileStrip({required this.profile});

  final AcademicEamsProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final items = [
      if (_hasText(profile.name)) ('姓名', profile.name!.trim()),
      if (_hasText(profile.department)) ('院系', profile.department!.trim()),
      if (_hasText(profile.major)) ('专业', profile.major!.trim()),
      if (_hasText(profile.className)) ('班级', profile.className!.trim()),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.input),
        border: Border.all(color: theme.color.border),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.m),
          child: Wrap(
            spacing: theme.spacing.l,
            runSpacing: theme.spacing.s,
            children: [
              for (final item in items)
                _CourseProfileItem(label: item.$1, value: item.$2),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

class _CourseProfileItem extends StatelessWidget {
  const _CourseProfileItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: theme.control.regular * 2,
        maxWidth: theme.breakpoint.compact - theme.spacing.xl2 * 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: theme.typography.body.copyWith(color: theme.color.muted),
          ),
          Flexible(
            child: Text(
              value,
              softWrap: true,
              style: theme.typography.body.copyWith(
                color: theme.color.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
