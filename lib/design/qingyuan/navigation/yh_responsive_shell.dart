/* 清源响应式应用壳。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';
import 'yh_navigation.dart';

class YhResponsiveShell extends StatelessWidget {
  const YhResponsiveShell({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    required this.child,
  });

  final List<YhNavigationItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = context.yhTheme;
        final showRail = constraints.maxWidth >= theme.breakpoint.medium;
        if (!showRail) {
          return Column(
            children: [
              Expanded(child: child),
              YhBottomNav(items: items, index: index, onChanged: onChanged),
            ],
          );
        }
        return Row(
          children: [
            YhNavRail(
              items: items,
              index: index,
              onChanged: onChanged,
              extended: constraints.maxWidth >= theme.breakpoint.expanded,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
