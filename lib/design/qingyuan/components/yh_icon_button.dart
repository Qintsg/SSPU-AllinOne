/* 清源图标按钮。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

enum YhIconButtonVariant { outline, ghost }

class YhIconButton extends StatelessWidget {
  const YhIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.selected = false,
    this.variant = YhIconButtonVariant.outline,
    this.disabled = false,
    this.size,
    this.focusNode,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool selected;
  final YhIconButtonVariant variant;
  final bool disabled;
  final double? size;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final effectiveSize = size ?? theme.control.regular;
    return YhPressable(
      semanticLabel: semanticLabel,
      onPressed: disabled ? null : onTap,
      selected: selected ? true : null,
      focusNode: focusNode,
      builder: (context, state, child) => Opacity(
        opacity: state.disabled ? 0.4 : 1,
        child: SizedBox.square(
          dimension: effectiveSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? theme.color.brandTint
                  : state.pressed
                  ? theme.color.brand.withValues(alpha: 0.16)
                  : state.hovered
                  ? theme.color.brand.withValues(alpha: 0.10)
                  : theme.color.surface.withValues(alpha: 0),
              border: variant == YhIconButtonVariant.outline
                  ? Border.all(
                      color: selected || state.hovered || state.focused
                          ? theme.color.brandStrong
                          : theme.color.border,
                      width: theme.layout.controlBorder,
                    )
                  : null,
              borderRadius: BorderRadius.circular(theme.radius.s),
            ),
            child: Center(child: child),
          ),
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: selected ? theme.color.brandStrong : theme.color.muted,
      ),
    );
  }
}
