/*
 * 体育考勤详情页 — 使用表格展示课外活动与晨跑明细
 * @Project : SSPU-AllinOne
 * @File : academic_sports_attendance_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'academic_page.dart';

/// 体育部课外活动考勤明细二级页面。
class SportsAttendanceDetailPage extends StatefulWidget {
  /// 最近一次体育考勤查询结果；加载首帧可为空。
  final SportsAttendanceQueryResult? result;

  /// 兼容旧路由的已读取汇总。
  final SportsAttendanceSummary? summary;

  /// 是否正在读取体育考勤详情。
  final bool isLoading;

  /// 详情页原地刷新 seam；为空时保留只读兼容行为。
  final AcademicDetailRefreshTask<SportsAttendanceQueryResult>? onRefresh;

  const SportsAttendanceDetailPage({
    super.key,
    this.result,
    this.summary,
    this.isLoading = false,
    this.onRefresh,
  }) : assert(result != null || summary != null || isLoading);

  @override
  State<SportsAttendanceDetailPage> createState() =>
      _SportsAttendanceDetailPageState();
}

class _SportsAttendanceDetailPageState
    extends State<SportsAttendanceDetailPage> {
  late final AcademicDetailRefreshController<SportsAttendanceQueryResult>
  _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AcademicDetailRefreshController(
      initialResult: widget.result,
      isSuccess: (result) => result.isSuccess,
      hasUsableContent: (result) => result.summary != null,
      failureMessage: (result) => '${result.message}：${result.detail}',
    )..addListener(_handleRefreshChanged);
  }

  @override
  void didUpdateWidget(covariant SportsAttendanceDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _refreshController.updateExternalResult(widget.result);
    }
  }

  void _handleRefreshChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshController
      ..removeListener(_handleRefreshChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final current = _refreshController.result;
    final summary = current?.summary ?? widget.summary;
    return YhTaskPage(
      title: '体育考勤',
      kicker: '本学期运动记录',
      summary: '汇总与原始考勤证据按日期连续展示；移动端保留全部字段且无需横向拖动。',
      source: '体育系统 · 本地快照',
      sourceSymbol: '学',
      appBarTitle: _academicTaskAppBarTitle(
        '体育系统',
        summary?.fetchedAt ?? current?.checkedAt,
      ),
      sourceTimestamp: _academicDetailTimestamp(
        summary?.fetchedAt ?? current?.checkedAt,
      ),
      primaryActionLabel: _refreshController.isRefreshing ? '正在刷新…' : '刷新考勤',
      onPrimaryAction:
          widget.onRefresh == null ||
              widget.isLoading ||
              _refreshController.isRefreshing
          ? null
          : () => unawaited(_refreshController.refresh(widget.onRefresh)),
      width: YhTaskPageWidth.reading,
      moreActions: [
        if (current != null && !current.isSuccess)
          YhTaskPageAction(
            label: '查看失败原因',
            onTap: () => unawaited(
              _showAcademicDetailFailure(
                context,
                title: '体育考勤读取未完成',
                message: current.message,
                detail: current.detail,
              ),
            ),
          ),
      ],
      body: _buildBody(context, theme, current, summary),
    );
  }

  Widget _buildBody(
    BuildContext context,
    YhTheme theme,
    SportsAttendanceQueryResult? current,
    SportsAttendanceSummary? summary,
  ) {
    if (widget.isLoading) {
      return const _AcademicDetailStateCard(
        child: _AcademicDetailLoadingState(
          title: '正在读取体育考勤',
          source: '体育系统 · 本地快照',
        ),
      );
    }

    if ((current != null && !current.isSuccess) || summary == null) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '!',
          title: '体育考勤暂不可用',
          message: '无法完成本次读取；检查账户或网络后可在本页重试，已有有效缓存不会被清空。',
          accent: theme.color.serviceSports,
          actionLabel: '返回教务中心',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    if (summary.totalCount == 0 && summary.records.isEmpty) {
      return _AcademicDetailStateCard(
        child: _AcademicDetailMessageState(
          symbol: '○',
          title: '当前没有体育考勤记录',
          message: '当前范围没有可展示的记录；可返回教务中心确认学期与账户后再次刷新。',
          accent: theme.color.serviceSports,
          actionLabel: '返回教务中心',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final showCacheNotice = current?.message.contains('缓存') ?? false;
    final stateGap = MediaQuery.sizeOf(context).width < theme.breakpoint.compact
        ? theme.spacing.m
        : theme.spacing.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_refreshController.isRefreshing) ...[
          const YhBanner(text: '正在刷新考勤；当前内容和返回路径保持可用，完成前已锁定重复刷新。'),
          SizedBox(height: stateGap),
        ] else if (_refreshController.retainedFailure case final failure?) ...[
          YhBanner(text: failure, kind: YhBannerKind.danger),
          SizedBox(height: stateGap),
        ] else if (showCacheNotice) ...[
          const YhBanner(
            text: '正在显示昨日缓存；刷新失败不会删除以下汇总与考勤证据记录。',
            kind: YhBannerKind.warn,
          ),
          SizedBox(height: stateGap),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns =
                constraints.maxWidth >=
                theme.breakpoint.medium + theme.control.regular * 4;
            final summaryPanel = _SportsAttendanceSummaryPanel(
              summary: summary,
            );
            final recordsPanel = _SportsAttendanceRecordsPanel(
              summary: summary,
            );
            if (!useColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryPanel,
                  SizedBox(height: theme.spacing.m),
                  recordsPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 9, child: summaryPanel),
                SizedBox(width: theme.spacing.m),
                Expanded(flex: 13, child: recordsPanel),
              ],
            );
          },
        ),
      ],
    );
  }
}
