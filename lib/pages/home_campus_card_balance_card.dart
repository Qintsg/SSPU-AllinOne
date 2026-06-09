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
    final theme = FluentTheme.of(context);
    final result = _campusCardResult;
    final snapshot = result?.snapshot;

    return FluentSurface(
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampusCardHeader(context, result, snapshot),
          const SizedBox(height: FluentSpacing.l),
          if (_isLoadingCampusCard) ...[
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: FluentProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: FluentSpacing.s),
                Text('正在读取校园卡余额...'),
              ],
            ),
          ] else if (result == null) ...[
            Text(
              _campusCardAutoRefreshEnabled
                  ? '自动刷新已开启，等待下一次读取。'
                  : '自动刷新未开启，可点击标题行刷新图标读取校园卡余额。',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ] else if (result.isSuccess && snapshot != null) ...[
            _buildCampusCardBalanceSummary(context, snapshot),
          ] else ...[
            FluentInfoBar(
              title: Text(result.message),
              content: Text(result.detail),
              severity: _campusCardSeverity(result.status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampusCardHeader(
    BuildContext context,
    CampusCardQueryResult? result,
    CampusCardSnapshot? snapshot,
  ) {
    final theme = FluentTheme.of(context);
    final openDetail = snapshot == null
        ? null
        : () => _openCampusCardDetail(snapshot);

    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _campusCardLastRefreshLabel(result),
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
            FluentIconButton(
              tooltip: '刷新校园卡余额',
              icon: _isLoadingCampusCard
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.refresh),
              onPressed: _isLoadingCampusCard ? null : _loadCampusCard,
            ),
            FluentButton.transparent(
              size: FluentButtonSize.small,
              onPressed: openDetail,
              child: const Text('交易记录查询'),
            ),
            FluentIconButton(
              tooltip: snapshot == null ? '刷新后查看详情' : '查看校园卡详情',
              icon: const Icon(FluentIcons.chevronRight),
              onPressed: openDetail,
            ),
          ],
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('校园卡余额', style: theme.typography.subtitle),
              const SizedBox(height: FluentSpacing.xs),
              actions,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text('校园卡余额', style: theme.typography.subtitle)),
            actions,
          ],
        );
      },
    );
  }

  /// 构建校园卡余额和异常状态摘要。
  Widget _buildCampusCardBalanceSummary(
    BuildContext context,
    CampusCardSnapshot snapshot,
  ) {
    final theme = FluentTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final summaryWidth = constraints.maxWidth >= 720
            ? constraints.maxWidth * 0.48
            : constraints.maxWidth;
        return SizedBox(
          width: summaryWidth,
          child: Wrap(
            spacing: FluentSpacing.m,
            runSpacing: FluentSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                snapshot.balance == null
                    ? '未读取'
                    : _formatMoney(snapshot.balance!),
                style: theme.typography.titleLarge,
              ),
              if (snapshot.hasAbnormalStatus)
                _CampusCardStatusPill(status: snapshot.status),
            ],
          ),
        );
      },
    );
  }

  /// 打开校园卡详情页。
  void _openCampusCardDetail(CampusCardSnapshot snapshot) {
    Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => CampusCardDetailPage(
          initialSnapshot: snapshot,
          campusCardService: _campusCardService,
        ),
      ),
    );
  }

  FluentInfoSeverity _campusCardSeverity(CampusCardQueryStatus status) {
    return switch (status) {
      CampusCardQueryStatus.success => FluentInfoSeverity.success,
      CampusCardQueryStatus.missingOaAccount ||
      CampusCardQueryStatus.missingOaPassword ||
      CampusCardQueryStatus.campusNetworkUnavailable ||
      CampusCardQueryStatus.oaLoginRequired => FluentInfoSeverity.warning,
      CampusCardQueryStatus.cardSystemUnavailable ||
      CampusCardQueryStatus.parseFailed ||
      CampusCardQueryStatus.networkError ||
      CampusCardQueryStatus.unexpectedError => FluentInfoSeverity.error,
    };
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

class _CampusCardStatusPill extends StatelessWidget {
  const _CampusCardStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.statusWarningBackground,
        borderRadius: BorderRadius.circular(FluentRadius.medium),
        border: Border.all(
          color: colors.statusWarningForeground.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        '卡状态：$status',
        style: type.caption1.copyWith(color: colors.statusWarningForeground),
      ),
    );
  }
}
