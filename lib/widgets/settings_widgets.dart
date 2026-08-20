/*
 * 设置页公用组件 — 间隔选择器、时间选择器、渠道开关行、导航标签
 * @Project : SSPU-AllinOne
 * @File : settings_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-04-17
 */

import '../design/qingyuan/qingyuan_ui.dart';
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
  final theme = context.yhTheme;
  final foreground = enabled ? theme.color.muted : theme.color.border;

  return Padding(
    padding: EdgeInsetsDirectional.only(
      start: theme.spacing.xl,
      top: theme.spacing.s,
    ),
    child: Wrap(
      spacing: theme.spacing.s,
      runSpacing: theme.spacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(YhIcons.sync, size: 20, color: foreground),
        SizedBox(
          width: theme.spacing.xl2 * 3,
          child: YhSelect<int>(
            label: '自动刷新',
            showLabel: false,
            value: kIntervalOptions.containsKey(currentValue)
                ? currentValue
                : 0,
            options: [
              for (final entry in kIntervalOptions.entries)
                YhSelectOption<int>(value: entry.key, label: entry.value),
            ],
            enabled: enabled,
            onChanged: enabled
                ? (value) {
                    if (value != null) onChanged(value);
                  }
                : null,
          ),
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
  bool autofocus = false,
}) => _SettingsNavItem(
  isSelected: index == selectedIndex,
  icon: icon,
  label: label,
  onTap: onTap,
  autofocus: autofocus,
);

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.autofocus = false,
  });

  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.fast,
      disableAnimations: disableAnimations,
    );
    return YhPressable(
      semanticLabel: label,
      selected: isSelected,
      autofocus: autofocus,
      onPressed: onTap,
      builder: (context, state, child) {
        final selectedBackground = state.hovered
            ? theme.color.brand.withValues(alpha: 0.20)
            : theme.color.brandTint;
        final background = isSelected
            ? selectedBackground
            : state.hovered
            ? theme.color.sunken
            : theme.color.surface.withValues(alpha: 0);
        final foreground = isSelected
            ? theme.color.brandInk
            : theme.color.muted;
        return SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: duration,
            curve: theme.motion.curve,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: theme.spacing.m,
              vertical: theme.spacing.s,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(theme.radius.s),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: theme.spacing.xs,
                  height: theme.spacing.l,
                  margin: EdgeInsetsDirectional.only(end: theme.spacing.s),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.color.brandStrong
                        : theme.color.surface.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(theme.radius.full),
                  ),
                ),
                Icon(icon, color: foreground),
                SizedBox(width: theme.spacing.s),
                Expanded(
                  child: Text(
                    label,
                    style: theme.typography.body.copyWith(
                      color: foreground,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
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
  final theme = context.yhTheme;
  final foreground = enabled ? theme.color.muted : theme.color.border;

  Widget numberField() => SizedBox(
    width: theme.layout.settingsIndicatorWidth,
    child: YhNumberField(
      label: label,
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

  return LayoutBuilder(
    builder: (context, constraints) {
      final shouldStack = shouldStackSettingsControls(constraints);
      if (shouldStack) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.layout.formFieldWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label：',
                style: theme.typography.small.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: theme.spacing.xs),
              numberField(),
            ],
          ),
        );
      }

      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formFieldWidth),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label：',
                style: theme.typography.small.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: theme.spacing.s),
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
  bool stackTrailing = true,
  bool hideIconOnCompact = false,
}) {
  final theme = context.yhTheme;
  return LayoutBuilder(
    builder: (context, constraints) {
      final shouldStack = shouldStackSettingsControls(constraints);
      final hideIcon =
          hideIconOnCompact && constraints.maxWidth < theme.breakpoint.compact;
      final leading = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideIcon) ...[
            Icon(icon, color: iconColor ?? theme.color.brandStrong),
            SizedBox(width: theme.spacing.m),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                SizedBox(height: theme.spacing.xs),
                subtitle,
              ],
            ),
          ),
        ],
      );

      if (shouldStack && stackTrailing) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            SizedBox(height: theme.spacing.s),
            Padding(
              padding: EdgeInsetsDirectional.only(start: theme.spacing.xl2),
              child: trailing,
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: leading),
          SizedBox(width: theme.spacing.m),
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
  final theme = context.yhTheme;

  return Wrap(
    spacing: theme.spacing.xs,
    runSpacing: theme.spacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('$label ', style: theme.typography.small),
      SizedBox(
        width: theme.spacing.xl2 * 2,
        child: YhSelect<int>(
          label: '$label小时',
          showLabel: false,
          value: hour,
          options: List.generate(
            24,
            (h) => YhSelectOption<int>(
              value: h,
              label: h.toString().padLeft(2, '0'),
            ),
          ),
          onChanged: (h) {
            if (h != null) onChanged(h, minute);
          },
        ),
      ),
      Text(
        ':',
        style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
      ),
      SizedBox(
        width: theme.spacing.xl2 * 2,
        child: YhSelect<int>(
          label: '$label分钟',
          showLabel: false,
          value: [0, 15, 30, 45].contains(minute) ? minute : 0,
          options: const [
            YhSelectOption(value: 0, label: '00'),
            YhSelectOption(value: 15, label: '15'),
            YhSelectOption(value: 30, label: '30'),
            YhSelectOption(value: 45, label: '45'),
          ],
          onChanged: (m) {
            if (m != null) onChanged(hour, m);
          },
        ),
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
  final theme = context.yhTheme;

  return Row(
    children: [
      Icon(icon, color: theme.color.brandStrong),
      SizedBox(width: theme.spacing.m),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.typography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              subtitle,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
          ],
        ),
      ),
      YhSwitch(value: value, semanticLabel: title, onChanged: onChanged),
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
    padding: EdgeInsetsDirectional.only(bottom: context.yhTheme.spacing.xs),
    child: YhButton(
      label: label,
      onTap: onTap,
      leadingIcon: icon,
      variant: isSelected ? YhButtonVariant.secondary : YhButtonVariant.text,
      minWidth: double.infinity,
    ),
  );
}
