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
  final SportsAttendanceQueryResult? result;
  final bool isLoading;
  final bool autoRefreshEnabled;
  final AcademicDetailRefreshTask<SportsAttendanceQueryResult>? onDetailRefresh;

  const AcademicSportsAttendanceCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.autoRefreshEnabled,
    this.onDetailRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final summary = result?.summary;

    return YhCard(
      key: const Key('academic-sports-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SportsAttendanceCardHeader(
            result: result,
            summary: summary,
            canOpenDetail: result?.isSuccess == true && summary != null,
            onDetailRefresh: onDetailRefresh,
          ),
          SizedBox(height: theme.spacing.m),
          _SportsAttendanceCardContent(
            result: result,
            summary: summary,
            isLoading: isLoading,
            autoRefreshEnabled: autoRefreshEnabled,
            kindForStatus: _sportsAttendanceBannerKind,
          ),
          SizedBox(height: theme.spacing.m),
          _SportsAttendanceCardFooter(
            lastRefreshLabel: _sportsAttendanceLastRefreshLabel(result),
          ),
        ],
      ),
    );
  }

  YhBannerKind _sportsAttendanceBannerKind(SportsAttendanceQueryStatus status) {
    return switch (status) {
      SportsAttendanceQueryStatus.success => YhBannerKind.success,
      SportsAttendanceQueryStatus.fetchDisabled ||
      SportsAttendanceQueryStatus.missingStudentId ||
      SportsAttendanceQueryStatus.missingSportsPassword ||
      SportsAttendanceQueryStatus.campusNetworkUnavailable => YhBannerKind.warn,
      SportsAttendanceQueryStatus.loginPageUnavailable ||
      SportsAttendanceQueryStatus.credentialsRejected ||
      SportsAttendanceQueryStatus.sessionUnavailable ||
      SportsAttendanceQueryStatus.parseFailed ||
      SportsAttendanceQueryStatus.networkError ||
      SportsAttendanceQueryStatus.unexpectedError => YhBannerKind.danger,
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
    required this.result,
    required this.summary,
    required this.canOpenDetail,
    required this.onDetailRefresh,
  });

  final SportsAttendanceQueryResult? result;
  final SportsAttendanceSummary? summary;
  final bool canOpenDetail;
  final AcademicDetailRefreshTask<SportsAttendanceQueryResult>? onDetailRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceSports;
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
            dimension: theme.control.compact,
            child: Icon(YhIcons.sports, color: accent),
          ),
        ),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: Semantics(
            header: true,
            child: Text('课外活动考勤', style: theme.typography.h3),
          ),
        ),
        SizedBox(width: theme.spacing.s),
        YhButton(
          label: '查看考勤记录',
          leadingIcon: YhIcons.visibility,
          variant: YhButtonVariant.secondary,
          onTap: canOpenDetail && summary != null
              ? () => Navigator.of(context).push(
                  YhPageRoute(
                    builder: (_) => SportsAttendanceDetailPage(
                      result: result,
                      onRefresh: onDetailRefresh,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _SportsAttendanceCardFooter extends StatelessWidget {
  const _SportsAttendanceCardFooter({required this.lastRefreshLabel});

  final String lastRefreshLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        lastRefreshLabel,
        style: theme.typography.caption.copyWith(color: theme.color.muted),
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
    required this.kindForStatus,
  });

  final SportsAttendanceQueryResult? result;
  final SportsAttendanceSummary? summary;
  final bool isLoading;
  final bool autoRefreshEnabled;
  final YhBannerKind Function(SportsAttendanceQueryStatus status) kindForStatus;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (isLoading) {
      return Row(
        children: [
          SizedBox(
            width: theme.spacing.xl2 * 2,
            child: const YhProgress(
              showPercent: false,
              semanticLabel: '正在读取体育部考勤',
            ),
          ),
          SizedBox(width: theme.spacing.s),
          const Expanded(child: Text('正在读取体育部考勤...')),
        ],
      );
    }

    if (result == null) {
      return Text(
        autoRefreshEnabled
            ? '自动刷新已开启，等待下一次统一读取；也可使用页面顶部的刷新按钮。'
            : '自动刷新未开启。可使用页面顶部的刷新按钮手动读取；体育查询需要校园网或学校 VPN。',
        style: theme.typography.body.copyWith(color: theme.color.muted),
      );
    }

    if (result!.isSuccess && summary != null) {
      return _SportsAttendanceSummaryView(summary: summary!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result!.message,
          style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: theme.spacing.s),
        YhBanner(text: result!.detail, kind: kindForStatus(result!.status)),
      ],
    );
  }
}

class _SportsAttendanceSummaryView extends StatelessWidget {
  const _SportsAttendanceSummaryView({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.l,
      runSpacing: theme.spacing.m,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth:
                theme.spacing.xl2 * 3 + theme.spacing.s + theme.spacing.xs,
            maxWidth: theme.breakpoint.compact / 3 + theme.spacing.l,
          ),
          child: _SportsAttendanceTotalMetric(count: summary.totalCount),
        ),
        _SportsAttendanceCountWrap(summary: summary),
      ],
    );
  }
}

class _SportsAttendanceTotalMetric extends StatelessWidget {
  const _SportsAttendanceTotalMetric({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceSports;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.color.sunken,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.input),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.m),
        child: Row(
          children: [
            Icon(YhIcons.sports, color: accent),
            SizedBox(width: theme.spacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总次数',
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    '$count 次',
                    style: theme.typography.h2.copyWith(color: accent),
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

class _SportsAttendanceCountWrap extends StatelessWidget {
  const _SportsAttendanceCountWrap({required this.summary});

  final SportsAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
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
    return YhChip(label: '${category.label} $count 次', selected: count >= 0);
  }
}
