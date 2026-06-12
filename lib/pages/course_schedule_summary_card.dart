/*
 * 课表概览卡片 — 展示当前课表摘要与学籍上下文
 * @Project : SSPU-AllinOne
 * @File : course_schedule_summary_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import '../design/fluent_ui.dart';
import '../models/academic_eams.dart';
import '../services/academic_term_service.dart';
import '../theme/fluent_tokens.dart';

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
    final profile = snapshot.profile;
    final courseTable = snapshot.courseTable!;
    final planText = _validProgramPlanText(snapshot.programCompletion);
    final metrics = [
      _CourseSummaryMetric(
        icon: FluentIcons.calendarWeek,
        label: '学期',
        value: _resolvedTermName(courseTable.termName),
      ),
      _CourseSummaryMetric(
        icon: FluentIcons.education,
        label: '课程数',
        value: '${courseTable.entries.length} 门',
      ),
      _CourseSummaryMetric(
        icon: FluentIcons.clock,
        label: '刷新时间',
        value: _formatTime(checkedAt),
      ),
      if (planText != null)
        _CourseSummaryMetric(
          icon: FluentIcons.task,
          label: '培养计划',
          value: planText,
        ),
    ];

    return FluentSurface(
      padding: const EdgeInsets.all(FluentSpacing.l),
      accentColor: context.fluentAccents.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluentSectionHeader(
            title: '本学期概览',
            subtitle: autoRefreshEnabled
                ? '自动刷新每 $autoRefreshIntervalMinutes 分钟运行一次'
                : '自动刷新未开启，可使用右上角按钮手动读取',
            icon: FluentIcons.calendar,
            accentColor: context.fluentAccents.schedule,
          ),
          const SizedBox(height: FluentSpacing.m),
          _CourseSummaryMetricGrid(metrics: metrics),
          if (profile != null && profile.hasAnyValue) ...[
            const SizedBox(height: FluentSpacing.m),
            _CourseProfileStrip(profile: profile),
          ],
          if (snapshot.warnings.isNotEmpty) ...[
            const SizedBox(height: FluentSpacing.m),
            FluentInfoBar(
              title: const Text('课表已可用，部分教务模块仍在降级'),
              content: Text(snapshot.warnings.join('；')),
              severity: FluentInfoSeverity.warning,
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

class _CourseSummaryMetricGrid extends StatelessWidget {
  const _CourseSummaryMetricGrid({required this.metrics});

  final List<_CourseSummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 4
            : width >= 560
            ? 2
            : 1;
        final itemWidth = (width - FluentSpacing.s * (columns - 1)) / columns;

        return Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.s,
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
    final colors = context.fluentColors;
    final type = context.fluentType;
    final radii = context.fluentRadii;
    final accent = context.fluentAccents.schedule;

    return Container(
      padding: const EdgeInsets.all(FluentSpacing.m),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: radii.largeBorder,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: FluentSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: type.caption1.copyWith(
                    color: colors.neutralForeground3,
                  ),
                ),
                const SizedBox(height: FluentSpacing.xxs),
                Text(
                  value,
                  softWrap: true,
                  style: type.body1Strong.copyWith(
                    color: colors.neutralForeground1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseProfileStrip extends StatelessWidget {
  const _CourseProfileStrip({required this.profile});

  final AcademicEamsProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (_hasText(profile.name)) ('姓名', profile.name!.trim()),
      if (_hasText(profile.department)) ('院系', profile.department!.trim()),
      if (_hasText(profile.major)) ('专业', profile.major!.trim()),
      if (_hasText(profile.className)) ('班级', profile.className!.trim()),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FluentSpacing.m),
      decoration: BoxDecoration(
        color: context.fluentColors.neutralBackground2,
        borderRadius: context.fluentRadii.largeBorder,
        border: Border.all(color: context.fluentColors.neutralStroke2),
      ),
      child: Wrap(
        spacing: FluentSpacing.l,
        runSpacing: FluentSpacing.s,
        children: [
          for (final item in items)
            _CourseProfileItem(label: item.$1, value: item.$2),
        ],
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
    final colors = context.fluentColors;
    final type = context.fluentType;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 360),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: type.body1.copyWith(color: colors.neutralForeground3),
          ),
          Flexible(
            child: Text(
              value,
              softWrap: true,
              style: type.body1Strong.copyWith(
                color: colors.neutralForeground1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
