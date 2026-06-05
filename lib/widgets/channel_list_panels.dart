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
import '../theme/app_shapes.dart';
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.neutralBackground2,
        borderRadius: AppShapes.md,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('刷新设置', style: type.body1Strong),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '这些设置会应用到本分区内每个已接入的内容渠道。',
              style: type.caption1.copyWith(color: foreground),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                buildCountNumberBox(
                  context: context,
                  label: '手动刷新文章个数',
                  value: groupManualCount,
                  enabled: hasImplementedChannel,
                  onChanged: onGroupManualCountChanged,
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '自动刷新：',
                      style: type.caption1.copyWith(color: foreground),
                    ),
                    FluentSwitch(
                      value: groupAutoRefreshEnabled,
                      onChanged: hasImplementedChannel
                          ? onGroupAutoRefreshToggled
                          : null,
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '自动刷新间隔：',
                      style: type.caption1.copyWith(color: foreground),
                    ),
                    FluentSelect<int>(
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
                  ],
                ),
                buildCountNumberBox(
                  context: context,
                  label: '自动刷新文章个数',
                  value: groupAutoCount,
                  enabled: enabled && groupAutoRefreshEnabled,
                  onChanged: onGroupAutoCountChanged,
                ),
              ],
            ),
          ],
        ),
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

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.neutralBackground2,
          borderRadius: AppShapes.md,
        ),
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
                      Icon(channel.icon, color: colors.brandForeground1),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.name,
                              style: type.body1Strong,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                            start: AppSpacing.xxl,
                          ),
                          child: FluentSwitch(value: enabled, onChanged: onToggled),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: description),
                      const SizedBox(width: AppSpacing.sm),
                      FluentSwitch(value: enabled, onChanged: onToggled),
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
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.xxl),
                  child: Text(
                    '此渠道数据源尚未接入，开关仅作为预配置使用。',
                    style: type.caption1.copyWith(
                      color: colors.neutralForeground2,
                    ),
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
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '内容分类',
            style: type.caption1.copyWith(color: labelColor),
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
        ? colors.brandBackgroundSelected.withValues(alpha: 0.12)
        : colors.neutralBackground2;
    final border = enabled ? colors.brandStroke2 : colors.neutralStroke2;

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radii.circular),
              border: Border.all(color: border, width: stroke.thin),
            ),
            child: Text(
              name,
              style: type.caption1.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
