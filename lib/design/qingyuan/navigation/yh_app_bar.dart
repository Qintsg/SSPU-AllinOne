/* 清源页面顶栏。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhAppBar extends StatelessWidget {
  const YhAppBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.actions = const <Widget>[],
    this.brand = false,
    this.scrolled = false,
    this.horizontalPadding,
    this.actionSpacing,
  });

  final String title;
  final String? eyebrow;
  final Widget? leading;
  final List<Widget> actions;
  final bool brand;
  final bool scrolled;
  final double? horizontalPadding;
  final double? actionSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = brand ? theme.color.onBrand : theme.color.foreground;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    return SizedBox(
      height: theme.layout.appBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand ? theme.color.brandStrong : theme.color.surface,
          border: scrolled || !brand
              ? Border(bottom: BorderSide(color: theme.color.border))
              : null,
          boxShadow: scrolled ? theme.elevation.e1 : const [],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
                horizontalPadding ??
                (eyebrow != null && compact
                    ? theme.spacing.s
                    : theme.spacing.m),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(
                  width: eyebrow == null ? theme.spacing.s : theme.spacing.m,
                ),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: eyebrow == null
                      ? Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.h3.copyWith(
                            color: foreground,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eyebrow!,
                              style: theme.typography.caption.copyWith(
                                color: brand
                                    ? foreground.withValues(
                                        alpha: theme.opacity.contentMuted,
                                      )
                                    : theme.color.muted,
                              ),
                            ),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typography.small.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (actions.isNotEmpty) ...[
                SizedBox(width: theme.spacing.s),
                for (
                  var index = 0;
                  index < actions.take(2).length;
                  index++
                ) ...[
                  if (index > 0) SizedBox(width: actionSpacing ?? 0),
                  actions[index],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
