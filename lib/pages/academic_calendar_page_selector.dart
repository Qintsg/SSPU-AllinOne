/*
 * 校历页面选择器 — 学年选择与键盘焦点行为
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_selector.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_calendar_page.dart';

class _CalendarSelector extends StatelessWidget {
  const _CalendarSelector({
    required this.entries,
    required this.selected,
    required this.compact,
    required this.enabled,
    required this.onSelected,
  });

  /// 校历条目。
  final List<AcademicCalendarCacheEntry> entries;

  /// 当前选中条目。
  final AcademicCalendarCacheEntry? selected;

  /// 是否为紧凑横向选择器。
  final bool compact;

  /// 远端操作期间冻结学年切换，避免目标与结果错配。
  final bool enabled;

  /// 选择条目回调。
  final ValueChanged<AcademicCalendarCacheEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    if (compact) {
      return SizedBox(
        height: theme.control.regular + theme.spacing.m,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: entries.length,
          separatorBuilder: (_, _) => SizedBox(width: theme.spacing.xs),
          itemBuilder: (context, index) => SizedBox(
            width: theme.spacing.xl2 * 4,
            child: _CalendarSelectorItem(
              entry: entries[index],
              selected:
                  selected?.schoolYearStart == entries[index].schoolYearStart,
              onPressed: enabled ? () => onSelected(entries[index]) : null,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => SizedBox(height: theme.spacing.xs),
      itemBuilder: (context, index) => _CalendarSelectorItem(
        entry: entries[index],
        selected: selected?.schoolYearStart == entries[index].schoolYearStart,
        onPressed: enabled ? () => onSelected(entries[index]) : null,
      ),
    );
  }
}

class _CalendarSelectorItem extends StatelessWidget {
  const _CalendarSelectorItem({
    required this.entry,
    required this.selected,
    required this.onPressed,
  });

  /// 校历条目。
  final AcademicCalendarCacheEntry entry;

  /// 是否选中。
  final bool selected;

  /// 点击回调。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disabled = onPressed == null;
    return YhPressable(
      semanticLabel: '打开${_yearLabel(entry)}',
      onPressed: onPressed,
      builder: (context, state, child) => AnimatedContainer(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: theme.control.touch + theme.spacing.m,
        ),
        duration: theme.motion.effective(
          theme.motion.fast,
          disableAnimations:
              MediaQuery.maybeOf(context)?.disableAnimations ?? false,
        ),
        curve: theme.motion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        ),
        decoration: BoxDecoration(
          color: selected
              ? disabled
                    ? Color.alphaBlend(
                        theme.color.serviceAcademic.withValues(
                          alpha:
                              theme.opacity.evidenceTint *
                              theme.opacity.disabled,
                        ),
                        theme.color.surface,
                      )
                    : Color.alphaBlend(
                        theme.color.serviceAcademic.withValues(
                          alpha: theme.opacity.evidenceTint,
                        ),
                        theme.color.surface,
                      )
              : state.hovered
              ? theme.color.sunken
              : theme.color.surface,
          border: Border.all(
            color: selected
                ? disabled
                      ? theme.color.serviceAcademic.withValues(
                          alpha: theme.opacity.disabled,
                        )
                      : theme.color.serviceAcademic
                : theme.color.border,
          ),
          borderRadius: BorderRadius.circular(theme.radius.s),
        ),
        child: Opacity(
          opacity: disabled ? theme.opacity.disabled : 1,
          child: child,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _yearLabel(entry),
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.copyWith(
              color: selected
                  ? theme.color.serviceAcademic
                  : theme.color.foreground,
              fontWeight: theme.typography.semibold,
            ),
          ),
          Text(
            entry.publishDate.isEmpty ? 'PDF' : entry.publishDate,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
        ],
      ),
    );
  }
}
