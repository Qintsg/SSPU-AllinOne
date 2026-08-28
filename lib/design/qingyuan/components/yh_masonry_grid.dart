/* 清源响应式瀑布流 — 按列轮转分配仪表盘卡片。 */

import 'package:flutter/widgets.dart';

typedef YhMasonryColumnResolver = int Function(double width);

class YhMasonryGrid extends StatelessWidget {
  const YhMasonryGrid({
    super.key,
    required this.children,
    required this.gap,
    required this.columnsForWidth,
  });

  final List<Widget> children;
  final double gap;
  final YhMasonryColumnResolver columnsForWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsForWidth(constraints.maxWidth)
            .clamp(1, children.length)
            .toInt();
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _column(children),
          );
        }
        final buckets = List.generate(columns, (_) => <Widget>[]);
        for (var index = 0; index < children.length; index += 1) {
          buckets[index % columns].add(children[index]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < columns; index += 1) ...[
              if (index > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _column(buckets[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _column(List<Widget> items) => [
    for (var index = 0; index < items.length; index += 1) ...[
      if (index > 0) SizedBox(height: gap),
      items[index],
    ],
  ];
}
