/*
 * 教务中心本专科教务摘要卡片 — 展示 EAMS 只读状态、课表、成绩、考试与培养计划概览
 * @Project : SSPU-AllinOne
 * @File : academic_eams_summary_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'academic_page.dart';

/// 教务中心本专科教务摘要卡片。
class AcademicEamsSummaryCard extends StatelessWidget {
  /// 最近一次本专科教务查询结果。
  final AcademicEamsQueryResult? result;

  /// 当前是否正在读取本专科教务系统。
  final bool isLoading;

  /// 刷新按钮是否应显示加载态，包含考试安排子查询。
  final bool isRefreshActionLoading;

  /// 是否已开启自动刷新。
  final bool autoRefreshEnabled;

  /// 手动刷新结束后的短暂反馈。
  final RefreshActionFeedback? refreshFeedback;

  /// 手动刷新回调。
  final VoidCallback onRefresh;

  /// 打开独立课程表页面回调。
  final VoidCallback onOpenCourseSchedule;

  /// 当前考试安排查询结果，用于让摘要指标跟随内嵌考试子卡片。
  final AcademicEamsQueryResult? examResult;

  /// 本专科教务内嵌考试安排子卡片。
  final Widget examSchedule;

  /// 当前成绩查询结果，用于让摘要指标跟随内嵌成绩子卡片。
  final AcademicEamsQueryResult? gradeResult;

  /// 本专科教务内嵌成绩子卡片。
  final Widget gradeCard;

  const AcademicEamsSummaryCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.isRefreshActionLoading,
    required this.autoRefreshEnabled,
    required this.refreshFeedback,
    required this.onRefresh,
    required this.onOpenCourseSchedule,
    required this.examResult,
    required this.examSchedule,
    required this.gradeResult,
    required this.gradeCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = context.fluentAccents.academic;
    final snapshot = result?.snapshot;

    return FluentSurface(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluentSectionHeader(
            title: '本专科教务',
            subtitle: 'OA 登录态只读读取个人信息、课表、成绩、考试和培养计划。',
            icon: FluentIcons.education,
            accentColor: accent,
          ),
          const SizedBox(height: FluentSpacing.l),
          if (isLoading) ...[
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取本专科教务摘要...'),
              ],
            ),
          ] else if (result == null) ...[
            Text(
              autoRefreshEnabled
                  ? '自动刷新已开启，等待下一次读取；也可点击右上角刷新。'
                  : '自动刷新未开启。点击右上角刷新图标可手动读取；本专科教务需要校园网或学校 VPN。',
            ),
          ] else if (result!.isSuccess && snapshot != null) ...[
            _AcademicEamsSnapshotView(
              snapshot: snapshot,
              examSnapshot: examResult?.snapshot?.exams ?? snapshot.exams,
              gradeSnapshot: gradeResult?.snapshot?.grades ?? snapshot.grades,
              status: result!.status,
              onOpenCourseSchedule: onOpenCourseSchedule,
            ),
          ] else ...[
            FluentInfoBar(
              title: Text(result!.message),
              content: Text(result!.detail),
              severity: _academicEamsSeverity(result!.status),
            ),
          ],
          const SizedBox(height: FluentSpacing.l),
          _AcademicEamsSubcardWrap(children: [examSchedule, gradeCard]),
          const SizedBox(height: FluentSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: RefreshStatusLine(
              label: _academicEamsLastRefreshLabel(result),
              labelStyle: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
              actionReservedWidth: refreshFeedback == null ? 32 : 180,
              action: RefreshFeedbackAction(
                key: const Key('academic-eams-refresh'),
                tooltip: '手动刷新本专科教务',
                semanticLabel: '手动刷新本专科教务',
                isLoading: isRefreshActionLoading,
                feedback: refreshFeedback,
                onPressed: onRefresh,
                minTouchSize: 32,
                size: 28,
                iconSize: 15,
                maxFeedbackWidth: 180,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FluentInfoSeverity _academicEamsSeverity(AcademicEamsQueryStatus status) {
    return switch (status) {
      AcademicEamsQueryStatus.success => FluentInfoSeverity.success,
      AcademicEamsQueryStatus.partialSuccess => FluentInfoSeverity.warning,
      AcademicEamsQueryStatus.missingOaAccount ||
      AcademicEamsQueryStatus.missingOaPassword ||
      AcademicEamsQueryStatus.campusNetworkUnavailable =>
        FluentInfoSeverity.warning,
      AcademicEamsQueryStatus.oaLoginRequired ||
      AcademicEamsQueryStatus.systemUnavailable ||
      AcademicEamsQueryStatus.readOnlyEntryUnavailable ||
      AcademicEamsQueryStatus.queryFormUnavailable ||
      AcademicEamsQueryStatus.parseFailed ||
      AcademicEamsQueryStatus.networkError ||
      AcademicEamsQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
  }

  String _academicEamsLastRefreshLabel(AcademicEamsQueryResult? result) {
    final checkedAt = result?.checkedAt;
    if (checkedAt == null) return '上次刷新：未刷新';
    return '上次刷新：${checkedAt.year.toString().padLeft(4, '0')}-'
        '${checkedAt.month.toString().padLeft(2, '0')}-'
        '${checkedAt.day.toString().padLeft(2, '0')} '
        '${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}

class _AcademicEamsSubcardWrap extends StatelessWidget {
  const _AcademicEamsSubcardWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 窄屏或仅有单个子卡片时占满整行，避免宽屏下半宽留白。
        if (constraints.maxWidth < 720 || children.length <= 1) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const SizedBox(height: FluentSpacing.m),
              ],
            ],
          );
        }
        final itemWidth = (constraints.maxWidth - FluentSpacing.m) / 2;
        return Wrap(
          spacing: FluentSpacing.m,
          runSpacing: FluentSpacing.m,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _AcademicEamsSnapshotView extends StatelessWidget {
  const _AcademicEamsSnapshotView({
    required this.snapshot,
    required this.examSnapshot,
    required this.gradeSnapshot,
    required this.status,
    required this.onOpenCourseSchedule,
  });

  final AcademicEamsSnapshot snapshot;
  final AcademicExamSnapshot? examSnapshot;
  final AcademicGradeSnapshot? gradeSnapshot;
  final AcademicEamsQueryStatus status;
  final VoidCallback onOpenCourseSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final profile = snapshot.profile;
    final courseCount = snapshot.courseTable?.entries.length ?? 0;
    final gradeCount = gradeSnapshot?.allRecords.length ?? 0;
    // 统计全部考试记录，避免考试时间未公布时摘要误显示为 0。
    final examCount = examSnapshot?.records.length ?? 0;
    final completion = snapshot.programCompletion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile != null && profile.hasAnyValue)
          _AcademicProfileSummary(profile: profile),
        Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.s,
          children: [
            _AcademicMetricPill(
              label: '课表',
              value: courseCount.toString(),
              suffix: '门',
            ),
            _AcademicMetricPill(
              label: '成绩',
              value: gradeCount.toString(),
              suffix: '条',
            ),
            _AcademicMetricPill(
              label: '考试',
              value: examCount.toString(),
              suffix: '场',
            ),
            _AcademicMetricPill(
              label: '培养计划',
              value: completion == null
                  ? '待补全'
                  : '${completion.completedCredits.toStringAsFixed(1)}/${(completion.completedCredits + completion.pendingCredits).toStringAsFixed(1)}',
              suffix: completion == null ? '' : '学分',
            ),
          ],
        ),
        const SizedBox(height: FluentSpacing.m),
        Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.s,
          children: [
            _AcademicCapabilityTag(
              icon: FluentIcons.calendar,
              label: '独立课程表页',
              value: courseCount > 0 ? '已可用' : '可打开',
            ),
            _AcademicCapabilityTag(
              icon: FluentIcons.certificate,
              label: '历史成绩',
              value: gradeCount > 0 ? '已读取' : '待读取',
            ),
            _AcademicCapabilityTag(
              icon: FluentIcons.search,
              label: '开课检索',
              value: snapshot.hasCourseOfferingEntry ? '入口已识别' : '入口待确认',
            ),
            _AcademicCapabilityTag(
              icon: FluentIcons.home,
              label: '空闲教室',
              value: snapshot.hasFreeClassroomEntry ? '入口已识别' : '入口待确认',
            ),
          ],
        ),
        if (snapshot.warnings.isNotEmpty) ...[
          const SizedBox(height: FluentSpacing.m),
          FluentInfoBar(
            title: Text(
              status == AcademicEamsQueryStatus.partialSuccess
                  ? '部分数据已降级展示'
                  : '只读入口状态',
            ),
            content: Text(snapshot.warnings.join('；')),
            severity: FluentInfoSeverity.warning,
          ),
        ],
        const SizedBox(height: FluentSpacing.l),
        Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.s,
          children: [
            FluentButton.primary(
              key: const Key('open-course-schedule'),
              onPressed: onOpenCourseSchedule,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.calendar, size: 14),
                  SizedBox(width: 6),
                  Text('打开课程表页面'),
                ],
              ),
            ),
            if (completion != null)
              FluentStatusChip(
                label:
                    '已修 ${completion.completedCourseCount} 门，未修 ${completion.pendingCourseCount} 门',
                icon: FluentIcons.certificate,
              ),
          ],
        ),
        if (snapshot.courseTable != null &&
            snapshot.courseTable!.entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FluentSpacing.s),
            child: Text(
              '课表页会展示课程名称、时间、地点、教师和周次信息；当前摘要只保留统计与入口。',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _AcademicProfileSummary extends StatelessWidget {
  const _AcademicProfileSummary({required this.profile});

  final AcademicEamsProfile profile;

  @override
  Widget build(BuildContext context) {
    final accent = context.fluentAccents.academic;
    final items = <String>[
      if (profile.name != null && profile.name!.isNotEmpty)
        '姓名：${profile.name}',
      if (profile.studentId != null && profile.studentId!.isNotEmpty)
        '学号：${profile.studentId}',
      if (profile.department != null && profile.department!.isNotEmpty)
        '院系：${profile.department}',
      if (profile.major != null && profile.major!.isNotEmpty)
        '专业：${profile.major}',
      if (profile.className != null && profile.className!.isNotEmpty)
        '班级：${profile.className}',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: FluentSpacing.m),
      padding: const EdgeInsets.all(FluentSpacing.m),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: context.fluentRadii.mediumBorder,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: FluentSpacing.s,
        runSpacing: FluentSpacing.xs,
        children: items.map((item) => Text(item)).toList(),
      ),
    );
  }
}

class _AcademicMetricPill extends StatelessWidget {
  const _AcademicMetricPill({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return FluentStatusChip(
      label: '$label $value$suffix',
      tone: FluentStatusChipTone.brand,
    );
  }
}

class _AcademicCapabilityTag extends StatelessWidget {
  const _AcademicCapabilityTag({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FluentStatusChip(label: '$label：$value', icon: icon);
  }
}
