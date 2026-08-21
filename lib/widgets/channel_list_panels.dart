/*
 * 渠道列表面板组件 — 顶部刷新设置卡片与单渠道卡片
 * @Project : SSPU-AllinOne
 * @File : channel_list_panels.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/qingyuan/qingyuan_ui.dart';

import '../models/channel_config.dart';
import '../models/message_item.dart';
import 'channel_icon_resolver.dart';
import 'responsive_layout.dart';
import 'settings_widgets.dart';

part 'channel_list_panels_support.dart';

/// 分组级刷新设置面板。
class ChannelGroupRefreshPanel extends StatelessWidget {
  final bool enabled;
  final bool hasImplementedChannel;
  final bool groupAutoRefreshEnabled;
  final int groupInterval;
  final int groupManualCount;
  final int groupAutoCount;
  final ValueChanged<int> onGroupManualCountChanged;
  final ValueChanged<bool> onGroupAutoRefreshToggled;
  final ValueChanged<int> onGroupIntervalChanged;
  final ValueChanged<int> onGroupAutoCountChanged;

  const ChannelGroupRefreshPanel({
    super.key,
    required this.enabled,
    required this.hasImplementedChannel,
    required this.groupAutoRefreshEnabled,
    required this.groupInterval,
    required this.groupManualCount,
    required this.groupAutoCount,
    required this.onGroupManualCountChanged,
    required this.onGroupAutoRefreshToggled,
    required this.onGroupIntervalChanged,
    required this.onGroupAutoCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = enabled ? theme.color.muted : theme.color.border;

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack = shouldStackSettingsControls(constraints);
              final titleBlock = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChannelSurfaceIcon(icon: YhIcons.sync, enabled: enabled),
                  SizedBox(width: theme.spacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('刷新设置', style: theme.typography.h3),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          hasImplementedChannel
                              ? '统一配置本分区已接入渠道的抓取条数和自动刷新频率。'
                              : '当前分区没有已接入的数据源，刷新设置暂不可用。',
                          style: theme.typography.small.copyWith(
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final statusChip = YhChip(
                label: groupAutoRefreshEnabled ? '自动刷新开启' : '自动刷新关闭',
                selected: groupAutoRefreshEnabled,
                disabled: !hasImplementedChannel,
              );

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    SizedBox(height: theme.spacing.s),
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: theme.spacing.xl2 + theme.spacing.s,
                      ),
                      child: statusChip,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  SizedBox(width: theme.spacing.s),
                  statusChip,
                ],
              );
            },
          ),
          SizedBox(height: theme.spacing.l),
          Wrap(
            spacing: theme.spacing.l,
            runSpacing: theme.spacing.l,
            children: [
              _RefreshSettingBlock(
                icon: YhIcons.download,
                title: '手动刷新',
                description: '点击信息中心刷新时，每个渠道最多抓取',
                enabled: hasImplementedChannel,
                child: _RefreshCountBox(
                  value: groupManualCount,
                  enabled: hasImplementedChannel,
                  onChanged: onGroupManualCountChanged,
                ),
              ),
              _RefreshSettingBlock(
                icon: groupAutoRefreshEnabled
                    ? YhIcons.notification
                    : YhIcons.notificationOff,
                title: '自动刷新',
                description: '后台定时读取已启用渠道',
                enabled: hasImplementedChannel,
                child: Wrap(
                  spacing: theme.spacing.s,
                  runSpacing: theme.spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    YhSwitch(
                      value: groupAutoRefreshEnabled,
                      semanticLabel: '分区自动刷新',
                      onChanged: hasImplementedChannel
                          ? onGroupAutoRefreshToggled
                          : null,
                    ),
                    Text(
                      groupAutoRefreshEnabled ? '已开启' : '已关闭',
                      style: theme.typography.small.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
              _RefreshSettingBlock(
                icon: YhIcons.clock,
                title: '刷新间隔',
                description: '每轮自动刷新之间的等待时间',
                enabled: enabled && groupAutoRefreshEnabled,
                child: SizedBox(
                  width: theme.spacing.xl2 * 3,
                  child: YhSelect<int>(
                    label: '刷新间隔',
                    showLabel: false,
                    value: kIntervalOptions.containsKey(groupInterval)
                        ? groupInterval
                        : 60,
                    options: [
                      for (final entry in kIntervalOptions.entries.where(
                        (entry) => entry.key > 0,
                      ))
                        YhSelectOption<int>(
                          value: entry.key,
                          label: entry.value,
                        ),
                    ],
                    enabled: enabled && groupAutoRefreshEnabled,
                    onChanged: enabled && groupAutoRefreshEnabled
                        ? (value) {
                            if (value != null) {
                              onGroupIntervalChanged(value);
                            }
                          }
                        : null,
                  ),
                ),
              ),
              _RefreshSettingBlock(
                icon: YhIcons.news,
                title: '自动抓取',
                description: '每次自动刷新时，每个渠道最多抓取',
                enabled: enabled && groupAutoRefreshEnabled,
                child: _RefreshCountBox(
                  value: groupAutoCount,
                  enabled: enabled && groupAutoRefreshEnabled,
                  onChanged: onGroupAutoCountChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单个渠道卡片。
class ChannelListItemCard extends StatelessWidget {
  final ChannelConfig channel;
  final bool enabled;
  final ValueChanged<bool> onToggled;
  final Map<String, bool> categoryEnabledMap;
  final ValueChanged<MessageCategory> onToggleCategory;

  const ChannelListItemCard({
    super.key,
    required this.channel,
    required this.enabled,
    required this.onToggled,
    required this.categoryEnabledMap,
    required this.onToggleCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final subtitle = channel.implemented
        ? channel.description
        : '${channel.description}（暂未接入）';
    final foreground = enabled ? theme.color.foreground : theme.color.muted;

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack = shouldStackSettingsControls(constraints);
              final description = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChannelSurfaceIcon(
                    icon: resolveChannelIcon(channel.icon),
                    enabled: enabled,
                  ),
                  SizedBox(width: theme.spacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: theme.spacing.s,
                          runSpacing: theme.spacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              channel.name,
                              style: theme.typography.body.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            YhChip(
                              label: channel.implemented ? '已接入' : '未接入',
                              selected: channel.implemented,
                            ),
                            YhChip(
                              label: enabled ? '显示中' : '已隐藏',
                              selected: enabled,
                            ),
                          ],
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          subtitle,
                          style: theme.typography.small.copyWith(
                            color: enabled
                                ? theme.color.muted
                                : theme.color.border,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final toggle = YhSwitch(
                value: enabled,
                semanticLabel: '${channel.name}显示状态',
                onChanged: onToggled,
              );

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    description,
                    SizedBox(height: theme.spacing.s),
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: theme.spacing.xl2 + theme.spacing.s,
                      ),
                      child: toggle,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: description),
                  SizedBox(width: theme.spacing.s),
                  toggle,
                ],
              );
            },
          ),
          if (channel.implemented &&
              channelSubcategories.containsKey(channel.id)) ...[
            SizedBox(height: theme.spacing.s),
            _ChannelSubcategoryButtons(
              channelId: channel.id,
              channelEnabled: enabled,
              categoryEnabledMap: categoryEnabledMap,
              onToggleCategory: onToggleCategory,
            ),
          ],
          if (!channel.implemented) ...[
            SizedBox(height: theme.spacing.s),
            Padding(
              padding: EdgeInsetsDirectional.only(start: theme.spacing.xl2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    YhIcons.info,
                    size: theme.spacing.m,
                    color: theme.color.muted,
                  ),
                  SizedBox(width: theme.spacing.xs),
                  Expanded(
                    child: Text(
                      '此渠道数据源尚未接入，开关仅作为预配置使用。',
                      style: theme.typography.small.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
