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
    final result = _campusCardResult;
    final snapshot = result?.snapshot;

    return FluentSurface(
      key: const Key('home-campus-card-balance-card'),
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCampusCardHeader(context, result, snapshot),
          const SizedBox(height: FluentSpacing.l),
          SizedBox(
            height: _campusCardBodyMinHeight,
            child: _buildCampusCardBody(context, result, snapshot),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusCardBody(
    BuildContext context,
    CampusCardQueryResult? result,
    CampusCardSnapshot? snapshot,
  ) {
    final theme = FluentTheme.of(context);
    if (result == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _campusCardAutoRefreshEnabled
              ? '自动刷新已开启，等待下一次读取。'
              : '自动刷新未开启，可点击标题行刷新图标读取校园卡余额。',
          style: theme.typography.caption?.copyWith(
            color: theme.resources.textFillColorSecondary,
          ),
        ),
      );
    }
    if (result.isSuccess && snapshot != null) {
      return _buildCampusCardBalanceSummary(context, snapshot);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: FluentInfoBar(
        title: Text(result.message),
        content: Text(result.detail),
        severity: _campusCardSeverity(result.status),
      ),
    );
  }

  static const double _campusCardBodyMinHeight = 48.0;

  Widget _buildCampusCardHeader(
    BuildContext context,
    CampusCardQueryResult? result,
    CampusCardSnapshot? snapshot,
  ) {
    final theme = FluentTheme.of(context);
    final openDetail = snapshot == null
        ? null
        : () => _openCampusCardDetail(snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('校园卡余额', style: theme.typography.subtitle)),
            _CampusCardHeaderDetailAction(
              label: '交易记录查询',
              tooltip: snapshot == null ? '刷新后查看详情' : '交易记录查询',
              onPressed: openDetail,
            ),
          ],
        ),
        const SizedBox(height: FluentSpacing.xs),
        SizedBox(
          height: 20,
          child: Wrap(
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
              _CampusCardHeaderIconAction(
                tooltip: '刷新校园卡余额',
                semanticLabel: '刷新校园卡余额',
                icon: FluentIcons.refresh,
                onPressed: _isLoadingCampusCard ? null : _loadCampusCard,
              ),
              if (_isLoadingCampusCard) _buildCampusCardLoadingHint(context),
              if (!_isLoadingCampusCard) const SizedBox(width: 1, height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampusCardLoadingHint(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: FluentProgressRing(strokeWidth: 2),
        ),
        const SizedBox(width: FluentSpacing.xs),
        Text(
          '正在刷新',
          style: theme.typography.caption?.copyWith(
            color: theme.resources.textFillColorSecondary,
          ),
        ),
      ],
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

class _CampusCardHeaderIconAction extends StatefulWidget {
  const _CampusCardHeaderIconAction({
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_CampusCardHeaderIconAction> createState() =>
      _CampusCardHeaderIconActionState();
}

class _CampusCardHeaderIconActionState
    extends State<_CampusCardHeaderIconAction> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final enabled = widget.onPressed != null;
    final backgroundColor = !enabled
        ? null
        : _pressed
        ? colors.subtleBackgroundPressed
        : _hovered
        ? colors.subtleBackgroundHover
        : null;
    final foregroundColor = enabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => _setHovered(true),
          onExit: (_) {
            _setHovered(false);
            _setPressed(false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            child: AnimatedContainer(
              duration: context.fluentMotion.durationFaster,
              curve: context.fluentMotion.curveEasyEase,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: context.fluentRadii.mediumBorder,
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, size: 16, color: foregroundColor),
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }
}

class _CampusCardHeaderDetailAction extends StatefulWidget {
  const _CampusCardHeaderDetailAction({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  State<_CampusCardHeaderDetailAction> createState() =>
      _CampusCardHeaderDetailActionState();
}

class _CampusCardHeaderDetailActionState
    extends State<_CampusCardHeaderDetailAction> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final enabled = widget.onPressed != null;
    final textColor = enabled
        ? _pressed
              ? colors.brandBackgroundPressed
              : _hovered
              ? colors.brandForeground2
              : colors.brandForeground1
        : colors.neutralForegroundDisabled;
    final backgroundColor = !enabled
        ? null
        : _pressed
        ? colors.subtleBackgroundPressed
        : _hovered
        ? colors.subtleBackgroundHover
        : null;

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.label,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => _setHovered(true),
          onExit: (_) {
            _setHovered(false);
            _setPressed(false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FluentSpacing.s,
                vertical: FluentSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: context.fluentRadii.mediumBorder,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      style: type.caption1Strong.copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: FluentSpacing.xs),
                  Icon(FluentIcons.chevronRight, size: 14, color: textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
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
