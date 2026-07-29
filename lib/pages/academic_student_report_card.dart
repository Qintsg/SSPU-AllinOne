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

  /// 手动刷新结束后的短暂反馈。
  final RefreshActionFeedback? refreshFeedback;

  /// 手动刷新回调。
  final VoidCallback onRefresh;

  /// 详情页原地刷新 adapter。
  final AcademicDetailRefreshTask<StudentReportQueryResult>? onDetailRefresh;

  const AcademicStudentReportCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.refreshFeedback,
    required this.onRefresh,
    this.onDetailRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final summary = result?.summary;

    return YhCard(
      key: const Key('academic-student-report-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecondClassroomCardHeader(
            result: result,
            summary: summary,
            canOpenDetail: result?.isSuccess == true && summary != null,
            lastRefreshLabel: _studentReportLastRefreshLabel(result),
            isLoading: isLoading,
            refreshFeedback: refreshFeedback,
            onRefresh: onRefresh,
            onDetailRefresh: onDetailRefresh,
          ),
          SizedBox(height: theme.spacing.m),
          _SecondClassroomCardContent(
            result: result,
            summary: summary,
            isLoading: isLoading,
            autoRefreshEnabled: autoRefreshEnabled,
            kindForStatus: _studentReportBannerKind,
          ),
        ],
      ),
    );
  }

  YhBannerKind _studentReportBannerKind(StudentReportQueryStatus status) {
    return switch (status) {
      StudentReportQueryStatus.success => YhBannerKind.success,
      StudentReportQueryStatus.missingOaAccount ||
      StudentReportQueryStatus.missingOaPassword ||
      StudentReportQueryStatus.campusNetworkUnavailable => YhBannerKind.warn,
      StudentReportQueryStatus.oaLoginRequired ||
      StudentReportQueryStatus.reportSystemUnavailable ||
      StudentReportQueryStatus.secondClassroomEntryUnavailable ||
      StudentReportQueryStatus.parseFailed ||
      StudentReportQueryStatus.networkError ||
      StudentReportQueryStatus.unexpectedError => YhBannerKind.danger,
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

class _SecondClassroomCardContent extends StatelessWidget {
  const _SecondClassroomCardContent({
    required this.result,
    required this.summary,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.kindForStatus,
  });

  final StudentReportQueryResult? result;
  final SecondClassroomCreditSummary? summary;
  final bool isLoading;
  final bool autoRefreshEnabled;
  final YhBannerKind Function(StudentReportQueryStatus status) kindForStatus;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (result?.isSuccess == true && summary != null) {
      return _SecondClassroomSummaryView(summary: summary!);
    }

    if (isLoading) {
      return Row(
        children: [
          SizedBox(
            width: theme.spacing.xl2 * 2,
            child: const YhProgress(
              showPercent: false,
              semanticLabel: '正在读取第二课堂学分',
            ),
          ),
          SizedBox(width: theme.spacing.s),
          const Expanded(child: Text('正在读取第二课堂学分...')),
        ],
      );
    }

    if (result == null) {
      return Text(
        autoRefreshEnabled
            ? '自动刷新已开启，等待下一次读取；也可点击右上角刷新。'
            : '自动刷新未开启。点击右上角刷新图标可手动读取；学工报表需要校园网或学校 VPN。',
        style: theme.typography.body.copyWith(color: theme.color.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result!.message,
          style: theme.typography.body.copyWith(
            color: theme.color.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: theme.spacing.s),
        YhBanner(text: result!.detail, kind: kindForStatus(result!.status)),
      ],
    );
  }
}

class _SecondClassroomCardHeader extends StatelessWidget {
  const _SecondClassroomCardHeader({
    required this.result,
    required this.summary,
    required this.canOpenDetail,
    required this.lastRefreshLabel,
    required this.isLoading,
    required this.refreshFeedback,
    required this.onRefresh,
    required this.onDetailRefresh,
  });

  final StudentReportQueryResult? result;
  final SecondClassroomCreditSummary? summary;
  final bool canOpenDetail;
  final String lastRefreshLabel;
  final bool isLoading;
  final RefreshActionFeedback? refreshFeedback;
  final VoidCallback onRefresh;
  final AcademicDetailRefreshTask<StudentReportQueryResult>? onDetailRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceSecondClass;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: theme.spacing.l,
          child: Icon(YhIcons.education, color: accent),
        ),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('第二课堂学分', style: theme.typography.h3),
              ),
              SizedBox(height: theme.spacing.xs),
              _buildRefreshLine(context),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.s),
        YhTooltip(
          message: '查看第二课堂学分详情',
          child: YhIconButton(
            key: const Key('academic-student-report-detail'),
            icon: YhIcons.chevronRight,
            semanticLabel: '查看第二课堂学分详情',
            variant: YhIconButtonVariant.ghost,
            onTap: canOpenDetail && summary != null
                ? () => Navigator.of(context).push(
                    YhPageRoute(
                      builder: (_) => StudentReportDetailPage(
                        result: result,
                        onRefresh: onDetailRefresh,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshLine(BuildContext context) {
    final theme = context.yhTheme;
    return RefreshStatusLine(
      label: lastRefreshLabel,
      labelStyle: theme.typography.caption.copyWith(color: theme.color.muted),
      minLineHeight: theme.control.minimumTarget,
      actionReservedWidth: refreshFeedback == null
          ? theme.control.minimumTarget
          : theme.breakpoint.compact / 3,
      action: RefreshFeedbackAction(
        key: const Key('academic-student-report-refresh'),
        tooltip: '手动刷新第二课堂学分',
        semanticLabel: '手动刷新第二课堂学分',
        isLoading: isLoading,
        feedback: refreshFeedback,
        onPressed: onRefresh,
        minTouchSize: theme.control.minimumTarget,
        maxFeedbackWidth: theme.breakpoint.compact / 3,
      ),
    );
  }
}
