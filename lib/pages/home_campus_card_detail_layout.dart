/*
 * 校园卡详情布局 — 余额账本、查询协同与恢复状态呈现
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_detail_layout.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'home_page.dart';

/// 承载校园卡详情的页面层级与响应式查询布局。
extension _CampusCardDetailLayout on _CampusCardDetailPageState {
  /// 构建说明本地快照边界的页面标题区。
  Widget _buildPageHeading(YhTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '只读校园卡',
          style: theme.typography.caption.copyWith(
            color: theme.color.brandInk,
            fontWeight: theme.typography.semibold,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        Semantics(
          header: true,
          child: Text('余额与交易记录', style: theme.typography.h1),
        ),
        SizedBox(height: theme.spacing.s),
        Text(
          '保留本机记录供快速浏览；仅在主动查询或同步时访问校园服务。',
          style: theme.typography.body.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.m),
        YhButton(
          key: const Key('campus-card-open-analytics'),
          label: '查看消费趋势',
          variant: YhButtonVariant.secondary,
          onTap: () => Navigator.of(context).push(
            YhPageRoute(
              builder: (_) =>
                  CampusConsumptionAnalyticsPage(snapshot: _snapshot),
            ),
          ),
        ),
      ],
    );
  }

  /// 根据当前保留状态呈现不中断上下文的恢复提示。
  Widget _buildStateBanner(CampusCardDetailDisplayState state) {
    return switch (state) {
      CampusCardDetailDisplayState.stale => YhBanner(
        key: const Key('campus-card-stale-banner'),
        text:
            '正在查看 ${_formatFullTime(_snapshot.fetchedAt)} 的本地记录；'
            '主动同步后会替换为最新快照。',
        kind: YhBannerKind.warn,
      ),
      CampusCardDetailDisplayState.partialError => YhBanner(
        key: const Key('campus-card-partial-error-banner'),
        text:
            _refreshController.retainedFailure ??
            '只读同步未完成；当前余额、记录和筛选已保留，可稍后重试。',
        kind: YhBannerKind.danger,
      ),
      CampusCardDetailDisplayState.operationLocked => YhBanner(
        key: const Key('campus-card-operation-banner'),
        text:
            '${_activeOperationLabel ?? '正在只读同步记录'}；'
            '旧内容仍可浏览，请勿重复操作。',
      ),
      CampusCardDetailDisplayState.validationError ||
      CampusCardDetailDisplayState.content ||
      CampusCardDetailDisplayState.empty ||
      CampusCardDetailDisplayState.error => const SizedBox.shrink(),
    };
  }

  /// 构建没有可恢复内容时的紧凑恢复面板。
  Widget _buildTerminalErrorPanel(YhTheme theme) {
    final result = _refreshController.result;
    final message = _credentialsInvalidated
        ? '账户连接已变化，旧账户记录已从本页隐藏；请返回首页读取当前账户。'
        : result != null && !result.isSuccess
        ? '只读${_lastRemoteOperation == _CampusCardRemoteOperation.rangeQuery ? '查询' : '同步'}未完成：'
              '${_failureReason(result)}；本页没有可恢复的旧记录。'
        : '请检查 OA 登录与校园网 / VPN；本页没有可恢复的旧记录。';
    final retryQuery =
        _lastRemoteOperation == _CampusCardRemoteOperation.rangeQuery;
    return _CampusCardTerminalErrorRecoveryPanel(
      message: message,
      retryLabel: retryQuery ? '重试只读查询' : '重试只读同步',
      onRetry: _credentialsInvalidated
          ? null
          : retryQuery
          ? _queryRemoteRecords
          : _syncAllRecords,
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  /// 按可用宽度将余额账本签与查询账本排列为双列或连续单列。
  Widget _buildPrimaryContent(
    YhTheme theme,
    CampusCardDetailDisplayState displayState,
  ) {
    final balance = _buildBalanceHero(theme);
    final filter = _buildFilterPanel(theme, displayState);
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedContentWidth =
            theme.layout.pageContentWidth - theme.spacing.xl * 2;
        if (constraints.maxWidth >= expandedContentWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: theme.layout.popoverWidth, child: balance),
              SizedBox(width: theme.spacing.m),
              Expanded(child: filter),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            balance,
            SizedBox(height: theme.spacing.m),
            filter,
          ],
        );
      },
    );
  }

  /// 构建按内容高度收束的校园卡余额账本签。
  Widget _buildBalanceHero(YhTheme theme) {
    final balance = _snapshot.balance == null
        ? '未读取'
        : _formatMoney(_snapshot.balance!);
    final status = _snapshot.status.trim().isEmpty ? '未读取' : _snapshot.status;
    final semantics =
        '校园卡余额 $balance，卡状态 $status，'
        '${_formatTime(_snapshot.fetchedAt)} 更新';
    return Semantics(
      label: semantics,
      container: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: const Key('campus-card-balance-hero'),
          decoration: BoxDecoration(
            color: theme.color.brandStrong,
            borderRadius: BorderRadius.circular(theme.radius.l),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '校园卡余额',
                  style: theme.typography.small.copyWith(
                    color: theme.color.onStructural.withValues(
                      alpha: theme.opacity.contentMuted,
                    ),
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                Text(
                  balance,
                  style: theme.typography.display.copyWith(
                    color: theme.color.onStructural,
                    fontFamily: YhTypographyTokens.fontFamilyMono,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                Wrap(
                  spacing: theme.spacing.m,
                  runSpacing: theme.spacing.xs,
                  children:
                      [
                            Text('卡状态 · $status'),
                            Text('${_formatTime(_snapshot.fetchedAt)} 更新'),
                          ]
                          .map((text) {
                            return DefaultTextStyle.merge(
                              style: theme.typography.caption.copyWith(
                                color: theme.color.onStructural.withValues(
                                  alpha: theme.opacity.contentMuted,
                                ),
                              ),
                              child: text,
                            );
                          })
                          .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建将本地快捷筛选与两类远端动作明确分级的交易查询账本。
  Widget _buildFilterPanel(
    YhTheme theme,
    CampusCardDetailDisplayState displayState,
  ) {
    final remoteLocked =
        displayState == CampusCardDetailDisplayState.operationLocked;
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('交易记录', style: theme.typography.h3),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      '日期用于远端只读查询，收支方向在本机即时筛选。',
                      style: theme.typography.body.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
              YhButton(
                key: const Key('campus-card-recent-seven-days'),
                label: '近 7 天',
                variant: YhButtonVariant.text,
                onTap: remoteLocked ? null : () => _queryPresetDays(7),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.s),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldsNeedOwnRow =
                  constraints.maxWidth <
                  theme.layout.inlineControlWidth * 2 + theme.spacing.s;
              final fieldWidth = fieldsNeedOwnRow
                  ? constraints.maxWidth
                  : theme.layout.inlineControlWidth;
              return Wrap(
                spacing: theme.spacing.s,
                runSpacing: theme.spacing.s,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: YhTextField(
                      key: const Key('campus-card-start-date'),
                      label: '开始日期',
                      showLabel: false,
                      controller: _startDateController,
                      hint: '开始日期',
                      enabled: !remoteLocked,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: YhTextField(
                      key: const Key('campus-card-end-date'),
                      label: '结束日期',
                      showLabel: false,
                      controller: _endDateController,
                      hint: '结束日期',
                      enabled: !remoteLocked,
                    ),
                  ),
                  YhButton(
                    key: const Key('campus-card-apply-filter'),
                    label: '查询记录',
                    onTap: remoteLocked ? null : _queryRemoteRecords,
                  ),
                  YhButton(
                    key: const Key('campus-card-sync-all'),
                    label: '只读同步全部记录',
                    leadingIcon: YhIcons.sync,
                    variant: YhButtonVariant.text,
                    onTap: remoteLocked ? null : _syncAllRecords,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: theme.spacing.m),
          YhTabs<_CampusCardTransactionDirectionFilter>(
            tabs: const [
              YhTab(
                value: _CampusCardTransactionDirectionFilter.all,
                label: '全部',
              ),
              YhTab(
                value: _CampusCardTransactionDirectionFilter.expense,
                label: '支出',
              ),
              YhTab(
                value: _CampusCardTransactionDirectionFilter.income,
                label: '收入',
              ),
            ],
            value: _directionFilter,
            onChanged: _onDirectionChanged,
          ),
          if (_validationMessage != null ||
              displayState == CampusCardDetailDisplayState.validationError) ...[
            SizedBox(
              height:
                  theme.spacing.m +
                  (displayState == CampusCardDetailDisplayState.validationError
                      ? theme.spacing.xs
                      : 0),
            ),
            YhBanner(
              key: const Key('campus-card-validation-banner'),
              text: _validationMessage ?? '开始日期不能晚于结束日期；已保留上一次有效筛选结果。',
              kind: YhBannerKind.danger,
            ),
          ],
        ],
      ),
    );
  }
}

/// 呈现无可恢复校园卡记录时的紧凑终端错误恢复条。
class _CampusCardTerminalErrorRecoveryPanel extends StatelessWidget {
  /// 创建包含原操作重试与返回首页出口的终端错误恢复条。
  ///
  /// :param message: 面向用户的失败原因与恢复边界。
  /// :param retryLabel: 与原远端操作对应的重试动词。
  /// :param onRetry: 可选的原操作重试回调；凭据失效时为空。
  /// :param onReturnHome: 返回首页处理账户连接的回调。
  const _CampusCardTerminalErrorRecoveryPanel({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.onReturnHome,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final title = Semantics(
      header: true,
      child: Text('暂时无法读取校园卡记录', style: theme.typography.h3),
    );
    final icon = ExcludeSemantics(
      child: Icon(
        YhIcons.warning,
        size: theme.spacing.l,
        color: theme.color.danger,
      ),
    );
    final actions = Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
      children: [
        YhButton(
          key: const Key('campus-card-retry-query'),
          label: retryLabel,
          onTap: onRetry,
        ),
        YhButton(
          label: '返回首页',
          variant: YhButtonVariant.secondary,
          onTap: onReturnHome,
        ),
      ],
    );
    final description = Text(
      message,
      style: theme.typography.small.copyWith(color: theme.color.muted),
    );

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
        child: YhCard(
          key: const Key('campus-card-terminal-error'),
          padding: EdgeInsets.all(theme.spacing.m),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        SizedBox(width: theme.spacing.s),
                        Expanded(child: title),
                      ],
                    ),
                    SizedBox(height: theme.spacing.xs),
                    description,
                    SizedBox(height: theme.spacing.m),
                    actions,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon,
                    SizedBox(width: theme.spacing.s),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          SizedBox(height: theme.spacing.xs),
                          description,
                        ],
                      ),
                    ),
                    SizedBox(width: theme.spacing.m),
                    actions,
                  ],
                ),
        ),
      ),
    );
  }
}
