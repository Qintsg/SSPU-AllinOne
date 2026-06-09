/*
 * 设置页公用组件 — 间隔选择器、时间选择器、渠道开关行、导航标签
 * @Project : SSPU-AllinOne
 * @File : settings_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-04-17
 */

import 'package:flutter/services.dart';

import '../design/fluent_ui.dart';
import '../theme/app_motion.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import 'responsive_layout.dart';

/// 可选的自动刷新间隔（分钟 => 显示文本）。
const Map<int, String> kIntervalOptions = {
  0: '关闭',
  15: '15 分钟',
  30: '30 分钟',
  60: '1 小时',
  120: '2 小时',
  360: '6 小时',
  720: '12 小时',
  1440: '24 小时',
};

/// 构建自动刷新间隔选择器。
Widget buildIntervalSelector({
  required BuildContext context,
  required int currentValue,
  required bool enabled,
  required Future<void> Function(int minutes) onChanged,
}) {
  final colors = context.fluentColors;
  final type = context.fluentType;
  final disabledColor = colors.neutralForegroundDisabled;

  return Padding(
    padding: const EdgeInsetsDirectional.only(
      start: AppSpacing.xl,
      top: AppSpacing.sm,
    ),
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          FluentIcons.sync,
          size: 20,
          color: enabled ? colors.neutralForeground2 : disabledColor,
        ),
        Text(
          '自动刷新：',
          style: type.caption1.copyWith(
            color: enabled ? colors.neutralForeground2 : disabledColor,
          ),
        ),
        FluentSelect<int>(
          value: kIntervalOptions.containsKey(currentValue) ? currentValue : 0,
          items: kIntervalOptions.entries
              .map(
                (entry) => FluentSelectItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onChanged(value);
                }
              : null,
        ),
      ],
    ),
  );
}

/// 构建左侧垂直导航项目。
Widget buildSettingsNavItem({
  required BuildContext context,
  required int index,
  required int selectedIndex,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final isSelected = index == selectedIndex;
  final colors = context.fluentColors;
  final type = context.fluentType;

  return _SettingsNavItem(
    isSelected: isSelected,
    icon: icon,
    label: label,
    onTap: onTap,
    colors: colors,
    type: type,
  );
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    required this.type,
  });

  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final FluentColors colors;
  final FluentTypography type;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: HoverButton(
        cursor: SystemMouseCursors.click,
        onPressed: onTap,
        semanticLabel: label,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        builder: (context, states) {
          final style = _resolveSettingsNavItemStyle(
            context: context,
            colors: colors,
            type: type,
            states: states,
            isSelected: isSelected,
          );

          return SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: AppMotion.short,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: AppShapes.md,
                border: Border.all(color: style.border, width: 2),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppMotion.short,
                    width: 4,
                    height: 24,
                    margin: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: style.indicator,
                      borderRadius: AppShapes.xs,
                    ),
                  ),
                  Icon(icon, color: style.foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, style: style.labelStyle)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsNavItemStyle {
  const _SettingsNavItemStyle({
    required this.background,
    required this.border,
    required this.indicator,
    required this.foreground,
    required this.labelStyle,
  });

  /// 导航项背景色。
  final Color background;

  /// 导航项焦点描边色。
  final Color border;

  /// 选中指示条颜色。
  final Color indicator;

  /// 图标前景色。
  final Color foreground;

  /// 标签文本样式。
  final TextStyle labelStyle;
}

/// 根据 Fluent 交互状态解析设置导航项视觉。
_SettingsNavItemStyle _resolveSettingsNavItemStyle({
  required BuildContext context,
  required FluentColors colors,
  required FluentTypography type,
  required Set<WidgetState> states,
  required bool isSelected,
}) {
  final resources = FluentTheme.of(context).resources;

  if (states.isDisabled) {
    return _SettingsNavItemStyle(
      background: Colors.transparent,
      border: Colors.transparent,
      indicator: Colors.transparent,
      foreground: colors.neutralForegroundDisabled,
      labelStyle: type.body1.copyWith(color: colors.neutralForegroundDisabled),
    );
  }

  final background = _resolveSettingsNavItemBackground(
    resources: resources,
    states: states,
    isSelected: isSelected,
  );
  final foreground = isSelected
      ? colors.brandForeground1
      : colors.neutralForeground2;

  return _SettingsNavItemStyle(
    background: background,
    border: states.isFocused ? colors.brandStroke1 : Colors.transparent,
    indicator: isSelected ? colors.brandBackground : Colors.transparent,
    foreground: foreground,
    labelStyle: isSelected
        ? type.body1Strong.copyWith(color: foreground)
        : type.body1.copyWith(color: foreground),
  );
}

