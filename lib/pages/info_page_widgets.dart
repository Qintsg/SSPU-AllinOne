part of 'info_page.dart';

Widget _buildInfoPageView(_InfoPageState state, BuildContext context) {
  final theme = FluentTheme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return ResponsiveBuilder(
    builder: (context, deviceType, constraints) {
      if (deviceType == DeviceType.phone) {
        return FluentPage(
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.s),
            child: _buildInfoMobileBody(state, theme, isDark),
          ),
        );
      }

      return FluentPage(
        header: FluentPageHeader(
          title: const Text('信息中心'),
          commandBar: _buildInfoHeaderActions(state, theme),
        ),
        content: Padding(
          padding: responsivePagePadding(deviceType),
          child: _buildInfoRegularBody(state, theme, isDark),
        ),
      );
    },
  );
}

Widget _buildInfoRegularBody(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  return FluentContentWidth(
    child: Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleInfoPaginationKey(state, event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRegularControls(state, theme, isDark),
          const SizedBox(height: FluentSpacing.s),
          Expanded(child: _buildInfoMessagePanel(state, theme, isDark)),
          if (state._filteredMessages.isNotEmpty) ...[
            const SizedBox(height: FluentSpacing.xxs),
            state._buildPagination(theme),
          ],
        ],
      ),
    ),
  );
}

Widget _buildInfoMobileBody(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildInfoMobileControls(state, theme),
      const SizedBox(height: FluentSpacing.xxs),
      Expanded(child: _buildInfoMessagePanel(state, theme, isDark)),
      if (state._filteredMessages.isNotEmpty) ...[
        const SizedBox(height: FluentSpacing.xxs),
        _buildInfoMobilePagination(state, theme),
      ],
    ],
  );
}

KeyEventResult _handleInfoPaginationKey(_InfoPageState state, KeyEvent event) {
  if (event is! KeyDownEvent || state._filteredMessages.isEmpty) {
    return KeyEventResult.ignored;
  }
  if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
      state._currentPage > 0) {
    state._setCurrentPage(state._currentPage - 1);
    return KeyEventResult.handled;
  }
  if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
      state._currentPage < state._totalPages - 1) {
    state._setCurrentPage(state._currentPage + 1);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

Widget _buildInfoMessagePanel(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final refreshSnapshot = state._refreshService.snapshot;
  if (refreshSnapshot.isRefreshing && state._filteredMessages.isEmpty) {
    return const Center(child: FluentProgressRing());
  }

  if (state._filteredMessages.isEmpty) {
    return FluentSurface(
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.inbox,
              size: 48,
              color: theme.resources.textFillColorSecondary,
            ),
            const SizedBox(height: FluentSpacing.m),
            Text(
              '暂无消息',
              style: theme.typography.body?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: FluentSpacing.s),
            Text(
              '点击上方刷新按钮获取最新消息',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return state._buildMessageList(theme, isDark);
}

Widget _buildInfoMessageList(
  _InfoPageState state,
  FluentThemeData theme,
  bool isDark,
) {
  final messages = state._pagedMessages;

  return FluentSurface(
    key: const Key('info-message-list'),
    padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xxs),
    child: ListView.separated(
      controller: state._messageListController,
      primary: false,
      itemCount: messages.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isRead = state._stateService.isRead(message.id);

        return MessageTile(
          message: message,
          isRead: isRead,
          isDark: isDark,
          onTap: () => state._openMessage(message),
          onMarkRead: () async {
            await state._stateService.markAsRead(message.id);
            state._refreshView();
          },
        );
      },
    ),
  );
}
