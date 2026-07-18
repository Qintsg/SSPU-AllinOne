/* 清源线性进度。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhProgressBar extends StatelessWidget {
  const YhProgressBar({super.key, required this.value, this.semanticLabel});

  final double value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final normalized = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel ?? '加载进度',
      value: '${(normalized * 100).round()}%',
      child: SizedBox(
        height: theme.spacing.xs,
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.color.brandTint),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: normalized,
              child: ColoredBox(color: theme.color.brandStrong),
            ),
          ),
        ),
      ),
    );
  }
}
