/*
 * 教务中心体育考勤卡片 — 展示体育部课外活动考勤汇总与明细入口
 * @Project : SSPU-AllinOne
 * @File : academic_sports_attendance_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'academic_page.dart';

/// 教务中心体育部课外活动考勤卡片。
class AcademicSportsAttendanceCard extends StatelessWidget {
  /// 最近一次体育部考勤查询结果。
  final SportsAttendanceQueryResult? result;

  /// 当前是否正在读取体育部系统。
  final bool isLoading;

  /// 是否已开启自动刷新。
  final bool autoRefreshEnabled;

  /// 手动刷新回调。
  final VoidCallback onRefresh;

  const AcademicSportsAttendanceCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final summary = result?.summary;

    return FluentSurface(
      accentColor: theme.resources.systemFillColorSuccess,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluentSectionHeader(
            title: '课外活动考勤',
            subtitle: '数据来自体育部查询系统，使用学工号和体育部查询密码登录。',
            icon: FluentIcons.running,
            accentColor: theme.resources.systemFillColorSuccess,
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
                Text('正在读取体育部考勤...'),
              ],
            ),
          ] else if (result == null) ...[
            Text(
              autoRefreshEnabled
                  ? '自动刷新已开启，等待下一次读取；也可点击右上角刷新。'
                  : '自动刷新未开启。点击右上角刷新图标可手动读取；体育查询需要校园网或学校 VPN。',
            ),
          ] else if (result!.isSuccess && summary != null) ...[
            _SportsAttendanceSummaryView(summary: summary),
          ] else ...[
            FluentInfoBar(
              title: Text(result!.message),
              content: Text(result!.detail),
              severity: _sportsAttendanceSeverity(result!.status),
            ),
          ],
          const SizedBox(height: FluentSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: FluentSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _sportsAttendanceLastRefreshLabel(result),
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                FluentIconButton(
                  key: const Key('academic-sports-refresh'),
                  tooltip: '手动刷新体育考勤',
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: FluentProgressRing(strokeWidth: 2),
                        )
                      : const Icon(FluentIcons.refresh),
                  onPressed: isLoading ? null : onRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FluentInfoSeverity _sportsAttendanceSeverity(
    SportsAttendanceQueryStatus status,
  ) {
    return switch (status) {
      SportsAttendanceQueryStatus.success => FluentInfoSeverity.success,
      SportsAttendanceQueryStatus.missingStudentId ||
      SportsAttendanceQueryStatus.missingSportsPassword ||
      SportsAttendanceQueryStatus.campusNetworkUnavailable =>
        FluentInfoSeverity.warning,
      SportsAttendanceQueryStatus.loginPageUnavailable ||
      SportsAttendanceQueryStatus.credentialsRejected ||
      SportsAttendanceQueryStatus.sessionUnavailable ||
      SportsAttendanceQueryStatus.parseFailed ||
      SportsAttendanceQueryStatus.networkError ||
      SportsAttendanceQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
  }

  String _sportsAttendanceLastRefreshLabel(
    SportsAttendanceQueryResult? result,
  ) {
    final checkedAt = result?.checkedAt;
    if (checkedAt == null) return '上次刷新：未刷新';
    return '上次刷新：${checkedAt.year.toString().padLeft(4, '0')}-'
        '${checkedAt.month.toString().padLeft(2, '0')}-'
        '${checkedAt.day.toString().padLeft(2, '0')} '
        '${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}

class _SportsAttendanceSummaryView extends StatelessWidget {
  const _SportsAttendanceSummaryView({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentMetricCard(
          label: '总次数',
          value: '${summary.totalCount}',
          suffix: '次',
          icon: FluentIcons.running,
          tone: FluentStatusChipTone.success,
        ),
        const SizedBox(height: FluentSpacing.m),
        Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.s,
          children: [
            _SportsAttendanceCountPill(
              category: SportsAttendanceCategory.morningExercise,
              count: summary.morningExerciseCount,
            ),
            _SportsAttendanceCountPill(
              category: SportsAttendanceCategory.extracurricularActivity,
              count: summary.extracurricularActivityCount,
            ),
            _SportsAttendanceCountPill(
              category: SportsAttendanceCategory.countAdjustment,
              count: summary.countAdjustmentCount,
            ),
            _SportsAttendanceCountPill(
              category: SportsAttendanceCategory.sportsCorridor,
              count: summary.sportsCorridorCount,
            ),
          ],
        ),
        const SizedBox(height: FluentSpacing.l),
        FluentButton.primary(
          onPressed: () => Navigator.of(context).push(
            FluentPageRoute(
              builder: (_) => SportsAttendanceDetailPage(summary: summary),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.list, size: 14),
              SizedBox(width: 6),
              Text('查看考勤记录'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SportsAttendanceCountPill extends StatelessWidget {
  const _SportsAttendanceCountPill({
    required this.category,
    required this.count,
  });

  final SportsAttendanceCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return FluentStatusChip(
      label: '${category.label} $count 次',
      tone: count < 0
          ? FluentStatusChipTone.warning
          : FluentStatusChipTone.brand,
    );
  }
}

/// 体育部课外活动考勤明细二级页面。
class SportsAttendanceDetailPage extends StatelessWidget {
  /// 已读取的考勤汇总与明细。
  final SportsAttendanceSummary summary;

  const SportsAttendanceDetailPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentPage.scrollable(
      header: FluentPageHeader(
        title: const Text('课外活动考勤记录'),
        commandBar: FluentButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
      ),
      children: [
        FluentCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(FluentSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('汇总', style: theme.typography.bodyStrong),
                const SizedBox(height: FluentSpacing.s),
                Text(
                  '总次数 ${summary.totalCount} 次，明细 ${summary.records.length} 条。',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FluentSpacing.m),
        if (summary.records.isEmpty)
          const FluentInfoBar(
            title: Text('暂无明细记录'),
            content: Text('体育部页面返回了汇总次数，但没有可展示的考勤明细。'),
            severity: FluentInfoSeverity.info,
          )
        else
          ...summary.records.map(_buildRecordCard),
      ],
    );
  }

  /// 构建单条考勤记录卡片，未知字段使用原始单元格兜底。
  Widget _buildRecordCard(SportsAttendanceRecord record) {
    final titleParts = [
      record.category.label,
      if (record.occurredAt != null) record.occurredAt!,
    ];
    final details = [
      if (record.project != null) '项目：${record.project}',
      if (record.location != null) '地点：${record.location}',
      if (record.remark != null) '备注：${record.remark}',
      if (record.cells.isNotEmpty) '原始记录：${record.cells.join(' / ')}',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: FluentSpacing.s),
      child: FluentCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(FluentSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(titleParts.join(' · '))),
                  Text('${record.count} 次'),
                ],
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: FluentSpacing.xs),
                Text(details.join('\n')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
