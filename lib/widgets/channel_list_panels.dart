/*
 * 渠道列表面板组件 — 顶部刷新设置卡片与单渠道卡片
 * @Project : SSPU-AllinOne
 * @File : channel_list_panels.dart
 * @Author : Qintsg
 * @Date : 2026-04-23
 */

import '../design/fluent_ui.dart';

import '../models/channel_config.dart';
import '../models/message_item.dart';
import '../theme/app_spacing.dart';
import 'responsive_layout.dart';
import 'settings_widgets.dart';

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
    final colors = context.fluentColors;
    final type = context.fluentType;
    final foreground = enabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;

    return FluentCard(
      padding: EdgeInsets.zero,
      bordered: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final shouldStack = shouldStackSettingsControls(constraints);
                final titleBlock = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FluentSurfaceIcon(
                      icon: FluentIcons.sync,
                      color: enabled
                          ? colors.brandForeground1
                          : colors.neutralForegroundDisabled,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text('刷新设置', style: type.body1Strong),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hasImplementedChannel
                                ? '统一配置本分区已接入渠道的抓取条数和自动刷新频率。'
                                : '当前分区没有已接入的数据源，刷新设置暂不可用。',
                            style: type.caption1.copyWith(color: foreground),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final statusChip = FluentStatusChip(
                  label: groupAutoRefreshEnabled ? '自动刷新开启' : '自动刷新关闭',
                  tone: groupAutoRefreshEnabled
                      ? FluentStatusChipTone.success
                      : FluentStatusChipTone.neutral,
                  icon: groupAutoRefreshEnabled
                      ? FluentIcons.sync
                      : FluentIcons.blocked,
                );

                if (shouldStack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.xxl + AppSpacing.sm,
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
                    const SizedBox(width: AppSpacing.sm),
                    statusChip,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _RefreshSettingBlock(
                  icon: FluentIcons.download,
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
                      ? FluentIcons.ringer
                      : FluentIcons.ringerOff,
                  title: '自动刷新',
                  description: '后台定时读取已启用渠道',
                  enabled: hasImplementedChannel,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FluentSwitch(
                        value: groupAutoRefreshEnabled,
                        onChanged: hasImplementedChannel
                            ? onGroupAutoRefreshToggled
                            : null,
                      ),
                      Text(
                        groupAutoRefreshEnabled ? '已开启' : '已关闭',
                        style: type.caption1.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
                _RefreshSettingBlock(
                  icon: FluentIcons.clock,
                  title: '刷新间隔',
                  description: '每轮自动刷新之间的等待时间',
                  enabled: enabled && groupAutoRefreshEnabled,
                  child: FluentSelect<int>(
                    value: kIntervalOptions.containsKey(groupInterval)
                        ? groupInterval
                        : 60,
                    items: kIntervalOptions.entries
                        .where((entry) => entry.key > 0)
                        .map(
                          (entry) => FluentSelectItem<int>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: enabled && groupAutoRefreshEnabled
                        ? (value) {
                            if (value != null) {
                              onGroupIntervalChanged(value);
                            }
                          }
                        : null,
                  ),
                ),
                _RefreshSettingBlock(
                  icon: FluentIcons.news,
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
      ),
    );
  }
}

/// 刷新设置中的单个参数块。
class _RefreshSettingBlock extends StatelessWidget {
  const _RefreshSettingBlock({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.child,
  });

  /// 图标。
  final IconData icon;

  /// 标题。
  final String title;

  /// 描述。
  final String description;

  /// 是否启用。
  final bool enabled;

  /// 控件内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final foreground = enabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled
                ? colors.brandForeground1
                : colors.neutralForegroundDisabled,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: type.caption1Strong.copyWith(color: foreground),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: type.caption1.copyWith(color: foreground),
                ),
                const SizedBox(height: AppSpacing.sm),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 自动刷新条数输入框。
class _RefreshCountBox extends StatelessWidget {
  const _RefreshCountBox({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  /// 当前条数。
  final int value;

  /// 是否可编辑。
  final bool enabled;

  /// 条数变化回调。
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: FluentNumberBox(
        value: value,
        enabled: enabled,
        suffixText: '条',
        min: 1,
        max: 200,
        onChanged: onChanged,
        onSubmitted: onChanged,
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
    final colors = context.fluentColors;
    final type = context.fluentType;
    final subtitle = channel.implemented
        ? channel.description
        : '${channel.description}（暂未接入）';
    final foreground = enabled
        ? colors.neutralForeground1
        : colors.neutralForeground2;

    return Padding(
      padding: EdgeInsets.zero,
      child: FluentCard(
        padding: EdgeInsets.zero,
        bordered: true,
        backgroundColor: enabled
            ? FluentTheme.of(context).cardColor
            : colors.neutralBackground2,
        borderColor: enabled ? colors.neutralStroke1 : colors.neutralStroke2,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final shouldStack = shouldStackSettingsControls(constraints);
                  final description = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FluentSurfaceIcon(
                        icon: channel.icon,
                        color: enabled
                            ? colors.brandForeground1
                            : colors.neutralForegroundDisabled,
                        size: 40,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  channel.name,
                                  style: type.body1Strong.copyWith(
                                    color: foreground,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                FluentStatusChip(
                                  label: channel.implemented ? '已接入' : '未接入',
                                  tone: channel.implemented
                                      ? FluentStatusChipTone.brand
                                      : FluentStatusChipTone.warning,
                                  icon: channel.implemented
                                      ? FluentIcons.plugConnected
                                      : FluentIcons.plugDisconnected,
                                ),
                                FluentStatusChip(
                                  label: enabled ? '显示中' : '已隐藏',
                                  tone: enabled
                                      ? FluentStatusChipTone.success
                                      : FluentStatusChipTone.neutral,
                                  icon: enabled
                                      ? FluentIcons.checkMark
                                      : FluentIcons.blocked,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle,
                              style: type.caption1.copyWith(
                                color: enabled
                                    ? colors.neutralForeground2
                                    : colors.neutralForegroundDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (shouldStack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        description,
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.xxl + AppSpacing.sm,
                          ),
                          child: FluentSwitch(
                            value: enabled,
                            onChanged: onToggled,
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: description),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: AppSpacing.xs,
                        ),
                        child: FluentSwitch(
                          value: enabled,
                          onChanged: onToggled,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (channel.implemented &&
                  channelSubcategories.containsKey(channel.id)) ...[
                const SizedBox(height: AppSpacing.sm),
                _ChannelSubcategoryButtons(
                  channelId: channel.id,
                  channelEnabled: enabled,
                  categoryEnabledMap: categoryEnabledMap,
                  onToggleCategory: onToggleCategory,
                ),
              ],
              if (!channel.implemented) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.xxl,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        FluentIcons.info,
                        size: 14,
                        color: colors.neutralForeground2,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '此渠道数据源尚未接入，开关仅作为预配置使用。',
                          style: type.caption1.copyWith(
                            color: colors.neutralForeground2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelSubcategoryButtons extends StatelessWidget {
  final String channelId;
  final bool channelEnabled;
  final Map<String, bool> categoryEnabledMap;
  final ValueChanged<MessageCategory> onToggleCategory;

  const _ChannelSubcategoryButtons({
    required this.channelId,
    required this.channelEnabled,
    required this.categoryEnabledMap,
    required this.onToggleCategory,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final subcategories = channelSubcategories[channelId]!;
    final labelColor = channelEnabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xxl + AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('内容分类', style: type.caption1.copyWith(color: labelColor)),
              FluentStatusChip(
                label: '${subcategories.length} 项',
                tone: FluentStatusChipTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: subcategories.map((subcategory) {
              final isEnabled =
                  categoryEnabledMap[subcategory.category.name] ?? true;
              return _ChannelSubcategoryButton(
                name: subcategory.name,
                enabled: isEnabled,
                interactive: channelEnabled,
                onPressed: () => onToggleCategory(subcategory.category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChannelSubcategoryButton extends StatelessWidget {
  final String name;
  final bool enabled;
  final bool interactive;
  final VoidCallback onPressed;

  const _ChannelSubcategoryButton({
    required this.name,
    required this.enabled,
    required this.interactive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final stroke = context.fluentStroke;
    final type = context.fluentType;
    final foreground = !interactive
        ? colors.neutralForegroundDisabled
        : enabled
        ? colors.brandForeground1
        : colors.neutralForeground2;
    final background = enabled
        ? colors.brandStroke2.withValues(alpha: 0.22)
        : colors.neutralBackground1;
    final border = enabled ? colors.brandStroke2 : colors.neutralStroke1;

    return Semantics(
      button: interactive,
      toggled: enabled,
      enabled: interactive,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: interactive ? onPressed : null,
          child: AnimatedContainer(
            duration: context.fluentMotion.durationFaster,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radii.circular),
              border: Border.all(color: border, width: stroke.thin),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enabled ? FluentIcons.checkMark : FluentIcons.blocked,
                  size: 12,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(name, style: type.caption1.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
