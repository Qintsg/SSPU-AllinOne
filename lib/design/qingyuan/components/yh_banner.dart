/* 清源持续提示横幅。 */

import 'package:flutter/widgets.dart';

import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_icon_button.dart';

enum YhBannerKind { info, success, warn, danger }

class YhBanner extends StatelessWidget {
  const YhBanner({
    super.key,
    required this.text,
    this.kind = YhBannerKind.info,
    this.leadingIcon,
    this.action,
    this.onClose,
    this.denseLeading = false,
  });

  final String text;
  final YhBannerKind kind;
  final IconData? leadingIcon;
  final Widget? action;
  final VoidCallback? onClose;
  final bool denseLeading;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final colors = switch (kind) {
      YhBannerKind.info => (theme.color.brandTint, theme.color.brandInk),
      YhBannerKind.success => (theme.color.successTint, theme.color.success),
      YhBannerKind.warn => (theme.color.warningTint, theme.color.warning),
      YhBannerKind.danger => (theme.color.dangerTint, theme.color.danger),
    };
    final icon =
        leadingIcon ??
        switch (kind) {
          YhBannerKind.info => YhIcons.info,
          YhBannerKind.success => YhIcons.check,
          YhBannerKind.warn || YhBannerKind.danger => YhIcons.warning,
        };
    return Semantics(
      liveRegion: kind == YhBannerKind.warn || kind == YhBannerKind.danger,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.s + theme.spacing.xs + theme.layout.divider * 2,
            theme.spacing.s +
                theme.spacing.xs +
                (compact ? theme.layout.divider : 0),
            theme.spacing.s + theme.spacing.xs + theme.layout.divider * 2,
            theme.spacing.s + theme.spacing.xs + theme.layout.divider,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: denseLeading
                    ? theme.spacing.m
                    : theme.spacing.m + theme.layout.divider * 2,
                color: colors.$2,
              ),
              SizedBox(
                width: denseLeading
                    ? theme.spacing.s
                    : theme.spacing.s + theme.layout.divider * 2,
              ),
              Expanded(
                child: Text(
                  text,
                  style: theme.typography.small.copyWith(color: colors.$2),
                ),
              ),
              ?action,
              if (onClose != null)
                YhIconButton(
                  icon: YhIcons.close,
                  semanticLabel: '关闭提示',
                  variant: YhIconButtonVariant.ghost,
                  onTap: onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
