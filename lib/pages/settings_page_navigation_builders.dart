/*
 * 设置页导航与分区切换的纯展示构建器 — 通过参数接收状态，不直接持有页面状态
 * @Project : SSPU-AllinOne
 * @File : settings_page_navigation_builders.dart
 * @Author : Qintsg
 * @Date : 2026-08-21
 */

part of 'settings_page.dart';

/// 左侧导航（宽屏）或抽屉内容（紧凑端）的共享构建器。
///
/// :param context: 构建上下文，用于主题与尺寸。
/// :param selectedIndex: 当前选中的设置分区索引。
/// :param onSelect: 用户切换分区时回调。
/// :returns: 设置分区导航列表。
Widget _buildSettingsNavigationWidget({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onSelect,
}) {
  final theme = context.yhTheme;
  final captionStyle = theme.typography.caption.copyWith(
    color: theme.color.muted,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(
          theme.spacing.s,
          theme.spacing.xs,
          theme.spacing.s,
          theme.spacing.s,
        ),
        child: Text('系统设置', style: captionStyle),
      ),
      buildSettingsNavItem(
        context: context,
        index: 0,
        selectedIndex: selectedIndex,
        icon: YhIcons.settings,
        label: '常规',
        onTap: () => onSelect(0),
      ),
      SizedBox(height: theme.spacing.xs),
      buildSettingsNavItem(
        context: context,
        index: 1,
        selectedIndex: selectedIndex,
        icon: YhIcons.calendar,
        label: '学期',
        onTap: () => onSelect(1),
      ),
      SizedBox(height: theme.spacing.xs),
      buildSettingsNavItem(
        context: context,
        index: 2,
        selectedIndex: selectedIndex,
        icon: YhIcons.sync,
        label: '自动刷新',
        onTap: () => onSelect(2),
      ),
      SizedBox(height: theme.spacing.xs),
      buildSettingsNavItem(
        context: context,
        index: 3,
        selectedIndex: selectedIndex,
        icon: YhIcons.lock,
        label: '安全',
        onTap: () => onSelect(3),
      ),
      _buildSettingsDivider(context),
      Padding(
        padding: EdgeInsets.fromLTRB(
          theme.spacing.s,
          0,
          theme.spacing.s,
          theme.spacing.s,
        ),
        child: Text('消息推送设置', style: captionStyle),
      ),
      buildSettingsNavItem(
        context: context,
        index: 4,
        selectedIndex: selectedIndex,
        icon: YhIcons.education,
        label: '职能部门',
        onTap: () => onSelect(4),
      ),
      SizedBox(height: theme.spacing.xs),
      buildSettingsNavItem(
        context: context,
        index: 5,
        selectedIndex: selectedIndex,
        icon: YhIcons.library,
        label: '教学单位',
        onTap: () => onSelect(5),
      ),
      SizedBox(height: theme.spacing.xs),
      buildSettingsNavItem(
        context: context,
        index: 6,
        selectedIndex: selectedIndex,
        icon: YhIcons.chat,
        label: '微信推文',
        onTap: () => onSelect(6),
      ),
      _buildSettingsDivider(context),
      buildSettingsNavItem(
        context: context,
        index: 7,
        selectedIndex: selectedIndex,
        icon: YhIcons.info,
        label: '关于',
        onTap: () => onSelect(7),
      ),
    ],
  );
}

/// 设置分区间的细分割线。
///
/// :param context: 构建上下文，用于主题。
/// :returns: 分隔线部件。
Widget _buildSettingsDivider(BuildContext context) {
  final theme = context.yhTheme;
  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: theme.spacing.s,
      horizontal: theme.spacing.s,
    ),
    child: SizedBox(
      height: theme.layout.divider,
      width: double.infinity,
      child: ColoredBox(color: theme.color.border),
    ),
  );
}

/// 窄屏顶部下拉触发器。
///
/// :param context: 构建上下文，用于主题与按压状态。
/// :param selectedIndex: 当前选中的设置分区索引。
/// :param sections: 设置分区标签与图标列表。
/// :param focusNode: 触发器的焦点节点，关闭抽屉后归还焦点。
/// :param onOpenDrawer: 用户按下时打开设置分区抽屉的回调。
/// :returns: 下拉触发器部件。
Widget _buildSettingsTabCombo({
  required BuildContext context,
  required int selectedIndex,
  required List<({String label, IconData icon})> sections,
  required FocusNode focusNode,
  required VoidCallback onOpenDrawer,
}) {
  final theme = context.yhTheme;
  final current = sections[selectedIndex];
  return YhPressable(
    key: const Key('settings-narrow-section-trigger'),
    semanticLabel: '当前设置分区：${current.label}，打开设置分区',
    focusNode: focusNode,
    onPressed: onOpenDrawer,
    builder: (context, state, child) => DecoratedBox(
      decoration: BoxDecoration(
        color: state.hovered ? theme.color.brandTint : theme.color.surface,
        border: Border.all(
          color: state.focused ? theme.color.brandStrong : theme.color.border,
          width: theme.layout.controlBorder,
        ),
        borderRadius: BorderRadius.circular(theme.radius.s),
      ),
      child: child,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: theme.control.minimumTarget),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
        child: Row(
          children: [
            Icon(current.icon, size: theme.spacing.l),
            SizedBox(width: theme.spacing.s),
            Expanded(
              child: Text(
                current.label,
                style: theme.typography.body.copyWith(
                  fontWeight: theme.typography.semibold,
                ),
              ),
            ),
            Icon(
              YhIcons.chevronDown,
              size: theme.spacing.l,
              color: theme.color.muted,
            ),
          ],
        ),
      ),
    ),
  );
}
