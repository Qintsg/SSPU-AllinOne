/*
 * 资讯页面主视图、状态与来源导航
 * @Project : SSPU-AllinOne
 * @File : info_page_view.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

/* 清源信息中心展示层。 */

part of 'info_page.dart';

Widget _buildInfoPageView(_InfoPageState state, BuildContext context) {
  final theme = context.yhTheme;
  return YhPageScaffold(
    appBar: null,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoint.medium;
        final compactState =
            MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
        final statePanelWidth = compactState
            ? double.infinity
            : theme.layout.formContentWidth;
        final displayState = state._displayState;
        final pagePadding = _infoPagePadding(
          theme,
          MediaQuery.sizeOf(context).width,
        );
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleInfoPaginationKey(state, event),
          child: Padding(
            padding: pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      theme.layout.pageContentWidth - pagePadding.horizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoHeader(state: state, compact: compact),
                    SizedBox(height: theme.spacing.l),
                    if (displayState == InfoPageDisplayState.content ||
                        displayState == InfoPageDisplayState.stale)
                      Expanded(
                        child: _InfoContent(
                          state: state,
                          compact: compact,
                          stale: displayState == InfoPageDisplayState.stale,
                        ),
                      )
                    else
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: SizedBox(
                            width: statePanelWidth,
                            height:
                                theme.control.regular * (compactState ? 5 : 4),
                            child: _InfoStatePanel(
                              state: displayState,
                              onReadOrRetry: state._refreshSchoolWebsite,
                              onOpenSettings:
                                  state.widget.onOpenSourceSettings ?? () {},
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

EdgeInsets _infoPagePadding(YhTheme theme, double viewportWidth) {
  if (viewportWidth < theme.breakpoint.medium) {
    return EdgeInsets.fromLTRB(
      theme.spacing.m,
      theme.spacing.l + theme.spacing.s,
      theme.spacing.m,
      0,
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
