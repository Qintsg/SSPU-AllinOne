/* 清源图标按钮。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

class YhIconButton extends StatelessWidget {
  const YhIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: semanticLabel,
      onPressed: onTap,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? theme.color.brandTint
              : state.pressed
              ? theme.color.brand.withValues(alpha: 0.16)
              : state.hovered
              ? theme.color.brand.withValues(alpha: 0.10)
              : theme.color.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: child,
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? theme.color.brandStrong : theme.color.muted,
      ),
    );
  }
}
