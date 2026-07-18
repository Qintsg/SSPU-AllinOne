/* 清源分页 — 首尾、当前邻页与省略号。 */

import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_icon_button.dart';

class YhPagination extends StatelessWidget {
  const YhPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.simple = false,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int>? onChanged;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final normalizedCount = pageCount < 1 ? 1 : pageCount;
    final normalizedPage = page.clamp(1, normalizedCount);
    final theme = context.yhTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '分页，第 $normalizedPage 页，共 $normalizedCount 页',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          YhIconButton(
            icon: YhIcons.back,
            semanticLabel: '上一页',
            onTap: normalizedPage > 1 && onChanged != null
                ? () => onChanged!(normalizedPage - 1)
                : null,
          ),
          if (simple)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
              child: Text(
                '第 $normalizedPage / $normalizedCount 页',
                style: theme.typography.small.copyWith(
                  color: theme.color.foreground,
                  fontFamily: YhTypographyTokens.fontFamilyMono,
                ),
              ),
            )
          else
            ..._pageItems(normalizedPage, normalizedCount).map(
              (item) => item == null
                  ? SizedBox(
                      width: theme.control.compact,
                      child: Text(
                        '…',
                        textAlign: TextAlign.center,
                        style: theme.typography.body.copyWith(
                          color: theme.color.muted,
                        ),
                      ),
                    )
                  : _PageButton(
                      page: item,
                      selected: item == normalizedPage,
                      onTap: onChanged == null ? null : () => onChanged!(item),
                    ),
            ),
          YhIconButton(
            icon: YhIcons.chevronRight,
            semanticLabel: '下一页',
            onTap: normalizedPage < normalizedCount && onChanged != null
                ? () => onChanged!(normalizedPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  List<int?> _pageItems(int current, int count) {
    final pages = <int>{
      1,
      count,
      current - 1,
      current,
      current + 1,
    }.where((page) => page >= 1 && page <= count).toList()..sort();
    final result = <int?>[];
    for (var index = 0; index < pages.length; index += 1) {
      if (index > 0 && pages[index] - pages[index - 1] > 1) {
        result.add(null);
      }
      result.add(pages[index]);
    }
    return result;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: '第 $page 页',
      selected: selected,
      onPressed: selected ? null : onTap,
      builder: (context, state, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? theme.color.brandStrong
              : state.hovered
              ? theme.color.brandTint
              : theme.color.surface,
          border: Border.all(
            color: selected ? theme.color.brandStrong : theme.color.border,
          ),
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: theme.control.compact,
        child: Center(
          child: Text(
            '$page',
            style: theme.typography.small.copyWith(
              color: selected ? theme.color.onBrand : theme.color.foreground,
              fontFamily: YhTypographyTokens.fontFamilyMono,
            ),
          ),
        ),
      ),
    );
  }
}
