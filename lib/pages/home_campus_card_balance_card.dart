/*
 * 主页校园卡余额卡片 — 展示余额并提供交易记录入口
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_balance_card.dart
 * @Author : Qintsg
 * @Date : 2026-05-01
 */

part of 'home_page.dart';

extension _HomeCampusCardBalanceCard on _HomePageState {
  Widget _buildCampusCardBalanceCard(
    BuildContext context, {
    required bool compact,
  }) {
    final theme = context.yhTheme;
    final result = _campusCardResult;
    final snapshot = result?.snapshot;
    final state = _homeCampusCardState(result, snapshot);
    final content = _homeCampusCardContent(state, result, snapshot);
    final canOpenDetails =
        (state == HomeCampusCardDisplayState.content ||
            state == HomeCampusCardDisplayState.stale ||
            state == HomeCampusCardDisplayState.operationLocked) &&
        snapshot != null;

    return _HomeOverviewCard(
      key: const Key('home-campus-card-balance-card'),
      icon: YhIcons.finance,
      color: theme.color.serviceFinance,
      title: content.title,
      detail: content.caption,
      value: content.value,
      compact: compact,
      onTap: canOpenDetails ? () => _openCampusCardDetail(snapshot) : null,
      valueColor: state == HomeCampusCardDisplayState.error
          ? theme.color.danger
          : theme.color.foreground,
    );
  }

  HomeCampusCardDisplayState _homeCampusCardState(
    CampusCardQueryResult? result,
    CampusCardSnapshot? snapshot,
  ) {
    final override = widget.campusCardDisplayStateOverride;
    if (override != null) return override;
    if (_campusCardRefreshController.isLoading) {
      return snapshot == null
          ? HomeCampusCardDisplayState.loading
          : HomeCampusCardDisplayState.operationLocked;
    }
    if (result == null ||
        (result.isSuccess &&
            snapshot != null &&
            snapshot.balance == null &&
            snapshot.records.isEmpty)) {
      return HomeCampusCardDisplayState.empty;
    }
    if (!result.isSuccess || snapshot == null) {
      return HomeCampusCardDisplayState.error;
    }
    final now = widget.nowOverride ?? DateTime.now();
    if (result.message.contains('缓存') ||
        now.difference(result.checkedAt) >= const Duration(hours: 1)) {
      return HomeCampusCardDisplayState.stale;
    }
    return HomeCampusCardDisplayState.content;
  }

  _HomeCampusCardContent _homeCampusCardContent(
    HomeCampusCardDisplayState state,
    CampusCardQueryResult? result,
    CampusCardSnapshot? snapshot,
  ) {
    final balance = snapshot?.balance == null
        ? '未读取'
        : _formatMoney(snapshot!.balance!);
    return switch (state) {
      HomeCampusCardDisplayState.loading => const _HomeCampusCardContent(
        title: '校园卡',
        caption: '正在读取本地余额',
        value: '···',
        semanticLabel: '校园卡正在读取本地余额',
      ),
      HomeCampusCardDisplayState.content => _HomeCampusCardContent(
        title: '校园卡',
        caption: '今日消费 ${_todayExpense(snapshot)}',
        value: balance,
        semanticLabel: '校园卡余额 $balance，今日消费 ${_todayExpense(snapshot)}',
      ),
      HomeCampusCardDisplayState.empty => const _HomeCampusCardContent(
        title: '校园卡',
        caption: '尚未读取余额',
        value: '未读取',
        semanticLabel: '校园卡尚未读取余额',
      ),
      HomeCampusCardDisplayState.stale => _HomeCampusCardContent(
        title: '校园卡 · 本地缓存',
        caption: _staleRefreshLabel(result?.checkedAt),
        value: balance,
        semanticLabel:
            '校园卡本地缓存余额 $balance，${_staleRefreshLabel(result?.checkedAt)}',
      ),
      HomeCampusCardDisplayState.error => const _HomeCampusCardContent(
        title: '校园卡暂不可用',
        caption: '请检查 OA 登录与校园网络',
        value: '重试',
        semanticLabel: '校园卡暂不可用，请检查 OA 登录与校园网络',
      ),
      HomeCampusCardDisplayState.operationLocked => _HomeCampusCardContent(
        title: '校园卡 · 正在更新',
        caption: '旧余额仍可查看',
        value: balance,
        semanticLabel: '校园卡正在更新，旧余额 $balance 仍可查看，详情入口可用',
      ),
    };
  }

  String _todayExpense(CampusCardSnapshot? snapshot) {
    if (snapshot == null) return '¥0.00';
    final now = widget.nowOverride ?? DateTime.now();
    final prefix =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final total = snapshot.records
        .where(
          (record) => record.isExpense && record.occurredAt.startsWith(prefix),
        )
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
    return _formatMoney(total);
  }

  String _staleRefreshLabel(DateTime? checkedAt) {
    if (checkedAt == null) return '更新时间未知';
    final now = widget.nowOverride ?? DateTime.now();
    final checkedDate = DateTime(
      checkedAt.year,
      checkedAt.month,
      checkedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final prefix = today.difference(checkedDate).inDays == 1
        ? '昨天'
        : '${checkedAt.month.toString().padLeft(2, '0')} 月 '
              '${checkedAt.day.toString().padLeft(2, '0')} 日';
    return '$prefix ${checkedAt.hour.toString().padLeft(2, '0')}:'
        '${checkedAt.minute.toString().padLeft(2, '0')} 更新';
  }

  void _openCampusCardDetail(CampusCardSnapshot snapshot) {
    Navigator.of(context).push(
      YhPageRoute(
        builder: (_) => CampusCardDetailPage(
          initialSnapshot: snapshot,
          campusCardService: _campusCardService,
          nowOverride: widget.nowOverride,
        ),
      ),
    );
  }

  String _formatMoney(double value) => '¥${value.toStringAsFixed(2)}';
}

class _HomeCampusCardContent {
  const _HomeCampusCardContent({
    required this.title,
    required this.caption,
    required this.value,
    required this.semanticLabel,
  });

  final String title;
  final String caption;
  final String value;
  final String semanticLabel;
}
