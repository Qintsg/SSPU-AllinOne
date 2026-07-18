/*
 * 学校邮箱页面布局 — 清源收件箱、阅读窗格与连接设置
 * @Project : SSPU-AllinOne
 * @File : email_page_layout.dart
 * @Author : Qintsg
 * @Date : 2026-07-19
 */

part of 'email_page.dart';

extension _EmailPageLayout on _EmailPageState {
  Widget _buildEmailContent(BuildContext context) {
    final theme = context.yhTheme;
    if (_showComposePane) {
      return Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
          child: _buildComposeCard(context),
        ),
      );
    }

    final result = _mailboxResult;
    if (result == null && _isFetchingMessages) {
      return _buildMailboxStateCard(
        context,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: theme.spacing.xl2 * 2,
              child: const YhProgress(showPercent: false),
            ),
            SizedBox(width: theme.spacing.m),
            const Flexible(child: Text('正在读取最近邮件')),
          ],
        ),
      );
    }
    if (result == null) {
      return _buildMailboxStateCard(
        context,
        child: YhEmptyState(
          icon: YhIcons.mail,
          title: '尚未读取邮箱',
          message: '连接学校邮箱后读取最近邮件，正文只保存在本机。',
          action: Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            alignment: WrapAlignment.center,
            children: [
              YhButton(
                label: '读取最近邮件',
                onTap: _isFetchingMessages ? null : _fetchMessages,
              ),
              YhButton(
                label: '邮箱连接设置',
                variant: YhButtonVariant.secondary,
                onTap: () => _openConnectionDrawer(context),
              ),
            ],
          ),
        ),
      );
    }
    if (!result.isSuccess || result.snapshot == null) {
      return _buildMailboxStateCard(
        context,
        child: YhEmptyState(
          icon: YhIcons.info,
          title: result.message,
          message: result.detail,
          action: Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            alignment: WrapAlignment.center,
            children: [
              YhButton(label: '重试', onTap: _fetchMessages),
              YhButton(
                label: '邮箱连接设置',
                variant: YhButtonVariant.secondary,
                onTap: () => _openConnectionDrawer(context),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = result.snapshot!;
    final messages = snapshot.messages;
    _selectFirstMessageIfNeeded(messages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: theme.spacing.s,
          runSpacing: theme.spacing.s,
          children: [
            YhStatusPill(
              label: '${snapshot.protocol.label} 已连接',
              kind: YhStatusKind.success,
            ),
            YhStatusPill(
              label: '${messages.length} 封邮件',
              kind: YhStatusKind.info,
            ),
            YhStatusPill(
              label: '${_formatClockTime(snapshot.fetchedAt)} 同步',
              kind: YhStatusKind.neutral,
            ),
          ],
        ),
        if (_isMailboxSnapshotStale(snapshot)) ...[
          SizedBox(height: theme.spacing.m),
          YhBanner(
            text:
                '当前显示 ${_formatClockTime(snapshot.fetchedAt)} 的本地邮件缓存；'
                '网络恢复后可手动刷新。',
            kind: YhBannerKind.warn,
          ),
        ],
        SizedBox(height: theme.spacing.m),
        if (messages.isEmpty)
          _buildMailboxStateCard(
            context,
            child: YhEmptyState(
              icon: YhIcons.mail,
              title: '收件箱暂无邮件',
              message: '连接正常，但当前查询范围没有可展示的邮件。',
              action: YhButton(
                label: '重新读取',
                variant: YhButtonVariant.secondary,
                onTap: _fetchMessages,
              ),
            ),
          )
        else if (MediaQuery.sizeOf(context).width >= theme.breakpoint.expanded)
          _buildDesktopMailClient(context)
        else
          _EmailMailboxListPanel(
            snapshot: snapshot,
            messages: messages,
            selectedMessageId: _selectedMessageId,
            refreshing: _isFetchingMessages,
            showHeader: false,
            showSenderAnchor: false,
            senderLabel: _senderDisplayName,
            formatDateTime: _formatOptionalDateTime,
            onMessagePressed: (message) =>
                _openOrSelectMessage(message, inline: false),
          ),
      ],
    );
  }

  Widget _buildDesktopMailClient(BuildContext context) {
    final theme = context.yhTheme;
    final snapshot = _mailboxResult!.snapshot!;
    final messages = snapshot.messages;
    return Row(
      key: const Key('email-desktop-client-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: theme.breakpoint.compact / 2 - theme.spacing.m,
          child: _EmailMailboxListPanel(
            snapshot: snapshot,
            messages: messages,
            selectedMessageId: _selectedMessageId,
            refreshing: _isFetchingMessages,
            showHeader: false,
            showSenderAnchor: false,
            minHeight: theme.layout.popoverWidth + theme.spacing.xl2 * 2,
            senderLabel: _senderDisplayName,
            formatDateTime: _formatOptionalDateTime,
            onMessagePressed: (message) =>
                _openOrSelectMessage(message, inline: true),
          ),
        ),
        SizedBox(width: theme.spacing.m),
        Expanded(
          child: _EmailInlineDetailPanel(
            message: _selectedMessage(messages),
            accountLabel: snapshot.account,
            protocolLabel: snapshot.protocol.label,
            fetchedAtLabel: _formatDateTime(snapshot.fetchedAt),
            formatDateTime: _formatOptionalDateTime,
          ),
        ),
      ],
    );
  }

  Widget _buildMailboxStateCard(BuildContext context, {required Widget child}) {
    final theme = context.yhTheme;
    return YhCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: theme.layout.popoverWidth + theme.spacing.xl,
        ),
        child: Center(child: child),
      ),
    );
  }

  Future<void> _openConnectionDrawer(BuildContext context) {
    final theme = context.yhTheme;
    return YhBottomDrawer.show<void>(
      context,
      title: '邮箱连接与协议',
      builder: (drawerContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProtocolSelector(context),
          SizedBox(height: theme.spacing.m),
          YhButton(
            label: _isFetchingMessages ? '读取中' : '读取最近邮件',
            leadingIcon: _isFetchingMessages ? null : YhIcons.refresh,
            onTap: _isFetchingMessages
                ? null
                : () {
                    Navigator.of(drawerContext).pop();
                    _fetchMessages();
                  },
          ),
          SizedBox(height: theme.spacing.m),
          Text('协议校验', style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: _buildValidationButtons(context),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            'IMAP / POP 仅读取最近邮件；SMTP 只在点击发送时提交普通文本。',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
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
    return YhSelect<EmailProtocol>(
      label: '收信协议',
      value: _selectedProtocol,
      options: const [
        YhSelectOption(value: EmailProtocol.imap, label: 'IMAP 收信'),
        YhSelectOption(value: EmailProtocol.pop, label: 'POP 收信'),
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

  List<Widget> _buildValidationButtons(BuildContext context) {
    return EmailProtocol.values
        .map(
          (protocol) => YhButton(
            label: _validatingProtocol == protocol
                ? '校验中'
                : '校验 ${protocol.label}',
            leadingIcon: _validatingProtocol == protocol
                ? null
                : YhIcons.connect,
            variant: YhButtonVariant.secondary,
            onTap: _validatingProtocol == null && !_isFetchingMessages
                ? () => _validateLogin(protocol)
                : null,
          ),
        )
        .toList(growable: false);
  }
}
