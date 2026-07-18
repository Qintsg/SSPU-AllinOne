/*
 * 主页校园卡余额卡片 — 展示余额并提供交易记录入口
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_balance_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'home_page.dart';

extension _HomeCampusCardBalanceCard on _HomePageState {
  /// 构建校园卡余额卡片。
  Widget _buildCampusCardBalanceCard(BuildContext context) {
    final theme = context.yhTheme;
    final result = _campusCardResult;
    final snapshot = result?.snapshot;
    final state = result == null
        ? YhDataState.degraded
        : result.isSuccess
        ? YhDataState.ready
        : YhDataState.failed;

    return YhDashboardTile(
      key: const Key('home-campus-card-balance-card'),
      title: '校园卡余额',
      icon: YhIcons.finance,
      state: state,
      accentColor: theme.color.serviceFinance,
      actions: [
        _CampusCardHeaderDetailAction(
          label: '交易记录查询',
          tooltip: snapshot == null ? '刷新后查看详情' : '交易记录查询',
          onPressed: snapshot == null
              ? null
              : () => _openCampusCardDetail(snapshot),
        ),
      ],
      footer: RefreshStatusLine(
        label: _campusCardLastRefreshLabel(result),
        labelStyle: theme.typography.caption.copyWith(color: theme.color.muted),
        actionReservedWidth: _campusCardRefreshController.feedback == null
            ? theme.control.compact
            : theme.spacing.xl2 * 2 + theme.spacing.m,
        action: RefreshFeedbackAction(
          key: const Key('home-campus-card-refresh'),
          tooltip: '刷新校园卡余额',
          semanticLabel: '刷新校园卡余额',
          isLoading: _campusCardRefreshController.isLoading,
          feedback: _campusCardRefreshController.feedback,
          onPressed: _loadCampusCard,
          minTouchSize: theme.control.minimumTarget,
          maxFeedbackWidth: theme.spacing.xl2 * 2 + theme.spacing.m,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: result?.isSuccess == false
              ? theme.control.regular + theme.spacing.xl + theme.spacing.s
              : theme.control.regular + theme.spacing.m,
        ),
        child: _buildCampusCardBody(context, result, snapshot),
      ),
    );
  }

  Widget _buildCampusCardBody(
    BuildContext context,
    CampusCardQueryResult? result,
    CampusCardSnapshot? snapshot,
  ) {
    final theme = context.yhTheme;
    if (result == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _campusCardRefreshController.autoRefreshEnabled
              ? '自动刷新已开启，等待下一次读取。'
              : '自动刷新未开启，可点击刷新图标读取校园卡余额。',
          style: theme.typography.caption.copyWith(color: theme.color.muted),
        ),
      );
    }
    if (result.isSuccess && snapshot != null) {
      return _buildCampusCardBalanceSummary(context, snapshot);
    }
    return _CampusCardFailureSummary(result: result);
  }

  /// 构建校园卡余额和异常状态摘要。
  Widget _buildCampusCardBalanceSummary(
    BuildContext context,
    CampusCardSnapshot snapshot,
  ) {
    final theme = context.yhTheme;
    return Wrap(
      spacing: theme.spacing.m,
      runSpacing: theme.spacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          snapshot.balance == null ? '未读取' : _formatMoney(snapshot.balance!),
          style: theme.typography.h1,
        ),
        if (snapshot.hasAbnormalStatus)
          _CampusCardStatusPill(status: snapshot.status),
      ],
    );
  }

  /// 打开校园卡详情页。
  void _openCampusCardDetail(CampusCardSnapshot snapshot) {
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => CampusCardDetailPage(
          initialSnapshot: snapshot,
          campusCardService: _campusCardService,
        ),
      ),
    );
  }

  String _campusCardLastRefreshLabel(CampusCardQueryResult? result) {
    final checkedAt = result?.checkedAt;
    if (checkedAt == null) return '上次刷新时间：未刷新';
    return '上次刷新时间：${_formatDateTime(checkedAt)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatMoney(double value) {
    return '¥${value.toStringAsFixed(2)}';
  }
}

class _CampusCardHeaderDetailAction extends StatelessWidget {
  const _CampusCardHeaderDetailAction({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return YhTooltip(
      message: tooltip,
      child: YhButton(
        label: label,
        trailingIcon: YhIcons.chevronRight,
        variant: YhButtonVariant.text,
        onTap: onPressed,
      ),
    );
  }
}

class _CampusCardFailureSummary extends StatelessWidget {
  const _CampusCardFailureSummary({required this.result});

  final CampusCardQueryResult result;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final textColor = _failureTextColor(context, result.status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: theme.typography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_detail.isNotEmpty) ...[
            SizedBox(height: theme.spacing.xs),
            Text(
              _detail,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _message {
    return switch (result.status) {
      CampusCardQueryStatus.missingOaAccount => '需要先填写 OA 账号',
      CampusCardQueryStatus.missingOaPassword => '需要先填写 OA 密码',
      _ => result.message,
    };
  }

  String get _detail {
    return switch (result.status) {
      CampusCardQueryStatus.missingOaAccount => '前往设置页保存学工号后，再刷新校园卡余额。',
      CampusCardQueryStatus.missingOaPassword => '前往设置页保存 OA 密码后，再刷新校园卡余额。',
      _ => result.detail.trim(),
    };
  }

  Color _failureTextColor(BuildContext context, CampusCardQueryStatus status) {
    return switch (status) {
      CampusCardQueryStatus.success => context.yhTheme.color.success,
      CampusCardQueryStatus.missingOaAccount ||
      CampusCardQueryStatus.missingOaPassword ||
      CampusCardQueryStatus.campusNetworkUnavailable ||
      CampusCardQueryStatus.oaLoginRequired => context.yhTheme.color.warning,
      CampusCardQueryStatus.cardSystemUnavailable ||
      CampusCardQueryStatus.parseFailed ||
      CampusCardQueryStatus.networkError ||
      CampusCardQueryStatus.unexpectedError => context.yhTheme.color.danger,
    };
  }
}

class _CampusCardStatusPill extends StatelessWidget {
  const _CampusCardStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.s,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.color.warningTint,
        borderRadius: BorderRadius.circular(theme.radius.full),
        border: Border.all(color: theme.color.warning.withValues(alpha: 0.24)),
      ),
      child: Text(
        '卡状态：$status',
        style: theme.typography.caption.copyWith(color: theme.color.warning),
      ),
    );
  }
}
