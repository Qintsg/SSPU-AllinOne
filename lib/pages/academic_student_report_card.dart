/*
 * 教务中心第二课堂学分卡片 — 展示学工报表只读查询结果
 * @Project : SSPU-AllinOne
 * @File : academic_student_report_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'academic_page.dart';

/// 教务中心第二课堂学分卡片。
class AcademicStudentReportCard extends StatelessWidget {
  /// 最近一次学工报表查询结果。
  final StudentReportQueryResult? result;

  /// 当前是否正在读取学工报表系统。
  final bool isLoading;

  /// 是否已开启自动刷新。
  final bool autoRefreshEnabled;

  /// 手动刷新回调。
  final VoidCallback onRefresh;

  const AcademicStudentReportCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final summary = result?.summary;

    return FluentSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecondClassroomCardHeader(
            summary: summary,
            canOpenDetail: result?.isSuccess == true && summary != null,
            lastRefreshLabel: _studentReportLastRefreshLabel(result),
            isLoading: isLoading,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: FluentSpacing.l),
          if (result?.isSuccess == true && summary != null) ...[
            _SecondClassroomSummaryView(summary: summary),
          ] else if (isLoading) ...[
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取第二课堂学分...'),
              ],
            ),
          ] else if (result == null) ...[
            Text(
              autoRefreshEnabled
                  ? '自动刷新已开启，等待下一次读取；也可点击右上角刷新。'
                  : '自动刷新未开启。点击右上角刷新图标可手动读取；学工报表需要校园网或学校 VPN。',
            ),
          ] else ...[
            FluentInfoBar(
              title: Text(result!.message),
              content: Text(result!.detail),
              severity: _studentReportSeverity(result!.status),
            ),
          ],
        ],
      ),
    );
  }

  FluentInfoSeverity _studentReportSeverity(StudentReportQueryStatus status) {
    return switch (status) {
      StudentReportQueryStatus.success => FluentInfoSeverity.success,
      StudentReportQueryStatus.missingOaAccount ||
      StudentReportQueryStatus.missingOaPassword ||
      StudentReportQueryStatus.campusNetworkUnavailable =>
        FluentInfoSeverity.warning,
      StudentReportQueryStatus.oaLoginRequired ||
      StudentReportQueryStatus.reportSystemUnavailable ||
      StudentReportQueryStatus.secondClassroomEntryUnavailable ||
      StudentReportQueryStatus.parseFailed ||
      StudentReportQueryStatus.networkError ||
      StudentReportQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
  }

  String _studentReportLastRefreshLabel(StudentReportQueryResult? result) {
    final checkedAt = result?.checkedAt;
    if (checkedAt == null) return '上次刷新：未刷新';
    return '上次刷新：${checkedAt.year.toString().padLeft(4, '0')}-'
        '${checkedAt.month.toString().padLeft(2, '0')}-'
        '${checkedAt.day.toString().padLeft(2, '0')} '
        '${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')}';
  }
}

class _SecondClassroomCardHeader extends StatelessWidget {
  const _SecondClassroomCardHeader({
    required this.summary,
    required this.canOpenDetail,
    required this.lastRefreshLabel,
    required this.isLoading,
    required this.onRefresh,
  });

  final SecondClassroomCreditSummary? summary;
  final bool canOpenDetail;
  final String lastRefreshLabel;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluentSurfaceIcon(icon: FluentIcons.education),
        const SizedBox(width: FluentSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '第二课堂学分',
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: FluentSpacing.xxs),
              Text(
                lastRefreshLabel,
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FluentSpacing.s),
        Wrap(
          spacing: FluentSpacing.xs,
          runSpacing: FluentSpacing.xs,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FluentIconButton(
              key: const Key('academic-student-report-refresh'),
              tooltip: '手动刷新第二课堂学分',
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.refresh),
              onPressed: isLoading ? null : onRefresh,
            ),
            Button(
              key: const Key('academic-student-report-detail'),
              onPressed: canOpenDetail && summary != null
                  ? () => Navigator.of(context).push(
                      FluentPageRoute(
                        builder: (_) =>
                            StudentReportDetailPage(summary: summary!),
                      ),
                    )
                  : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('详情'),
                  SizedBox(width: 4),
                  Icon(FluentIcons.chevronRight, size: 14),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
