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

  /// 手动刷新结束后的短暂反馈。
  final RefreshActionFeedback? refreshFeedback;

  /// 手动刷新回调。
  final VoidCallback onRefresh;

  const AcademicSportsAttendanceCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.refreshFeedback,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.fluentAccents.sports;
    final summary = result?.summary;

    return FluentSurface(
      key: const Key('academic-sports-card'),
      accentColor: accent,
      child: FluentStretchCardBody(
        header: _SportsAttendanceCardHeader(
          summary: summary,
          canOpenDetail: result?.isSuccess == true && summary != null,
          accentColor: accent,
        ),
        body: _SportsAttendanceCardContent(
          result: result,
          summary: summary,
          isLoading: isLoading,
          autoRefreshEnabled: autoRefreshEnabled,
          severityForStatus: _sportsAttendanceSeverity,
        ),
        footer: _SportsAttendanceCardFooter(
          lastRefreshLabel: _sportsAttendanceLastRefreshLabel(result),
          isLoading: isLoading,
          refreshFeedback: refreshFeedback,
          onRefresh: onRefresh,
        ),
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

class _SportsAttendanceCardHeader extends StatelessWidget {
  const _SportsAttendanceCardHeader({
    required this.summary,
    required this.canOpenDetail,
    required this.accentColor,
  });

  final SportsAttendanceSummary? summary;
  final bool canOpenDetail;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final title = Semantics(
      header: true,
      child: Text(
        '课外活动考勤',
        style: type.subtitle2.copyWith(color: colors.neutralForeground1),
      ),
    );
    final detailAction = _buildDetailAction(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        if (compact) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FluentSurfaceIcon(icon: FluentIcons.running, color: accentColor),
              const SizedBox(width: FluentSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: FluentSpacing.xs),
                    Align(alignment: Alignment.centerLeft, child: detailAction),
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FluentSurfaceIcon(icon: FluentIcons.running, color: accentColor),
            const SizedBox(width: FluentSpacing.m),
            Expanded(child: title),
            const SizedBox(width: FluentSpacing.s),
            detailAction,
          ],
        );
      },
    );
  }

  Widget _buildDetailAction(BuildContext context) {
    return FluentButton.primary(
      onPressed: canOpenDetail && summary != null
          ? () => Navigator.of(context).push(
              FluentPageRoute(
                builder: (_) => SportsAttendanceDetailPage(summary: summary!),
              ),
            )
          : null,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.list, size: 14),
          SizedBox(width: 6),
          Text('查看考勤记录'),
        ],
      ),
    );
  }
}

class _SportsAttendanceCardFooter extends StatelessWidget {
  const _SportsAttendanceCardFooter({
    required this.lastRefreshLabel,
    required this.isLoading,
    required this.refreshFeedback,
    required this.onRefresh,
  });

  final String lastRefreshLabel;
  final bool isLoading;
  final RefreshActionFeedback? refreshFeedback;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: RefreshStatusLine(
        label: lastRefreshLabel,
        labelStyle: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorSecondary,
        ),
        actionReservedWidth: refreshFeedback == null ? 32 : 180,
        action: RefreshFeedbackAction(
          key: const Key('academic-sports-refresh'),
          tooltip: '手动刷新体育考勤',
          semanticLabel: '手动刷新体育考勤',
          isLoading: isLoading,
          feedback: refreshFeedback,
          onPressed: onRefresh,
          minTouchSize: 32,
          size: 28,
          iconSize: 15,
          maxFeedbackWidth: 180,
        ),
      ),
    );
  }
}

class _SportsAttendanceCardContent extends StatelessWidget {
  const _SportsAttendanceCardContent({
    required this.result,
    required this.summary,
    required this.isLoading,
    required this.autoRefreshEnabled,
    required this.severityForStatus,
  });

  final SportsAttendanceQueryResult? result;
  final SportsAttendanceSummary? summary;
  final bool isLoading;
  final bool autoRefreshEnabled;
  final FluentInfoSeverity Function(SportsAttendanceQueryStatus status)
  severityForStatus;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: FluentProgressRing(strokeWidth: 2),
          ),
          SizedBox(width: FluentSpacing.s),
          Text('正在读取体育部考勤...'),
        ],
      );
    }

    if (result == null) {
      return Text(
        autoRefreshEnabled
            ? '自动刷新已开启，等待下一次读取；也可点击卡片底部刷新图标。'
            : '自动刷新未开启。点击卡片底部刷新图标可手动读取；体育查询需要校园网或学校 VPN。',
      );
    }

    if (result!.isSuccess && summary != null) {
      return _SportsAttendanceSummaryView(summary: summary!);
    }

    return FluentInfoBar(
      title: Text(result!.message),
      content: Text(result!.detail),
      severity: severityForStatus(result!.status),
    );
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
        Wrap(
          spacing: FluentSpacing.l,
          runSpacing: FluentSpacing.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 156, maxWidth: 220),
              child: FluentMetricCard(
                label: '总次数',
                value: '${summary.totalCount}',
                suffix: '次',
                icon: FluentIcons.running,
                tone: FluentStatusChipTone.success,
              ),
            ),
            _SportsAttendanceCountWrap(summary: summary),
          ],
        ),
      ],
    );
  }
}

class _SportsAttendanceCountWrap extends StatelessWidget {
  const _SportsAttendanceCountWrap({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
