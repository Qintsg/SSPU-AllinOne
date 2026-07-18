/*
 * 微信推文矩阵卡片组件 — SSPU 官方公众号展示与关注控制
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_matrix_card.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/qingyuan/qingyuan_ui.dart';

import '../models/sspu_wechat_accounts.dart';
import '../utils/wechat_followed_account_matcher.dart';

/// 微信矩阵卡片。
class SettingsWechatMatrixCard extends StatelessWidget {
  /// 已认证状态。
  final bool authenticated;

  /// 当前是否正在批量关注。
  final bool batchFollowing;

  /// 批量关注进度文本。
  final String batchProgress;

  /// 单个公众号的通知开关。
  final Map<String, bool> mpNotificationEnabled;

  /// 已关注列表。
  final List<Map<String, String>> followedMps;

  /// 当前正在关注的微信号。
  final String followingAccountId;

  /// 一键全部关注回调。
  final VoidCallback onBatchFollow;

  /// 启用微信矩阵公众号获取回调。
  final Future<void> Function() onEnableAll;

  /// 关闭微信矩阵公众号获取回调。
  final Future<void> Function() onDisableAll;

  /// 单个推荐公众号开关回调。
  final Future<void> Function(SspuWechatAccount account, bool enabled)
  onToggleAccount;

  const SettingsWechatMatrixCard({
    super.key,
    required this.authenticated,
    required this.batchFollowing,
    required this.batchProgress,
    required this.mpNotificationEnabled,
    required this.followedMps,
    required this.followingAccountId,
    required this.onBatchFollow,
    required this.onEnableAll,
    required this.onDisableAll,
    required this.onToggleAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final allAccountsFollowed = sspuWechatAccounts.every(
      (account) => findFollowedWechatAccount(account, followedMps) != null,
    );

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack =
                  constraints.maxWidth < theme.breakpoint.compact;
              final intro = _buildIntro(context);
              final actions = _buildMatrixActions(
                context,
                showBatchFollow: !allAccountsFollowed,
                alignEnd: !shouldStack,
              );

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    intro,
                    SizedBox(height: theme.spacing.s),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: intro),
                  SizedBox(width: theme.spacing.m),
                  actions,
                ],
              );
            },
          ),
          SizedBox(height: theme.spacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 420
                  ? constraints.maxWidth
                  : null;
              return Wrap(
                spacing: theme.spacing.s,
                runSpacing: theme.spacing.s,
                children: sspuWechatAccounts.map((account) {
                  final followed = findFollowedWechatAccount(
                    account,
                    followedMps,
                  );
                  final fakeid = followed?['fakeid'] ?? '';
                  final enabled =
                      fakeid.isNotEmpty &&
                      (mpNotificationEnabled[fakeid] ?? true);
                  final following = followingAccountId == account.wxAccount;
                  final displayId = _resolveWechatAccountDisplayId(
                    account,
                    followed,
                  );

                  final toggleButton = _WechatAccountToggleButton(
                    account: account,
                    displayId: displayId,
                    authenticated: authenticated,
                    followed: followed != null,
                    enabled: enabled,
                    following: following,
                    onToggle: (value) => onToggleAccount(account, value),
                  );
                  if (itemWidth == null) return toggleButton;
                  return SizedBox(width: itemWidth, child: toggleButton);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建卡片简介。
  Widget _buildIntro(BuildContext context) {
    final theme = context.yhTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text('微信矩阵', style: theme.typography.h3),
            ),
            Text(
              '来源：校园+微信矩阵 · 共 ${sspuWechatAccounts.length} 个',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatrixActions(
    BuildContext context, {
    required bool showBatchFollow,
    required bool alignEnd,
  }) {
    final theme = context.yhTheme;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showBatchFollow)
              YhButton(
                label: batchFollowing ? '关注中' : '一键全部关注',
                onTap: !authenticated || batchFollowing ? null : onBatchFollow,
                disabled: !authenticated || batchFollowing,
                leadingIcon: batchFollowing ? null : YhIcons.add,
              ),
            YhButton(
              label: '全部开启',
              leadingIcon: YhIcons.check,
              onTap: authenticated ? onEnableAll : null,
              disabled: !authenticated,
            ),
            YhButton(
              label: '全部关闭',
              leadingIcon: YhIcons.close,
              onTap: authenticated ? onDisableAll : null,
              disabled: !authenticated,
              variant: YhButtonVariant.secondary,
            ),
          ],
        ),
        if (batchFollowing && batchProgress.isNotEmpty) ...[
          SizedBox(height: theme.spacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              batchProgress,
              style: theme.typography.small,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _WechatAccountToggleButton extends StatelessWidget {
  final SspuWechatAccount account;
  final String displayId;
  final bool authenticated;
  final bool followed;
  final bool enabled;
  final bool following;
  final ValueChanged<bool> onToggle;

  const _WechatAccountToggleButton({
    required this.account,
    required this.displayId,
    required this.authenticated,
    required this.followed,
    required this.enabled,
    required this.following,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final active = authenticated && enabled;
    final disabled = !authenticated || following;
    final foreground = !authenticated
        ? theme.color.border
        : active
        ? theme.color.brandInk
        : theme.color.muted;
    final background = active ? theme.color.brandTint : theme.color.sunken;
    final borderColor = !authenticated
        ? theme.color.border
        : active
        ? theme.color.brandStrong
        : theme.color.border;
    final tooltipMessage = !authenticated
        ? '需先完成公众号平台认证'
        : followed
        ? '切换是否获取该公众号推文'
        : '切换后会自动关注并获取该公众号推文';

    return YhTooltip(
      message: tooltipMessage,
      child: YhPressable(
        semanticLabel: account.name,
        selected: active,
        onPressed: disabled ? null : () => onToggle(!active),
        builder: (context, state, child) {
          final overlayAlpha = state.pressed
              ? 0.18
              : state.hovered
              ? 0.10
              : 0.0;
          return AnimatedContainer(
            key: Key('wechat-matrix-toggle-${account.wxAccount}'),
            duration: theme.motion.fast,
            curve: theme.motion.curve,
            constraints: BoxConstraints(
              minHeight: theme.control.minimumTarget,
              maxWidth: 320,
            ),
            padding: EdgeInsetsDirectional.only(
              start: theme.spacing.s,
              top: theme.spacing.xs,
              end: theme.spacing.m,
              bottom: theme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                theme.color.foreground.withValues(alpha: overlayAlpha),
                background,
              ),
              borderRadius: BorderRadius.circular(theme.radius.full),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WechatAccountAvatar(account: account, foreground: foreground),
                SizedBox(width: theme.spacing.s),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: theme.typography.body.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      Text(
                        displayId,
                        style: theme.typography.caption.copyWith(
                          color: foreground,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: theme.spacing.s),
                if (following)
                  SizedBox(
                    width: theme.spacing.xl,
                    child: const YhProgress(showPercent: false),
                  )
                else
                  Icon(
                    active ? YhIcons.check : YhIcons.add,
                    size: theme.spacing.m,
                    color: foreground,
                  ),
              ],
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

String _resolveWechatAccountDisplayId(
  SspuWechatAccount account,
  Map<String, String>? followed,
) {
  final alias = followed?['alias']?.trim();
  if (alias != null && alias.isNotEmpty) return alias;

  final recommended = followed?['recommended_wx_account']?.trim();
  if (recommended != null && recommended.isNotEmpty) return recommended;

  return account.wxAccount;
}

class _WechatAccountAvatar extends StatelessWidget {
  const _WechatAccountAvatar({required this.account, required this.foreground});

  /// 公众号账号。
  final SspuWechatAccount account;

  /// 前景色。
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final avatar = account.iconUrl.trim().isEmpty
        ? Icon(YhIcons.chat, size: theme.spacing.l, color: foreground)
        : Image.network(
            account.iconUrl,
            width: theme.spacing.xl,
            height: theme.spacing.xl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(YhIcons.chat, size: theme.spacing.l, color: foreground),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius.full),
      child: SizedBox.square(dimension: theme.spacing.xl, child: avatar),
    );
  }
}
