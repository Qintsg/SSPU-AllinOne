/*
 * 微信推文矩阵卡片组件 — SSPU 官方公众号展示与关注控制
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_matrix_card.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import 'package:flutter/material.dart';

import '../models/sspu_wechat_accounts.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../utils/wechat_followed_account_matcher.dart';

/// SSPU 微信矩阵卡片。
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

  /// 单个公众号关注回调。
  final ValueChanged<SspuWechatAccount> onFollowAccount;

  /// 单个公众号开关回调。
  final Future<void> Function(String fakeid, bool enabled) onToggleMp;

  const SettingsWechatMatrixCard({
    super.key,
    required this.authenticated,
    required this.batchFollowing,
    required this.batchProgress,
    required this.mpNotificationEnabled,
    required this.followedMps,
    required this.followingAccountId,
    required this.onBatchFollow,
    required this.onFollowAccount,
    required this.onToggleMp,
  });

  @override
  Widget build(BuildContext context) {
    final allAccountsFollowed = sspuWechatAccounts.every(
      (account) => findFollowedWechatAccount(account, followedMps) != null,
    );

    return Card.filled(
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
                final itemWidth = constraints.maxWidth < 360
                    ? constraints.maxWidth
                    : 340.0;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: sspuWechatAccounts.map((account) {
                    final followed = findFollowedWechatAccount(
                      account,
                      followedMps,
                    );
                    final fakeid = followed?['fakeid'] ?? '';
                    final enabled = fakeid.isEmpty
                        ? false
                        : (mpNotificationEnabled[fakeid] ?? true);
                    final following = followingAccountId == account.wxAccount;

                    return SizedBox(
                      width: itemWidth,
                      child: _WechatAccountTile(
                        account: account,
                        authenticated: authenticated,
                        followed: followed != null,
                        enabled: enabled,
                        following: following,
                        onFollow: () => onFollowAccount(account),
                        onToggle: (value) => onToggleMp(fakeid, value),
                      ),
                    );
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text('SSPU 微信矩阵', style: textTheme.titleMedium),
            ),
            Text(
              '来源：校园+微信矩阵 · 共 ${sspuWechatAccounts.length} 个',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '以下为上海第二工业大学官方认可的微信公众号',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '已关注的公众号可在此直接控制是否获取推文；未关注项仅展示状态。',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBatchFollowAction(
    BuildContext context, {
    required bool alignEnd,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: !authenticated || batchFollowing ? null : onBatchFollow,
          icon: batchFollowing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.group_add_outlined),
          label: const Text('一键全部关注'),
        ),
        if (batchFollowing && batchProgress.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              batchProgress,
              style: textTheme.bodySmall,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _WechatAccountTile extends StatelessWidget {
  final SspuWechatAccount account;
  final bool authenticated;
  final bool followed;
  final bool enabled;
  final bool following;
  final VoidCallback onFollow;
  final ValueChanged<bool> onToggle;

  const _WechatAccountTile({
    required this.account,
    required this.authenticated,
    required this.followed,
    required this.enabled,
    required this.following,
    required this.onFollow,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppShapes.md,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppShapes.sm,
              child: Image.network(
                account.iconUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.chat_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    account.wxAccount,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (!authenticated)
              Text(
                '未认证',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else if (!followed)
              OutlinedButton(
                onPressed: following ? null : onFollow,
                child: following
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('关注'),
              )
            else
              Tooltip(
                message: '控制是否获取该公众号推文',
                child: Switch(value: enabled, onChanged: onToggle),
              ),
          ],
        ),
      ),
    );
  }
}
