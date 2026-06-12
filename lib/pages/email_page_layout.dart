/*
 * 学校邮箱页面布局 — 组织三栏邮件客户端与窄屏单栏布局
 * @Project : SSPU-AllinOne
 * @File : email_page_layout.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'email_page.dart';

extension _EmailPageLayout on _EmailPageState {
  Widget _buildEmailContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopClient = constraints.maxWidth >= 1040;
        if (useDesktopClient) {
          return _buildDesktopMailClient(context);
        }

        return Column(
          children: [
            _animateEmailSection(_buildCompactToolbar(context), 0),
            if (_showComposePane) ...[
              const SizedBox(height: FluentSpacing.m),
              _animateEmailSection(_buildComposeCard(context), 1),
            ],
            const SizedBox(height: FluentSpacing.m),
            _animateEmailSection(
              _buildMailboxSection(context, inlineDetail: false),
              _showComposePane ? 2 : 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopMailClient(BuildContext context) {
    return Row(
      key: const Key('email-desktop-client-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 260, child: _buildMailboxSidebar(context)),
        const SizedBox(width: FluentSpacing.m),
        SizedBox(width: 380, child: _buildMailboxListPane(context)),
        const SizedBox(width: FluentSpacing.m),
        Expanded(child: _buildReadingPane(context)),
      ],
    );
  }

  Widget _animateEmailSection(Widget child, int index) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate(delay: FluentDuration.stagger * index)
        .fadeIn(duration: FluentDuration.slow, curve: FluentEasing.decelerate)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildMailboxSidebar(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentSurface(
      key: const Key('email-sidebar'),
      minHeight: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FluentSectionHeader(
            title: 'SSPU 邮箱',
            subtitle: '收信、阅读和 SMTP 发信',
            icon: FluentIcons.mail,
          ),
          const SizedBox(height: FluentSpacing.l),
          SizedBox(
            width: double.infinity,
            child: FluentButton.primary(
              onPressed: _showComposePane ? null : _startCompose,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.edit, size: 14),
                  SizedBox(width: FluentSpacing.xs),
                  Text('写邮件'),
                ],
              ),
            ),
          ),
          const SizedBox(height: FluentSpacing.xl),
          Text('收件箱', style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.s),
          _buildProtocolSelector(context),
          const SizedBox(height: FluentSpacing.s),
          SizedBox(
            width: double.infinity,
            child: FluentButton.outline(
              onPressed: _isFetchingMessages ? null : _fetchMessages,
              child: _buildButtonContent(
                loading: _isFetchingMessages,
                icon: FluentIcons.refresh,
                label: '读取最近邮件',
              ),
            ),
          ),
          const SizedBox(height: FluentSpacing.m),
          Text(
            'IMAP / POP 仅读取最近邮件；SMTP 只在点击发送时提交文本邮件，不会自动发信、删除、移动或标记已读。',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: FluentSpacing.xl),
          Text('协议校验', style: theme.typography.bodyStrong),
          const SizedBox(height: FluentSpacing.s),
          ..._buildValidationButtons(context),
          if (_validationResult != null) ...[
            const SizedBox(height: FluentSpacing.m),
            FluentInfoBar(
              title: Text(_validationResult!.message),
              content: Text(_validationResult!.detail),
              severity: _severityOf(_validationResult!.status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactToolbar(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentSurface(
      key: const Key('email-compact-toolbar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FluentSectionHeader(
            title: 'SSPU 邮箱',
            subtitle: 'IMAP / POP 收信，SMTP 主动发信',
            icon: FluentIcons.mail,
          ),
          const SizedBox(height: FluentSpacing.m),
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FluentButton.primary(
                onPressed: _showComposePane ? null : _startCompose,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.edit, size: 14),
                    SizedBox(width: FluentSpacing.xs),
                    Text('写邮件'),
                  ],
                ),
              ),
              SizedBox(width: 160, child: _buildProtocolSelector(context)),
              FluentButton.outline(
                onPressed: _isFetchingMessages ? null : _fetchMessages,
                child: _buildButtonContent(
                  loading: _isFetchingMessages,
                  icon: FluentIcons.refresh,
                  label: '读取最近邮件',
                ),
              ),
              ..._buildValidationButtons(context, compact: true),
            ],
          ),
          const SizedBox(height: FluentSpacing.s),
          Text(
            'SMTP 只在点击发送时提交文本邮件；不会自动发信、删除、移动或标记已读。',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          if (_validationResult != null) ...[
            const SizedBox(height: FluentSpacing.m),
            FluentInfoBar(
              title: Text(_validationResult!.message),
              content: Text(_validationResult!.detail),
              severity: _severityOf(_validationResult!.status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposeCard(BuildContext context) {
    return EmailComposePanel(
      toController: _toController,
      ccController: _ccController,
      bccController: _bccController,
      subjectController: _subjectController,
      bodyController: _bodyController,
      isSending: _isSendingMessage,
      result: _sendResult,
      severityOf: _severityOf,
      onSend: _sendEmail,
      onCancel: _closeCompose,
    );
  }

  Widget _buildProtocolSelector(BuildContext context) {
    return FluentSelect<EmailProtocol>(
      value: _selectedProtocol,
      items: const [
        FluentSelectItem(value: EmailProtocol.imap, child: Text('IMAP 收信')),
        FluentSelectItem(value: EmailProtocol.pop, child: Text('POP 收信')),
      ],
      onChanged: _isFetchingMessages
          ? null
          : (protocol) {
              if (protocol == null) return;
              _selectProtocol(protocol);
              unawaited(_loadCachedMessagesForSelectedProtocol());
            },
    );
  }

  List<Widget> _buildValidationButtons(
    BuildContext context, {
    bool compact = false,
  }) {
    return EmailProtocol.values
        .map(
          (protocol) => FluentButton.outline(
            onPressed: _validatingProtocol == null && !_isFetchingMessages
                ? () => _validateLogin(protocol)
                : null,
            child: _buildButtonContent(
              loading: _validatingProtocol == protocol,
              icon: FluentIcons.plugConnected,
              label: '校验 ${protocol.label}',
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildButtonContent({
    required bool loading,
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: FluentProgressRing(strokeWidth: 2),
          ),
        ] else ...[
          Icon(icon, size: 14),
        ],
        const SizedBox(width: FluentSpacing.xs),
        Text(label),
      ],
    );
  }

  /// 构建邮件读取结果和列表。
  Widget _buildMailboxSection(
    BuildContext context, {
    required bool inlineDetail,
  }) {
    final result = _mailboxResult;
    if (result == null && _isFetchingMessages) {
      return const FluentSurface(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: FluentProgressRing(strokeWidth: 2),
            ),
            SizedBox(width: FluentSpacing.s),
            Text('正在读取最近邮件...'),
          ],
        ),
      );
    }

    if (result == null) {
      return FluentInfoBar(
        title: const Text('尚未读取邮箱'),
        content: Text(
          _emailAutoRefreshEnabled
              ? '邮箱自动刷新已开启，等待下一次读取；也可点击“读取最近邮件”立即刷新。'
              : '选择 IMAP 或 POP 后点击“读取最近邮件”，也可以先校验各协议登录状态。',
        ),
        severity: FluentInfoSeverity.info,
      );
    }

    if (!result.isSuccess || result.snapshot == null) {
      return FluentInfoBar(
        title: Text(result.message),
        content: Text(result.detail),
        severity: _severityOf(result.status),
      );
    }

    final snapshot = result.snapshot!;
    final messages = snapshot.messages;
    _selectFirstMessageIfNeeded(messages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentSurface(
          padding: const EdgeInsets.all(FluentSpacing.l),
          child: Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${snapshot.protocol.label} 最近邮件：${messages.length} 封'),
              Text('上次刷新：${_formatDateTime(snapshot.fetchedAt)}'),
              if (_isFetchingMessages)
                const FluentStatusChip(
                  label: '同步中',
                  icon: FluentIcons.refresh,
                  tone: FluentStatusChipTone.brand,
                ),
            ],
          ),
        ),
        const SizedBox(height: FluentSpacing.m),
        if (messages.isEmpty)
          const FluentInfoBar(
            title: Text('暂无可展示邮件'),
            content: Text('邮箱协议登录成功，但最近邮件列表为空。'),
            severity: FluentInfoSeverity.info,
          )
        else if (inlineDetail)
          _buildMailboxTwoPane(context, snapshot, messages)
        else
          ...messages.map(
            (message) => _buildMessageCard(message, inlineDetail: false),
          ),
      ],
    );
  }

  Widget _buildMailboxListPane(BuildContext context) {
    final result = _mailboxResult;
    if (result == null && _isFetchingMessages) {
      return const FluentSurface(
        key: Key('email-list-pane-loading'),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: FluentProgressRing(strokeWidth: 2),
            ),
            SizedBox(width: FluentSpacing.s),
            Text('正在读取最近邮件...'),
          ],
        ),
      );
    }

    if (result == null) {
      return FluentSurface(
        key: const Key('email-list-pane-empty'),
        minHeight: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FluentSectionHeader(
              title: '收件箱',
              subtitle: '尚未读取邮箱',
              icon: FluentIcons.inbox,
            ),
            const SizedBox(height: FluentSpacing.m),
            Text(
              _emailAutoRefreshEnabled
                  ? '邮箱自动刷新已开启，等待下一次读取；也可点击“读取最近邮件”立即刷新。'
                  : '选择协议后读取最近邮件，列表会显示在这里。',
            ),
          ],
        ),
      );
    }

    if (!result.isSuccess || result.snapshot == null) {
      return FluentSurface(
        minHeight: 520,
        child: FluentInfoBar(
          title: Text(result.message),
          content: Text(result.detail),
          severity: _severityOf(result.status),
        ),
      );
    }

    final snapshot = result.snapshot!;
    final messages = snapshot.messages;
    _selectFirstMessageIfNeeded(messages);
    return _EmailMailboxListPanel(
      snapshot: snapshot,
      messages: messages,
      selectedMessageId: _selectedMessageId,
      refreshing: _isFetchingMessages,
      senderLabel: _senderLabel,
      formatDateTime: _formatOptionalDateTime,
      onMessagePressed: (message) =>
          _openOrSelectMessage(message, inline: true),
    );
  }

  Widget _buildReadingPane(BuildContext context) {
    if (_showComposePane) {
      return _buildComposeCard(context);
    }

    final snapshot = _mailboxResult?.snapshot;
    final selectedMessage = snapshot == null
        ? null
        : _selectedMessage(snapshot.messages);
    if (snapshot == null || selectedMessage == null) {
      return const _EmailReadingPlaceholder();
    }

    return _EmailInlineDetailPanel(
      message: selectedMessage,
      protocolLabel: snapshot.protocol.label,
      fetchedAtLabel: _formatDateTime(snapshot.fetchedAt),
      senderLabel: _senderLabel,
      formatDateTime: _formatOptionalDateTime,
    );
  }

  Widget _buildMailboxTwoPane(
    BuildContext context,
    EmailMailboxSnapshot snapshot,
    List<EmailMessageSnapshot> messages,
  ) {
    final selectedMessage = _selectedMessage(messages);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 360,
          child: FluentSurface(
            padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xxs),
            child: Column(
              children: [
                for (var index = 0; index < messages.length; index++) ...[
                  _EmailListRow(
                    message: messages[index],
                    selected: messages[index].id == selectedMessage?.id,
                    senderLabel: _senderLabel,
                    formatDateTime: _formatOptionalDateTime,
                    onPressed: () =>
                        _openOrSelectMessage(messages[index], inline: true),
                  ),
                  if (index != messages.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: FluentSpacing.m),
        Expanded(
          child: _EmailInlineDetailPanel(
            message: selectedMessage,
            protocolLabel: snapshot.protocol.label,
            fetchedAtLabel: _formatDateTime(snapshot.fetchedAt),
            senderLabel: _senderLabel,
            formatDateTime: _formatOptionalDateTime,
          ),
        ),
      ],
    );
  }

  /// 构建单封邮件摘要卡片。
  Widget _buildMessageCard(
    EmailMessageSnapshot message, {
    required bool inlineDetail,
  }) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: FluentSpacing.s),
      child: FluentSurface(
        padding: const EdgeInsets.all(FluentSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.subject,
                    style: theme.typography.bodyStrong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: FluentSpacing.s),
                Text(_formatOptionalDateTime(message.receivedAt)),
              ],
            ),
            const SizedBox(height: FluentSpacing.xs),
            Text(
              _senderLabel(message),
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: FluentSpacing.s),
            Text(message.preview, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: FluentSpacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: FluentButton.outline(
                onPressed: () =>
                    _openOrSelectMessage(message, inline: inlineDetail),
                child: const Text('查看正文'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
