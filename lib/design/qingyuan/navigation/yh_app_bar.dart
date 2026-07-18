/* 清源页面顶栏。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhAppBar extends StatelessWidget {
  const YhAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.brand = false,
    this.scrolled = false,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool brand;
  final bool scrolled;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = brand ? theme.color.onBrand : theme.color.foreground;
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
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: theme.spacing.s),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.h3.copyWith(color: foreground),
                  ),
                ),
              ),
              if (actions.isNotEmpty) ...[
                SizedBox(width: theme.spacing.s),
                ...actions.take(2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
