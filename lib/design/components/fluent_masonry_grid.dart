/*
 * Fluent 瀑布流网格 — 按列轮转分配卡片的仪表盘布局组件
 * @Project : SSPU-AllinOne
 * @File : fluent_masonry_grid.dart
 * @Author : Qintsg
 * @Date : 2026-06-11
 */

import 'package:fluent_ui/fluent_ui.dart';

/// 根据可用宽度返回列数。
typedef FluentMasonryColumnResolver = int Function(double width);

/// 列优先瀑布流：按 round-robin 把 [children] 分进多列，各列独立堆叠。
class FluentMasonryGrid extends StatelessWidget {
  const FluentMasonryGrid({
    super.key,
    required this.children,
    required this.gap,
    required this.columnsForWidth,
  });

  /// 待展示的卡片。
  final List<Widget> children;

  /// 列间距与列内项目间距。
  final double gap;

  /// 宽度到列数的映射。
  final FluentMasonryColumnResolver columnsForWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedColumns = columnsForWidth(constraints.maxWidth);
        final columns = resolvedColumns.clamp(1, children.length).toInt();
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildColumnChildren(children),
          );
        }

        final buckets = List.generate(columns, (_) => <Widget>[]);
        for (var index = 0; index < children.length; index++) {
          buckets[index % columns].add(children[index]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var columnIndex = 0; columnIndex < columns; columnIndex++) ...[
              if (columnIndex > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildColumnChildren(buckets[columnIndex]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildColumnChildren(List<Widget> columnChildren) {
    return [
      for (var index = 0; index < columnChildren.length; index++) ...[
        if (index > 0) SizedBox(height: gap),
        columnChildren[index],
      ],
    ];
  }
}
