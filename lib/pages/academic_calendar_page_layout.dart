/*
 * 校历页面布局 — 响应式证据列、正文区与状态横幅
 * @Project : SSPU-AllinOne
 * @File : academic_calendar_page_layout.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'academic_calendar_page.dart';

extension _AcademicCalendarPageLayout on _AcademicCalendarPageState {
  Widget _buildCalendarPage(BuildContext context) {
    final selected = _selected;
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '校历',
        horizontalPadding: theme.spacing.s,
        actionSpacing: theme.spacing.s,
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          YhIconButton(
            icon: YhIcons.refresh,
            semanticLabel: _isRefreshing ? '正在刷新校历' : '刷新校历',
            onTap: _remoteOperationLocked ? null : _refreshAll,
          ),
          YhIconButton(
            icon: YhIcons.open,
            semanticLabel: '外部打开校历 PDF',
            onTap: selected == null || _remoteOperationLocked
                ? null
                : () => _openExternal(selected),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: theme.layout.pageContentWidth,
            ),
            child: SizedBox.expand(
              child: Padding(
                padding:
                    MediaQuery.sizeOf(context).width < theme.breakpoint.medium
                    ? EdgeInsets.symmetric(
                        horizontal: theme.spacing.m,
                        vertical: theme.spacing.s,
                      )
                    : EdgeInsets.all(theme.spacing.m),
                child: _buildBody(selected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AcademicCalendarCacheEntry? selected) {
    if (_isLoading && _entries.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.yhTheme.spacing.xl2 * 4,
          ),
          child: const YhProgressBar(value: 0.5, semanticLabel: '正在加载校历'),
        ),
      );
    }
    if (_entries.isEmpty) {
      final failed = _errorMessage != null;
      return YhEmptyState(
        icon: failed ? YhIcons.warning : YhIcons.calendar,
        title: failed ? '暂时无法读取公开校历' : '尚未找到可查看的校历',
        message: failed
            ? '本机没有有效档案，教务处公开页面也未完成读取；可在这里重试。'
            : '读取已完成，但 2021 年以后没有可用 PDF；可刷新公开来源。',
        action: YhButton(
          label: failed ? '重新读取公开校历' : '刷新公开校历',
          onTap: _isRefreshing ? null : _refreshAll,
          variant: YhButtonVariant.secondary,
        ),
      );
    }

    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading && _entries.isNotEmpty) ...[
          const YhBanner(text: '正在检查公开校历更新；当前学年和 PDF 已从本机恢复，完成前已锁定其它远端操作。'),
          SizedBox(height: theme.spacing.s),
        ] else if (_isRefreshing || _isOpeningExternal) ...[
          _calendarStatusBanner(
            YhBanner(
              text: _isRefreshing
                  ? '正在刷新公开校历；当前学年、PDF 和返回路径保持可用，完成前已锁定其它远端操作。'
                  : '正在交给外部应用；完成前已锁定重复操作，当前学年、PDF 和返回路径保持可用。',
              denseLeading: true,
            ),
          ),
          SizedBox(height: theme.spacing.s),
        ] else if (_externalError != null) ...[
          _calendarStatusBanner(
            YhBanner(
              text: _externalError!,
              kind: YhBannerKind.danger,
              leadingIcon: YhIcons.info,
              denseLeading: true,
            ),
          ),
          SizedBox(height: theme.spacing.s),
        ],
        if (_errorMessage != null) ...[
          _calendarStatusBanner(
            YhBanner(
              text: _errorMessage!,
              kind: selected?.isStale == true
                  ? YhBannerKind.warn
                  : YhBannerKind.danger,
              leadingIcon: YhIcons.info,
              denseLeading: true,
            ),
          ),
          SizedBox(height: theme.spacing.s),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CalendarSelector(
                      entries: _entries,
                      selected: selected,
                      compact: true,
                      enabled: !_remoteOperationLocked,
                      onSelected: _selectCalendarEntry,
                    ),
                    SizedBox(height: theme.spacing.s),
                    _CalendarTermCard(
                      contextSummary: _termContext,
                      selection:
                          _termContext?.effectiveQueryTerm ??
                          widget.termService.settings.selectedTerm ??
                          AcademicTermService.defaultTerm,
                      availableTerms: widget.termService.availableTerms,
                      loading: _isTermLoading || _isUpdatingTerm,
                      error: _termError,
                      enabled: !_remoteOperationLocked,
                      onChanged: _setQueryTerm,
                      onRetry: _retryTermContext,
                    ),
                    SizedBox(height: theme.spacing.s),
                    _CalendarEvidence(entry: selected, compact: true),
                    SizedBox(height: theme.spacing.s),
                    Expanded(child: _buildViewer(selected)),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: theme.spacing.xl2 * 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CalendarSourceCard(entry: selected),
                        SizedBox(height: theme.spacing.s),
                        _CalendarTermCard(
                          contextSummary: _termContext,
                          selection:
                              _termContext?.effectiveQueryTerm ??
                              widget.termService.settings.selectedTerm ??
                              AcademicTermService.defaultTerm,
                          availableTerms: widget.termService.availableTerms,
                          loading: _isTermLoading || _isUpdatingTerm,
                          error: _termError,
                          enabled: !_remoteOperationLocked,
                          onChanged: _setQueryTerm,
                          onRetry: _retryTermContext,
                        ),
                        SizedBox(height: theme.spacing.s),
                        _CalendarSelector(
                          entries: _entries,
                          selected: selected,
                          compact: false,
                          enabled: !_remoteOperationLocked,
                          onSelected: _selectCalendarEntry,
                        ),
                        SizedBox(height: theme.spacing.s),
                        _CalendarEvidence(entry: selected, compact: false),
                      ],
                    ),
                  ),
                  SizedBox(width: theme.spacing.m),
                  Expanded(child: _buildViewer(selected)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewer(AcademicCalendarCacheEntry? selected) {
    final document =
        widget.viewerBuilder?.call(context, selected) ??
        _CalendarPdfViewer(
          entry: selected,
          onOpenExternal: selected == null || _remoteOperationLocked
              ? null
              : () => _openExternal(selected),
        );
    return _CalendarDocumentPanel(
      entry: selected,
      onFocus: selected == null || _remoteOperationLocked
          ? null
          : () => Navigator.of(context).push(
              YhPageRoute<void>(
                builder: (_) => AcademicCalendarPdfPage(
                  title: selected.title,
                  pdfFilePath: selected.pdfFilePath,
                  pdfUrl: selected.pdfUrl,
                ),
              ),
            ),
      child: document,
    );
  }

  Widget _calendarStatusBanner(Widget banner) {
    final theme = context.yhTheme;
    if (MediaQuery.sizeOf(context).width >= theme.breakpoint.medium) {
      return banner;
    }
    return SizedBox(
      height: theme.control.touch + theme.spacing.s + theme.spacing.xs,
      child: ClipRect(child: banner),
    );
  }
}
