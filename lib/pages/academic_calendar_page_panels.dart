/*
 * 校历页面面板 — 来源、查询学期与原始文档框架
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_panels.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_calendar_page.dart';

class _CalendarSourceCard extends StatelessWidget {
  const _CalendarSourceCard({required this.entry});

  final AcademicCalendarCacheEntry? entry;

  String _updatedAt(DateTime? value) {
    if (value == null) return '等待本机档案时间';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute 更新';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Container(
      constraints: BoxConstraints(
        minHeight: theme.control.touch + theme.spacing.xs,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Row(
        children: [
          Container(
            width: theme.spacing.s,
            height: theme.spacing.s,
            decoration: BoxDecoration(
              color: theme.color.serviceAcademic,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '教务处公开校历',
                  style: theme.typography.small.copyWith(
                    color: theme.color.foreground,
                    fontWeight: theme.typography.semibold,
                  ),
                ),
                Text(
                  '无需登录 · ${_updatedAt(entry?.fetchedAt)}',
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTermCard extends StatelessWidget {
  const _CalendarTermCard({
    required this.contextSummary,
    required this.selection,
    required this.availableTerms,
    required this.loading,
    required this.error,
    required this.enabled,
    required this.onChanged,
    required this.onRetry,
  });

  final AcademicTermContext? contextSummary;
  final AcademicTermChoice selection;
  final List<AcademicTermChoice> availableTerms;
  final bool loading;
  final String? error;
  final bool enabled;
  final ValueChanged<AcademicTermChoice> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    return Container(
      key: const Key('academic-calendar-term-context'),
      padding: EdgeInsets.all(compact ? theme.spacing.s : theme.spacing.m),
      decoration: BoxDecoration(
        color: theme.color.surface,
        border: Border.all(color: theme.color.border),
        borderRadius: BorderRadius.circular(theme.radius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '统一查询学期',
            style: theme.typography.caption.copyWith(
              color: theme.color.brandStrong,
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: compact ? theme.spacing.xs : theme.spacing.s),
          if (loading && contextSummary == null)
            const YhProgressBar(value: 0.5, semanticLabel: '正在读取当前学期与查询学期')
          else if (error != null && contextSummary == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!,
                  style: theme.typography.small.copyWith(
                    color: theme.color.danger,
                  ),
                ),
                SizedBox(height: theme.spacing.s),
                YhButton(
                  label: '重试学期设置',
                  variant: YhButtonVariant.secondary,
                  onTap: enabled ? onRetry : null,
                ),
              ],
            )
          else ...[
            AcademicTermSelector(
              selection: selection,
              availableTerms: availableTerms,
              contextSummary: contextSummary,
              enabled: enabled && !loading,
              variant: AcademicTermSelectorVariant.compact,
              onChanged: onChanged,
            ),
            if (error != null) ...[
              SizedBox(height: theme.spacing.s),
              Text(
                error!,
                style: theme.typography.small.copyWith(
                  color: theme.color.danger,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CalendarDocumentPanel extends StatelessWidget {
  const _CalendarDocumentPanel({
    required this.entry,
    required this.onFocus,
    required this.child,
  });

  final AcademicCalendarCacheEntry? entry;
  final VoidCallback? onFocus;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return ClipRRect(
      key: const Key('academic-calendar-document-panel'),
      borderRadius: BorderRadius.circular(theme.radius.l),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.color.surface,
          border: Border.all(color: theme.color.border),
          borderRadius: BorderRadius.circular(theme.radius.l),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: BoxConstraints(minHeight: theme.control.touch),
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.m,
                vertical: theme.spacing.s,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.color.border,
                    width: theme.layout.divider,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '原始证据',
                          style: theme.typography.caption.copyWith(
                            color: theme.color.serviceAcademic,
                          ),
                        ),
                        Text(
                          entry == null
                              ? '请选择学年'
                              : '${_yearLabel(entry!)}校历 PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.copyWith(
                            color: theme.color.foreground,
                            fontWeight: theme.typography.semibold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  YhButton(
                    label: '专注查看',
                    variant: YhButtonVariant.secondary,
                    minWidth:
                        MediaQuery.sizeOf(context).width <
                            theme.breakpoint.medium
                        ? theme.control.minimumTarget +
                              theme.spacing.l +
                              theme.spacing.xs
                        : null,
                    onTap: onFocus,
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
