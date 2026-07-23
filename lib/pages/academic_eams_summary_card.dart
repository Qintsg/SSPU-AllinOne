/* 教务中心本专科教务摘要卡片。 */

part of 'academic_page.dart';

class AcademicEamsSummaryCard extends StatelessWidget {
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

  final AcademicEamsQueryResult? result;
  final bool isLoading;
  final bool isRefreshActionLoading;
  final bool autoRefreshEnabled;
  final RefreshActionFeedback? refreshFeedback;
  final VoidCallback onRefresh;
  final VoidCallback onOpenCourseSchedule;
  final AcademicEamsQueryResult? examResult;
  final Widget examSchedule;
  final AcademicEamsQueryResult? gradeResult;
  final Widget gradeCard;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = result?.snapshot;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AcademicEamsHeader(),
          SizedBox(height: theme.spacing.l),
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: theme.spacing.xl2 * 2,
                  child: const YhProgress(
                    showPercent: false,
                    semanticLabel: '正在读取本专科教务摘要',
                  ),
                ),
                SizedBox(width: theme.spacing.s),
                const Expanded(child: Text('正在读取本专科教务摘要...')),
              ],
            )
          else if (result == null)
            Text(
              autoRefreshEnabled
                  ? '自动刷新已开启，等待下一次读取；也可点击右上角刷新。'
                  : '自动刷新未开启。点击右上角刷新图标可手动读取；本专科教务需要校园网或学校 VPN。',
              style: theme.typography.body.copyWith(color: theme.color.muted),
            )
          else if (result!.isSuccess && snapshot != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result!.status ==
                    AcademicEamsQueryStatus.partialSuccess) ...[
                  YhBanner(
                    text: [
                      result!.message,
                      result!.detail,
                    ].where((value) => value.isNotEmpty).join('：'),
                    kind: YhBannerKind.warn,
                  ),
                  SizedBox(height: theme.spacing.m),
                ],
                _AcademicEamsSnapshotView(
                  snapshot: snapshot,
                  examSnapshot: examResult?.snapshot?.exams ?? snapshot.exams,
                  gradeSnapshot:
                      gradeResult?.snapshot?.grades ?? snapshot.grades,
                  status: result!.status,
                  onOpenCourseSchedule: onOpenCourseSchedule,
                ),
              ],
            )
          else
            _AcademicEamsFailure(result: result!),
          SizedBox(height: theme.spacing.l),
          _AcademicEamsSubcardWrap(children: [examSchedule, gradeCard]),
          SizedBox(height: theme.spacing.m),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: RefreshStatusLine(
              label: _lastRefreshLabel(result),
              labelStyle: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
              minLineHeight: theme.control.minimumTarget,
              actionReservedWidth: refreshFeedback == null
                  ? theme.control.minimumTarget
                  : theme.breakpoint.compact / 3,
              action: RefreshFeedbackAction(
                key: const Key('academic-eams-refresh'),
                tooltip: '手动刷新本专科教务',
                semanticLabel: '手动刷新本专科教务',
                isLoading: isRefreshActionLoading,
                feedback: refreshFeedback,
                onPressed: onRefresh,
                minTouchSize: theme.control.minimumTarget,
                maxFeedbackWidth: theme.breakpoint.compact / 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lastRefreshLabel(AcademicEamsQueryResult? value) {
    final time = value?.checkedAt;
    if (time == null) return '上次刷新：未刷新';
    return '上次刷新：${time.year.toString().padLeft(4, '0')}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class _AcademicEamsHeader extends StatelessWidget {
  const _AcademicEamsHeader();
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
            dimension: theme.spacing.xl2,
            child: Icon(YhIcons.academic, color: accent),
          ),
        ),
        SizedBox(width: theme.spacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('本专科教务', style: theme.typography.h3),
              ),
              SizedBox(height: theme.spacing.xs),
              Text(
                'OA 登录态只读读取个人信息、课表、成绩、考试和培养计划。',
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

class _AcademicEamsFailure extends StatelessWidget {
  const _AcademicEamsFailure({required this.result});
  final AcademicEamsQueryResult result;
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final warning =
        result.status == AcademicEamsQueryStatus.partialSuccess ||
        result.status == AcademicEamsQueryStatus.missingOaAccount ||
        result.status == AcademicEamsQueryStatus.missingOaPassword ||
        result.status == AcademicEamsQueryStatus.campusNetworkUnavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.message,
          style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: theme.spacing.s),
        YhBanner(
          text: result.detail,
          kind: warning ? YhBannerKind.warn : YhBannerKind.danger,
        ),
      ],
    );
  }
}

