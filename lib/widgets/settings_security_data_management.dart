/*
 * 设置页安全分区数据管理 — 整合本地缓存与全量数据清理入口
 * @Project : SSPU-AllinOne
 * @File : settings_security_data_management.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

part of 'settings_security_section.dart';

enum SettingsDataPrivacyState { content, loading, error }

/// 本地数据与隐私操作，可独立呈现清理中的忙碌态和失败恢复态。
class SettingsDataPrivacySection extends StatelessWidget {
  const SettingsDataPrivacySection({
    super.key,
    required this.onClearMessageCache,
    required this.onClearAllData,
    this.state = SettingsDataPrivacyState.content,
    this.errorMessage,
    this.clearedItems = const ['消息缓存'],
    this.remainingItems = const ['账户凭据', '个性化设置', '本地文件'],
  });

  final VoidCallback onClearMessageCache;
  final VoidCallback onClearAllData;
  final SettingsDataPrivacyState state;
  final String? errorMessage;
  final List<String> clearedItems;
  final List<String> remainingItems;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state == SettingsDataPrivacyState.loading) ...[
          const YhProgress(showPercent: false, semanticLabel: '正在清理本地数据'),
          SizedBox(height: theme.spacing.m),
          const YhBanner(text: '正在清理本地数据，请保持应用打开。'),
          SizedBox(height: theme.spacing.m),
        ],
        if (state == SettingsDataPrivacyState.error) ...[
          YhBanner(
            text: errorMessage ?? '部分本地数据未能清理，请重试。',
            kind: YhBannerKind.danger,
          ),
          SizedBox(height: theme.spacing.m),
          _CleanupResult(
            label: '已清除项目',
            items: clearedItems,
            kind: YhStatusKind.success,
          ),
          SizedBox(height: theme.spacing.s),
          _CleanupResult(
            label: '未清除项目',
            items: remainingItems,
            kind: YhStatusKind.danger,
          ),
          SizedBox(height: theme.spacing.m),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = shouldStackSettingsControls(constraints);
            final summary = _buildSummary(context);
            final actions = _buildActions(context);

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summary,
                  SizedBox(height: theme.spacing.m),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: summary),
                SizedBox(width: theme.spacing.l),
                actions,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(YhIcons.database, color: theme.color.danger),
        SizedBox(width: theme.spacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('数据管理', style: theme.typography.h3),
              SizedBox(height: theme.spacing.xs),
              Text(
                '清理信息中心缓存，或清除本地数据并退出应用。',
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: context.yhTheme.spacing.s,
      runSpacing: context.yhTheme.spacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DangerActionButton(
          key: const Key('settings-clear-message-cache'),
          icon: YhIcons.clean,
          label: '清理信息中心缓存',
          onPressed: state == SettingsDataPrivacyState.loading
              ? null
              : onClearMessageCache,
        ),
        _DangerActionButton(
          key: const Key('settings-clear-all-data'),
          icon: YhIcons.delete,
          label: '清除本地数据',
          onPressed: state == SettingsDataPrivacyState.loading
              ? null
              : onClearAllData,
        ),
      ],
    );
  }
}

class _CleanupResult extends StatelessWidget {
  const _CleanupResult({
    required this.label,
    required this.items,
    required this.kind,
  });

  final String label;
  final List<String> items;
  final YhStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      label: '$label：${items.join('、')}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YhStatusPill(label: label, kind: kind),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Text(
              items.isEmpty ? '无' : items.join('、'),
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return YhButton(
      label: label,
      onTap: onPressed,
      leadingIcon: icon,
      variant: YhButtonVariant.danger,
    );
  }
}
