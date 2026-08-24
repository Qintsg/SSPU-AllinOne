/*
 * 清源筹码 — 筛选与已输入标签
 * @Project : SSPU-AllinOne
 * @File : yh_chip.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_icon_button.dart';

class YhChip extends StatelessWidget {
  const YhChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final enabled = !disabled;
    final content = _ChipSurface(
      label: label,
      selected: selected,
      disabled: disabled,
      onDeleted: enabled ? onDeleted : null,
    );
    if (onTap == null) return content;
    return YhPressable(
      semanticLabel: label,
      selected: selected,
      onPressed: enabled ? onTap : null,
      builder: (context, state, child) => _ChipSurface(
        label: label,
        selected: selected,
        disabled: state.disabled,
        hovered: state.hovered,
        pressed: state.pressed,
        onDeleted: enabled ? onDeleted : null,
      ),
      child: content,
    );
  }
}

class _ChipSurface extends StatelessWidget {
  const _ChipSurface({
    required this.label,
    required this.selected,
    required this.disabled,
    this.hovered = false,
    this.pressed = false,
    this.onDeleted,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final bool hovered;
  final bool pressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = theme.motion.effective(
      theme.motion.fast,
      disableAnimations: disableAnimations,
    );
    final foreground = selected ? theme.color.brandInk : theme.color.muted;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: AnimatedContainer(
        duration: duration,
        curve: theme.motion.curve,
        constraints: BoxConstraints(minHeight: theme.spacing.xl),
        padding: EdgeInsetsDirectional.only(
          start: theme.spacing.m - theme.spacing.xs / 2,
          end: onDeleted == null ? theme.spacing.m - theme.spacing.xs / 2 : 0,
        ),
        decoration: BoxDecoration(
          color: selected
              ? theme.color.brandTint
              : pressed
              ? theme.color.brand.withValues(alpha: 0.12)
              : theme.color.surface.withValues(alpha: 0),
          border: Border.all(
            color: selected || hovered ? theme.color.brand : theme.color.border,
          ),
          borderRadius: BorderRadius.circular(theme.radius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(YhIcons.check, size: theme.spacing.m, color: foreground),
              SizedBox(width: theme.spacing.xs),
            ],
            Text(
              label,
              style: theme.typography.small.copyWith(color: foreground),
            ),
            if (onDeleted != null)
              YhIconButton(
                icon: YhIcons.close,
                semanticLabel: '删除 $label',
                variant: YhIconButtonVariant.ghost,
                onTap: onDeleted,
              ),
          ],
        ),
      ),
    );
  }
}