class _AcademicEamsSubcardWrap extends StatelessWidget {
  const _AcademicEamsSubcardWrap({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
                theme.breakpoint.medium - theme.spacing.xl2 ||
            children.length <= 1) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  SizedBox(height: theme.spacing.m),
              ],
            ],
          );
        }
        final width = (constraints.maxWidth - theme.spacing.m) / 2;
        return Wrap(
          spacing: theme.spacing.m,
          runSpacing: theme.spacing.m,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
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
    final theme = context.yhTheme;
    final profile = snapshot.profile;
    final courseCount = snapshot.courseTable?.entries.length ?? 0;
    final gradeCount = gradeSnapshot?.allRecords.length ?? 0;
    final examCount = examSnapshot?.records.length ?? 0;
    final completion = snapshot.programCompletion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile != null && profile.hasAnyValue)
          _AcademicProfileSummary(profile: profile),
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          children: [
            YhChip(label: '课表 $courseCount门', selected: courseCount > 0),
            YhChip(label: '成绩 $gradeCount条', selected: gradeCount > 0),
            YhChip(label: '考试 $examCount场', selected: examCount > 0),
            YhChip(
              label: completion == null
                  ? '培养计划 待补全'
                  : '培养计划 ${completion.completedCredits.toStringAsFixed(1)}/${(completion.completedCredits + completion.pendingCredits).toStringAsFixed(1)}学分',
              selected: completion != null,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.m),
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          children: [
            YhChip(label: '独立课程表页：${courseCount > 0 ? '已可用' : '可打开'}'),
            YhChip(label: '历史成绩：${gradeCount > 0 ? '已读取' : '待读取'}'),
            YhChip(
              label:
                  '开课检索：${snapshot.hasCourseOfferingEntry ? '入口已识别' : '入口待确认'}',
            ),
            YhChip(
              label:
                  '空闲教室：${snapshot.hasFreeClassroomEntry ? '入口已识别' : '入口待确认'}',
            ),
          ],
        ),
        if (snapshot.warnings.isNotEmpty) ...[
          SizedBox(height: theme.spacing.m),
          YhBanner(
            text:
                '${status == AcademicEamsQueryStatus.partialSuccess ? '部分数据已降级展示' : '只读入口状态'}：${snapshot.warnings.join('；')}',
            kind: YhBannerKind.warn,
          ),
        ],
        SizedBox(height: theme.spacing.l),
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          children: [
            YhButton(
              key: const Key('open-course-schedule'),
              label: '打开课程表页面',
              leadingIcon: YhIcons.calendar,
              onTap: onOpenCourseSchedule,
            ),
            if (completion != null)
              YhChip(
                label:
                    '已修 ${completion.completedCourseCount} 门，未修 ${completion.pendingCourseCount} 门',
              ),
          ],
        ),
        if (snapshot.courseTable?.entries.isNotEmpty == true) ...[
          SizedBox(height: theme.spacing.s),
          Text(
            '课表页会展示课程名称、时间、地点、教师和周次信息；当前摘要只保留统计与入口。',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
        ],
      ],
    );
  }
}

class _AcademicProfileSummary extends StatelessWidget {
  const _AcademicProfileSummary({required this.profile});
  final AcademicEamsProfile profile;
  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final items = <String>[
      if (profile.name?.isNotEmpty == true) '姓名：${profile.name}',
      if (profile.studentId?.isNotEmpty == true) '学号：${profile.studentId}',
      if (profile.department?.isNotEmpty == true) '院系：${profile.department}',
      if (profile.major?.isNotEmpty == true) '专业：${profile.major}',
      if (profile.className?.isNotEmpty == true) '班级：${profile.className}',
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.m),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.brandTint,
          border: Border.all(color: theme.color.brand),
          borderRadius: BorderRadius.circular(theme.radius.input),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.m),
            child: Wrap(
              spacing: theme.spacing.s,
              runSpacing: theme.spacing.xs,
              children: [for (final item in items) Text(item)],
            ),
          ),
        ),
      ),
    );
  }
}
