/*
 * 设置页公用组件 — 间隔选择器、时间选择器、渠道开关行、导航标签
 * @Project : SSPU-AllinOne
 * @File : settings_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-04-17
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final disabledColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

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
          Icons.sync,
          size: 20,
          color: enabled ? colorScheme.onSurfaceVariant : disabledColor,
        ),
        Text(
          '自动刷新：',
          style: textTheme.bodySmall?.copyWith(
            color: enabled ? colorScheme.onSurfaceVariant : disabledColor,
          ),
        ),
        DropdownButton<int>(
          value: kIntervalOptions.containsKey(currentValue) ? currentValue : 0,
          items: kIntervalOptions.entries
              .map(
                (entry) => DropdownMenuItem<int>(
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
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppShapes.md,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedContainer(
          duration: AppMotion.short,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : null,
            borderRadius: AppShapes.md,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.short,
                width: 4,
                height: 24,
                margin: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: AppShapes.xs,
                ),
              ),
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: isSelected
                      ? textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        )
                      : textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final foreground = enabled
      ? colorScheme.onSurfaceVariant
      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

  Widget numberField() {
    return SizedBox(
      width: 128,
      child: TextFormField(
        key: ValueKey('$label-$value-$enabled'),
        initialValue: value.toString(),
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(isDense: true, suffixText: '条'),
        onChanged: (newValue) {
          final parsed = int.tryParse(newValue);
          if (parsed == null) return;
          onChanged(parsed.clamp(1, 200));
        },
        onFieldSubmitted: (newValue) {
          final parsed = int.tryParse(newValue);
          onChanged((parsed ?? value).clamp(1, 200));
        },
      ),
    );
  }

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
                style: textTheme.bodySmall?.copyWith(color: foreground),
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
                style: textTheme.bodySmall?.copyWith(color: foreground),
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
  return LayoutBuilder(
    builder: (context, constraints) {
      final shouldStack = shouldStackSettingsControls(constraints);
      final leading = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
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
  final textTheme = Theme.of(context).textTheme;

  return Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('$label ', style: textTheme.bodySmall),
      DropdownButton<int>(
        value: hour,
        items: List.generate(
          24,
          (h) => DropdownMenuItem<int>(
            value: h,
            child: Text(h.toString().padLeft(2, '0')),
          ),
        ),
        onChanged: (h) {
          if (h != null) onChanged(h, minute);
        },
      ),
      Text(':', style: textTheme.titleSmall),
      DropdownButton<int>(
        value: [0, 15, 30, 45].contains(minute) ? minute : 0,
        items: const [
          DropdownMenuItem(value: 0, child: Text('00')),
          DropdownMenuItem(value: 15, child: Text('15')),
          DropdownMenuItem(value: 30, child: Text('30')),
          DropdownMenuItem(value: 45, child: Text('45')),
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
  final textTheme = Theme.of(context).textTheme;
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    children: [
      Icon(icon, color: colorScheme.primary),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      Switch(value: value, onChanged: onChanged),
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
  final colorScheme = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
    child: isSelected
        ? FilledButton.tonalIcon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          )
        : TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          ),
  );
}
