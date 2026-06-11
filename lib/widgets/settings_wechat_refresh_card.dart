/*
 * 微信推文刷新设置卡片 — 管理手动抓取、自动刷新与批量开关
 * @Project : SSPU-AllinOne
 * @File : settings_wechat_refresh_card.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import '../design/fluent_ui.dart';
import '../theme/app_breakpoints.dart';
import '../theme/fluent_tokens.dart';
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
    required this.onEnableAll,
    required this.onDisableAll,
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

  /// 启用微信推文相关开关。
  final Future<void> Function() onEnableAll;

  /// 关闭微信推文相关开关。
  final Future<void> Function() onDisableAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;

    return FluentCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < AppBreakpoints.mediumMax;
                final heading = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FluentSurfaceIcon(icon: FluentIcons.sync),
                    const SizedBox(width: FluentSpacing.s),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('刷新设置', style: type.subtitle2),
                          Text(
                            '控制微信推文的抓取条数、频率和矩阵开关',
                            style: type.caption1.copyWith(
                              color: colors.neutralForeground2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final actions = Wrap(
                  spacing: FluentSpacing.s,
                  runSpacing: FluentSpacing.s,
                  children: [
                    FluentButton.primaryIcon(
                      icon: const Icon(FluentIcons.checkMark),
                      label: const Text('全部开启'),
                      onPressed: onEnableAll,
                    ),
                    FluentButton.outlineIcon(
                      icon: const Icon(FluentIcons.blocked),
                      label: const Text('全部关闭'),
                      onPressed: onDisableAll,
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: FluentSpacing.s),
                      actions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: FluentSpacing.l),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: FluentSpacing.l),
            Wrap(
              spacing: FluentSpacing.l,
              runSpacing: FluentSpacing.m,
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
                  child: FluentSwitch(
                    value: autoRefreshEnabled,
                    onChanged: onAutoRefreshChanged,
                  ),
                ),
                _InlineWechatSetting(
                  label: '刷新频率',
                  enabled: autoRefreshEnabled,
                  child: FluentSelect<int>(
                    value: kIntervalOptions.containsKey(refreshInterval)
                        ? refreshInterval
                        : 120,
                    items: kIntervalOptions.entries
                        .where((entry) => entry.key > 0)
                        .map(
                          (entry) => FluentSelectItem<int>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
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
    final colors = context.fluentColors;
    final type = context.fluentType;
    final foreground = enabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;

    return Wrap(
      spacing: FluentSpacing.xs,
      runSpacing: FluentSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: type.caption1.copyWith(color: foreground)),
        child,
      ],
    );
  }
}
