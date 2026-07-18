/* 清源页签导航。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../theme/yh_theme.dart';

@immutable
class YhTab<T> {
  const YhTab({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class YhTabs<T> extends StatelessWidget {
  const YhTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
  });

  final List<YhTab<T>> tabs;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        children: [
          for (final tab in tabs)
            YhPressable(
              semanticLabel: tab.label,
              selected: tab.value == value,
              inMutuallyExclusiveGroup: true,
              onPressed: onChanged == null ? null : () => onChanged!(tab.value),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab.value == value
                          ? theme.color.brandStrong
                          : const Color(0x00000000),
                      width: theme.focus.ringWidth,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.m,
                    vertical: theme.spacing.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.icon != null) ...[
                        Icon(tab.icon, size: theme.spacing.l),
                        SizedBox(width: theme.spacing.s),
                      ],
                      Text(
                        tab.label,
                        style: theme.typography.body.copyWith(
                          color: tab.value == value
                              ? theme.color.brandInk
                              : theme.color.muted,
                          fontWeight: tab.value == value
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
