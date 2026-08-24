/*
 * 快捷入口状态页 — 本地加载、空结果与恢复动作
 * @Project : SSPU-AllinOne
 * @File : quick_links_status_page.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'quick_links_page.dart';

class _QuickLinksStatusPage extends StatelessWidget {
  const _QuickLinksStatusPage({
    required this.title,
    required this.message,
    this.icon,
    this.action,
    this.loading = false,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    Widget withStateSizeTransition(Widget stateCard) {
      if (disableAnimations) return stateCard;
      return AnimatedSize(
        duration: theme.motion.base,
        curve: theme.motion.curve,
        child: stateCard,
      );
    }

    return YhPageScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final padding = _quickLinksPagePadding(theme, viewportWidth);
          return SingleChildScrollView(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: theme.layout.pageContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _QuickLinksHeader(),
                    SizedBox(
                      height: _quickLinksSectionGap(theme, viewportWidth),
                    ),
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: viewportWidth < theme.breakpoint.medium
                              ? double.infinity
                              : theme.layout.formContentWidth,
                        ),
                        child: SizedBox(
                          width: viewportWidth < theme.breakpoint.medium
                              ? double.infinity
                              : theme.layout.formContentWidth,
                          child: withStateSizeTransition(
                            YhCard(
                              child: loading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        YhRing.activity(
                                          size: theme.control.compact,
                                          label: '正在读取校园入口',
                                        ),
                                        SizedBox(width: theme.spacing.m),
                                        Flexible(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: theme.typography.h3,
                                              ),
                                              SizedBox(
                                                height: theme.spacing.xs,
                                              ),
                                              Text(
                                                message,
                                                style: theme.typography.small
                                                    .copyWith(
                                                      color: theme.color.muted,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : _QuickLinksStateMessage(
                                      icon: icon ?? YhIcons.link,
                                      title: title,
                                      message: message,
                                      action: action,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