/// 对齐 `NavigationPane` 普通导航项的浅色背景状态。
Color _resolveSettingsNavItemBackground({
  required ResourceDictionary resources,
  required Set<WidgetState> states,
  required bool isSelected,
}) {
  if (isSelected) {
    return states.isHovered || states.isPressed
        ? resources.subtleFillColorTertiary
        : resources.subtleFillColorSecondary;
  }

  if (states.isPressed) return resources.subtleFillColorTertiary;
  if (states.isHovered) return resources.subtleFillColorSecondary;

  return resources.subtleFillColorTransparent;
}

/// 构建数值设置框。
/// 适用于手动刷新条数、自动刷新条数等正整数输入项。
Widget buildCountNumberBox({
  required BuildContext context,
  required String label,
  required int value,
  required bool enabled,
  required ValueChanged<int> onChanged,
}) {
  final colors = context.fluentColors;
  final type = context.fluentType;
  final foreground = enabled
      ? colors.neutralForeground2
      : colors.neutralForegroundDisabled;

  Widget numberField() => SizedBox(
    width: 128,
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

  return LayoutBuilder(
    builder: (context, constraints) {
      final shouldStack = shouldStackSettingsControls(constraints);
      if (shouldStack) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label：',
                style: type.caption1.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              numberField(),
            ],
          ),
        );
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label：',
                style: type.caption1.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            numberField(),
          ],
        ),
      );
    },
  );
}

/// 构建可在窄屏自动堆叠尾部控件的设置行。
Widget buildResponsiveSettingsRow({
  required BuildContext context,
  required IconData icon,
  required Widget title,
  required Widget subtitle,
  required Widget trailing,
  Color? iconColor,
}) {
  final colors = context.fluentColors;
  return LayoutBuilder(
    builder: (context, constraints) {
      final shouldStack = shouldStackSettingsControls(constraints);
      final leading = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? colors.brandForeground1),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.xs),
                subtitle,
              ],
            ),
          ),
        ],
      );

      if (shouldStack) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.xxl),
              child: trailing,
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: leading),
          const SizedBox(width: AppSpacing.md),
          trailing,
        ],
      );
    },
  );
}

/// 构建时间选择器（小时 + 分钟下拉框）。
Widget buildTimePicker({
  required BuildContext context,
  required String label,
  required int hour,
  required int minute,
  required Future<void> Function(int h, int m) onChanged,
}) {
  final type = context.fluentType;

  return Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('$label ', style: type.caption1),
      FluentSelect<int>(
        value: hour,
        items: List.generate(
          24,
          (h) => FluentSelectItem<int>(
            value: h,
            child: Text(h.toString().padLeft(2, '0')),
          ),
        ),
        onChanged: (h) {
          if (h != null) onChanged(h, minute);
        },
      ),
      Text(':', style: type.body1Strong),
      FluentSelect<int>(
        value: [0, 15, 30, 45].contains(minute) ? minute : 0,
        items: const [
          FluentSelectItem(value: 0, child: Text('00')),
          FluentSelectItem(value: 15, child: Text('15')),
          FluentSelectItem(value: 30, child: Text('30')),
          FluentSelectItem(value: 45, child: Text('45')),
        ],
        onChanged: (m) {
          if (m != null) onChanged(hour, m);
        },
      ),
    ],
  );
}

/// 构建信息渠道开关行。
Widget buildChannelToggle({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  final colors = context.fluentColors;
  final type = context.fluentType;

  return Row(
    children: [
      Icon(icon, color: colors.brandForeground1),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: type.body1Strong),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: type.caption1.copyWith(color: colors.neutralForeground2),
            ),
          ],
        ),
      ),
      FluentSwitch(value: value, onChanged: onChanged),
    ],
  );
}

/// 构建设置分区导航栏按钮。
Widget buildNavTab({
  required BuildContext context,
  required int index,
  required int selectedIndex,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final isSelected = selectedIndex == index;

  return Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
    child: isSelected
        ? FluentButton.secondaryIcon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          )
        : FluentButton.transparentIcon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          ),
  );
}
