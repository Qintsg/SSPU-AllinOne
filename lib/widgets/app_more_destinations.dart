/* 清源应用低频目的地抽屉内容。 */

import '../design/qingyuan/qingyuan_ui.dart';

class AppMoreDestination {
  const AppMoreDestination({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.description,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final String? description;
  final bool selected;
}

/// “更多”抽屉的生产内容，compact 导航与视觉矩阵共享同一实现。
class AppMoreDestinationsContent extends StatelessWidget {
  const AppMoreDestinationsContent({super.key, required this.items});

  final List<AppMoreDestination> items;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    String descriptionFor(AppMoreDestination item) {
      if (item.description != null) return item.description!;
      return switch (item.label) {
        '邮箱' => '查看学校邮件',
        '跳转' => '打开校园服务',
        '设置' => '管理本地数据',
        _ => '打开${item.label}',
      };
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          YhListItem(
            title: items[index].label,
            subtitle: descriptionFor(items[index]),
            leading: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.color.brandTint,
                borderRadius: BorderRadius.circular(theme.radius.input),
              ),
              child: SizedBox.square(
                dimension: theme.control.minimumTarget,
                child: Icon(
                  items[index].icon,
                  size: theme.spacing.l,
                  color: theme.color.brandInk,
                ),
              ),
            ),
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
