/*
 * 微信推文矩阵卡片组件 — SSPU 官方公众号展示与关注控制
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_matrix_card.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/fluent_ui.dart';

import '../models/sspu_wechat_accounts.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
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
    required this.onToggleAccount,
  });

  @override
  Widget build(BuildContext context) {
    final allAccountsFollowed = sspuWechatAccounts.every(
      (account) => findFollowedWechatAccount(account, followedMps) != null,
    );

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final shouldStack =
                    AppBreakpoints.fromWidth(constraints.maxWidth) ==
                    WindowSizeClass.compact;
                final intro = _buildIntro(context);
                final batchAction = !allAccountsFollowed
                    ? _buildBatchFollowAction(context, alignEnd: !shouldStack)
                    : null;

                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      intro,
                      if (batchAction != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        batchAction,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: intro),
                    if (batchAction != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      batchAction,
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth < 420
                    ? constraints.maxWidth
                    : null;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
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
      ),
    );
  }

  /// 构建卡片简介。
  Widget _buildIntro(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(header: true, child: Text('微信矩阵', style: type.subtitle1)),
            Text(
              '来源：校园+微信矩阵 · 共 ${sspuWechatAccounts.length} 个',
              style: type.caption1.copyWith(color: colors.neutralForeground2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchFollowAction(
    BuildContext context, {
    required bool alignEnd,
  }) {
    final type = context.fluentType;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        FluentButton.primaryIcon(
          onPressed: !authenticated || batchFollowing ? null : onBatchFollow,
          icon: batchFollowing
              ? const SizedBox.square(
                  dimension: 20,
                  child: FluentProgressRing(strokeWidth: 2),
                )
              : const Icon(FluentIcons.peopleAdd),
          label: const Text('一键全部关注'),
        ),
        if (batchFollowing && batchProgress.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              batchProgress,
              style: type.caption1,
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
    final colors = context.fluentColors;
    final motion = context.fluentMotion;
    final radii = context.fluentRadii;
    final stroke = context.fluentStroke;
    final type = context.fluentType;
    final active = authenticated && enabled;
    final disabled = !authenticated || following;
    final foreground = !authenticated
        ? colors.neutralForegroundDisabled
        : active
        ? colors.brandForeground1
        : colors.neutralForeground2;
    final background = active
        ? colors.brandStroke2.withValues(alpha: 0.35)
        : colors.neutralBackground2;
    final hoverBackground = active
        ? colors.brandStroke2.withValues(alpha: 0.48)
        : colors.neutralBackground1Hover;
    final pressedBackground = active
        ? colors.brandStroke2.withValues(alpha: 0.58)
        : colors.neutralBackground1Pressed;
    final borderColor = !authenticated
        ? colors.neutralStroke2
        : active
        ? colors.brandStroke1
        : colors.neutralStroke1;
    final tooltipMessage = !authenticated
        ? '需先完成公众号平台认证'
        : followed
        ? '切换是否获取该公众号推文'
        : '切换后会自动关注并获取该公众号推文';

    return Tooltip(
      message: tooltipMessage,
      child: Semantics(
        button: true,
        selected: active,
        enabled: !disabled,
        label: account.name,
        child: HoverButton(
          cursor: disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onPressed: disabled ? null : () => onToggle(!active),
          builder: (context, states) {
            final resolvedBackground = states.isPressed
                ? pressedBackground
                : states.isHovered || states.isFocused
                ? hoverBackground
                : background;
            return AnimatedContainer(
              key: Key('wechat-matrix-toggle-${account.wxAccount}'),
              duration: motion.durationFast,
              constraints: const BoxConstraints(minHeight: 52, maxWidth: 260),
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.sm,
                top: AppSpacing.xs,
                end: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: resolvedBackground,
                borderRadius: BorderRadius.circular(radii.circular),
                border: Border.all(color: borderColor, width: stroke.thin),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WechatAccountAvatar(
                    account: account,
                    foreground: foreground,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: type.body1Strong.copyWith(color: foreground),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          displayId,
                          style: type.caption1.copyWith(color: foreground),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (following)
                    const SizedBox.square(
                      dimension: 18,
                      child: FluentProgressRing(strokeWidth: 2),
                    )
                  else
                    Icon(
                      active ? FluentIcons.checkMark : FluentIcons.peopleAdd,
                      size: 16,
                      color: foreground,
                    ),
                ],
              ),
            );
          },
        ),
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
    final radii = context.fluentRadii;
    final avatar = account.iconUrl.trim().isEmpty
        ? Icon(FluentIcons.chat, size: 24, color: foreground)
        : Image.network(
            account.iconUrl,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(FluentIcons.chat, size: 24, color: foreground),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radii.circular),
      child: SizedBox.square(dimension: 32, child: avatar),
    );
  }
}
