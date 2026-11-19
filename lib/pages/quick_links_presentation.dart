/*
 * 快捷入口展示辅助 — 状态文案、页面标题与响应式边距
 * @Project : SSPU-AllinOne
 * @File : quick_links_presentation.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'quick_links_page.dart';

class _QuickLinksStateMessage extends StatelessWidget {
  const _QuickLinksStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compactGap = theme.spacing.xs + theme.layout.divider * 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: theme.control.regular,
            height: theme.control.regular,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.color.brandTint,
              borderRadius: BorderRadius.circular(theme.radius.m),
            ),
            child: Icon(
              icon,
              size: theme.spacing.l,
              color: theme.color.brandStrong,
            ),
          ),
        ),
        SizedBox(height: compactGap),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.typography.h3.copyWith(
              color: theme.color.foreground,
              fontWeight: theme.typography.semibold,
            ),
          ),
        ),
        SizedBox(height: compactGap),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: theme.layout.statusProgressWidth,
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
        ),
        if (action != null) ...[SizedBox(height: theme.spacing.s), action!],
      ],
    );
  }
}

class _QuickLinksHeader extends StatelessWidget {
  const _QuickLinksHeader();

  @override
  Widget build(BuildContext context) => const YhPageHeading(title: '常用校园入口');
}

class _FocusQuickLinkSearchIntent extends Intent {
  const _FocusQuickLinkSearchIntent();
}

EdgeInsets _quickLinksPagePadding(YhTheme theme, double viewportWidth) {
  if (viewportWidth < theme.breakpoint.medium) {
    return EdgeInsets.symmetric(
      horizontal: theme.spacing.m,
      vertical: theme.spacing.l + theme.spacing.s + theme.layout.divider * 3,
    );
  }
  final progress =
      ((viewportWidth - theme.breakpoint.medium) /
              (theme.breakpoint.expanded - theme.breakpoint.medium))
          .clamp(0.0, 1.0);
  final horizontal =
      theme.spacing.xl + (theme.spacing.xl2 - theme.spacing.xl) * progress;
  return EdgeInsets.symmetric(
    horizontal: horizontal,
    vertical: theme.spacing.xl + theme.spacing.s,
  );
}

double _quickLinksSectionGap(YhTheme theme, double viewportWidth) =>
    viewportWidth < theme.breakpoint.medium
    ? theme.spacing.l + theme.spacing.xs
    : theme.spacing.l;
