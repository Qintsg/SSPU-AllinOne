/* 清源应用低频目的地抽屉内容。 */

import '../design/qingyuan/qingyuan_ui.dart';

class AppMoreDestination {
  const AppMoreDestination({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool selected;
}

/// “更多”抽屉的生产内容，compact 导航与视觉矩阵共享同一实现。
class AppMoreDestinationsContent extends StatelessWidget {
  const AppMoreDestinationsContent({super.key, required this.items});

  final List<AppMoreDestination> items;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          YhListItem(
            title: items[index].label,
            leading: Icon(items[index].icon, size: theme.spacing.l),
            trailing: Icon(
              items[index].selected ? YhIcons.check : YhIcons.chevronRight,
              size: theme.spacing.l,
            ),
            selected: items[index].selected,
            onTap: items[index].onSelected,
          ),
          if (index < items.length - 1)
            SizedBox(
              key: ValueKey('app-more-divider-$index'),
              height: theme.layout.divider,
              child: ColoredBox(color: theme.color.border),
            ),
        ],
      ],
    );
  }
}
