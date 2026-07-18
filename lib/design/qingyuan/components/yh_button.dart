/* 清源按钮 — 四种语义层级共享统一交互基座。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

enum YhButtonVariant { primary, secondary, text, danger }

class YhButton extends StatelessWidget {
  const YhButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = YhButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.disabled = false,
    this.minWidth,
    this.height,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onTap;
  final YhButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool disabled;
  final double? minWidth;
  final double? height;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final effectiveHeight = height ?? theme.control.regular;
    final contentHeight = effectiveHeight - theme.focus.ringWidth * 2;
    final effectiveMinWidth = minWidth ?? theme.control.minimumTarget * 2;
    final enabled = !disabled && onTap != null;

    return YhPressable(
      semanticLabel: label,
      onPressed: enabled ? onTap : null,
      autofocus: autofocus,
      builder: (context, state, child) {
        final colors = _resolveColors(context, state);
        return Opacity(
          opacity: state.disabled ? 0.4 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              border: colors.border == null
                  ? null
                  : Border.all(
                      color: colors.border!,
                      width: theme.layout.controlBorder,
                    ),
              borderRadius: BorderRadius.circular(theme.radius.m),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: effectiveMinWidth,
                minHeight: contentHeight,
                maxHeight: contentHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
                child: DefaultTextStyle(
                  style: theme.typography.body.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 20),
            SizedBox(width: theme.spacing.s),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (trailingIcon != null) ...[
            SizedBox(width: theme.spacing.s),
            Icon(trailingIcon, size: 20),
          ],
        ],
      ),
    );
  }

  _YhButtonColors _resolveColors(BuildContext context, YhPressableState state) {
    final colors = context.yhTheme.color;
    final overlayAlpha = state.pressed
        ? 0.18
        : state.hovered
        ? 0.10
        : 0.0;
    return switch (variant) {
      YhButtonVariant.primary => _YhButtonColors(
        background: Color.alphaBlend(
          colors.foreground.withValues(alpha: overlayAlpha),
          colors.brandStrong,
        ),
        foreground: colors.onBrand,
      ),
      YhButtonVariant.danger => _YhButtonColors(
        background: Color.alphaBlend(
          colors.foreground.withValues(alpha: overlayAlpha),
          colors.danger,
        ),
        foreground: colors.onBrand,
      ),
      YhButtonVariant.secondary => _YhButtonColors(
        background: colors.brand.withValues(alpha: overlayAlpha),
        foreground: colors.brandStrong,
        border: colors.brand,
      ),
      YhButtonVariant.text => _YhButtonColors(
        background: colors.brand.withValues(alpha: overlayAlpha),
        foreground: colors.brandStrong,
      ),
    };
  }
}

class _YhButtonColors {
  const _YhButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
