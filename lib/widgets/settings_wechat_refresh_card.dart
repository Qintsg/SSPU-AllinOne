/*
 * 微信推文刷新设置卡片 — 管理手动抓取、自动刷新与批量开关
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_refresh_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import '../design/qingyuan/qingyuan_ui.dart';
import 'settings_widgets.dart';

/// 微信推文刷新设置卡片。
class SettingsWechatRefreshCard extends StatelessWidget {
  const SettingsWechatRefreshCard({
    super.key,
    required this.manualFetchCount,
    required this.autoRefreshEnabled,
    required this.refreshInterval,
    required this.autoFetchCount,
    required this.onManualFetchCountChanged,
    required this.onAutoRefreshChanged,
    required this.onRefreshIntervalChanged,
    required this.onAutoFetchCountChanged,
  });

  /// 手动刷新文章条数。
  final int manualFetchCount;

  /// 是否启用自动刷新。
  final bool autoRefreshEnabled;

  /// 自动刷新频率。
  final int refreshInterval;

  /// 自动刷新文章条数。
  final int autoFetchCount;

  /// 修改手动刷新文章条数。
  final Future<void> Function(int count) onManualFetchCountChanged;

  /// 修改自动刷新开关。
  final Future<void> Function(bool enabled) onAutoRefreshChanged;

  /// 修改自动刷新频率。
  final Future<void> Function(int minutes) onRefreshIntervalChanged;

  /// 修改自动刷新文章条数。
  final Future<void> Function(int count) onAutoFetchCountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(YhIcons.sync, color: theme.color.brandStrong),
              SizedBox(width: theme.spacing.s),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('刷新设置', style: theme.typography.h3),
                    Text(
                      '控制微信推文的抓取条数和自动刷新频率',
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.l),
          Wrap(
            spacing: theme.spacing.l,
            runSpacing: theme.spacing.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildCountNumberBox(
                context: context,
                label: '手动刷新条数',
                value: manualFetchCount,
                enabled: true,
                onChanged: onManualFetchCountChanged,
              ),
              _InlineWechatSetting(
                label: '自动刷新',
                enabled: true,
                child: YhSwitch(
                  value: autoRefreshEnabled,
                  semanticLabel: '微信推文自动刷新',
                  onChanged: onAutoRefreshChanged,
                ),
              ),
              _InlineWechatSetting(
                label: '刷新频率',
                enabled: autoRefreshEnabled,
                child: YhSelect<int>(
                  label: '刷新频率',
                  showLabel: false,
                  value: kIntervalOptions.containsKey(refreshInterval)
                      ? refreshInterval
                      : 120,
                  enabled: autoRefreshEnabled,
                  options: [
                    for (final entry in kIntervalOptions.entries.where(
                      (entry) => entry.key > 0,
                    ))
                      YhSelectOption<int>(value: entry.key, label: entry.value),
                  ],
                  onChanged: autoRefreshEnabled
                      ? (value) {
                          if (value != null) onRefreshIntervalChanged(value);
                        }
                      : null,
                ),
              ),
              buildCountNumberBox(
                context: context,
                label: '自动刷新条数',
                value: autoFetchCount,
                enabled: autoRefreshEnabled,
                onChanged: onAutoFetchCountChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineWechatSetting extends StatelessWidget {
  const _InlineWechatSetting({
    required this.label,
    required this.enabled,
    required this.child,
  });

  /// 标签。
  final String label;

  /// 是否可用。
  final bool enabled;

  /// 控件。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = enabled ? theme.color.muted : theme.color.border;

    return Wrap(
      spacing: theme.spacing.xs,
      runSpacing: theme.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: theme.typography.small.copyWith(color: foreground)),
        child,
      ],
    );
  }
}
