/*
 * 渠道列表面板的内部支撑部件 — 图标底板、刷新参数块、条数输入与分类按钮
 * @Project : SSPU-AllinOne
 * @File : channel_list_panels_support.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'channel_list_panels.dart';

/// 频道设置卡片使用的清源图标底板。
class _ChannelSurfaceIcon extends StatelessWidget {
  const _ChannelSurfaceIcon({required this.icon, required this.enabled});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? theme.color.brandTint : theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.s),
      ),
      child: SizedBox.square(
        dimension: theme.spacing.xl2,
        child: Icon(
          icon,
          size: theme.spacing.l,
          color: enabled ? theme.color.brandStrong : theme.color.border,
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

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = enabled ? theme.color.muted : theme.color.border;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: theme.breakpoint.medium / 4,
        maxWidth: theme.breakpoint.compact / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: theme.spacing.l,
            color: enabled ? theme.color.brandStrong : theme.color.border,
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.small.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  description,
                  style: theme.typography.small.copyWith(color: foreground),
                ),
                SizedBox(height: theme.spacing.s),
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

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return SizedBox(
      width: theme.spacing.xl2 * 2 + theme.spacing.xl + theme.spacing.xs,
      child: YhNumberField(
        label: '抓取条数',
        showLabel: false,
        value: value,
        enabled: enabled,
        suffix: '条',
        min: 1,
        max: 200,
        onChanged: onChanged,
        onSubmitted: onChanged,
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
    final theme = context.yhTheme;
    final subcategories = channelSubcategories[channelId]!;
    final labelColor = channelEnabled ? theme.color.muted : theme.color.border;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: theme.spacing.xl2 + theme.spacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '内容分类',
                style: theme.typography.small.copyWith(color: labelColor),
              ),
              YhChip(
                label: '${subcategories.length} 项',
                disabled: !channelEnabled,
              ),
            ],
          ),
          SizedBox(height: theme.spacing.xs),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              for (final subcategory in subcategories)
                YhChip(
                  label: subcategory.name,
                  selected:
                      categoryEnabledMap[subcategory.category.name] ?? true,
                  disabled: !channelEnabled,
                  onTap: () => onToggleCategory(subcategory.category),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
