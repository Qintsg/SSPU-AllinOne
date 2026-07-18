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
    final theme = context.yhTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopClient =
            constraints.maxWidth >=
            theme.breakpoint.expanded -
                theme.breakpoint.compact / 4 -
                theme.spacing.s -
                theme.spacing.xs / 2;
        if (useDesktopClient) {
          return _buildDesktopMailClient(context);
        }

        return Column(
          children: [
            _animateEmailSection(_buildCompactToolbar(context), 0),
            if (_showComposePane) ...[
              SizedBox(height: theme.spacing.m),
              _animateEmailSection(_buildComposeCard(context), 1),
            ],
            SizedBox(height: theme.spacing.m),
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
    final theme = context.yhTheme;
    return Row(
      key: const Key('email-desktop-client-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width:
              theme.breakpoint.compact / 2 - theme.spacing.xl - theme.spacing.s,
          child: _buildMailboxSidebar(context),
        ),
        SizedBox(width: theme.spacing.m),
        SizedBox(
          width:
              theme.breakpoint.compact -
              (theme.breakpoint.compact / 3 +
                  theme.spacing.m +
                  theme.spacing.xs),
          child: _buildMailboxListPane(context),
        ),
        SizedBox(width: theme.spacing.m),
        Expanded(child: _buildReadingPane(context)),
      ],
    );
  }

  Widget _animateEmailSection(Widget child, int index) {
    return child;
  }

  Widget _buildMailboxSidebar(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-sidebar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EmailSectionHeading(
            title: 'SSPU 邮箱',
            subtitle: '收信、阅读和 SMTP 发信',
            icon: YhIcons.mail,
          ),
          SizedBox(height: theme.spacing.l),
          SizedBox(
            width: double.infinity,
            child: YhButton(
              label: '写邮件',
              leadingIcon: YhIcons.edit,
              onTap: _showComposePane ? null : _startCompose,
            ),
          ),
          SizedBox(height: theme.spacing.xl),
          Text('收件箱', style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          _buildProtocolSelector(context),
          SizedBox(height: theme.spacing.s),
          SizedBox(
            width: double.infinity,
            child: YhButton(
              label: _isFetchingMessages ? '读取中' : '读取最近邮件',
              leadingIcon: _isFetchingMessages ? null : YhIcons.refresh,
              variant: YhButtonVariant.secondary,
              onTap: _isFetchingMessages ? null : _fetchMessages,
            ),
          ),
          SizedBox(height: theme.spacing.m),
          Text(
            'IMAP / POP 仅读取最近邮件；SMTP 只在点击发送时提交文本邮件，不会自动发信、删除、移动或标记已读。',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.xl),
          Text('协议校验', style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          ..._buildValidationButtons(context),
          if (_validationResult != null) ...[
            SizedBox(height: theme.spacing.m),
            Text(_validationResult!.message, style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(
              text: _validationResult!.detail,
              kind: _severityOf(_validationResult!.status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactToolbar(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-compact-toolbar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EmailSectionHeading(
            title: 'SSPU 邮箱',
            subtitle: 'IMAP / POP 收信，SMTP 主动发信',
            icon: YhIcons.mail,
          ),
          SizedBox(height: theme.spacing.m),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              YhButton(
                label: '写邮件',
                leadingIcon: YhIcons.edit,
                onTap: _showComposePane ? null : _startCompose,
              ),
              SizedBox(
                width:
                    theme.breakpoint.compact / 4 +
                    theme.spacing.s +
                    theme.spacing.xs / 2,
                child: _buildProtocolSelector(context),
              ),
              YhButton(
                label: _isFetchingMessages ? '读取中' : '读取最近邮件',
                leadingIcon: _isFetchingMessages ? null : YhIcons.refresh,
                variant: YhButtonVariant.secondary,
                onTap: _isFetchingMessages ? null : _fetchMessages,
              ),
              ..._buildValidationButtons(context, compact: true),
            ],
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            'SMTP 只在点击发送时提交文本邮件；不会自动发信、删除、移动或标记已读。',
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          if (_validationResult != null) ...[
            SizedBox(height: theme.spacing.m),
            Text(_validationResult!.message, style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(
              text: _validationResult!.detail,
              kind: _severityOf(_validationResult!.status),
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
    return YhSelect<EmailProtocol>(
      label: '收信协议',
      showLabel: false,
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

  List<Widget> _buildValidationButtons(
    BuildContext context, {
    bool compact = false,
  }) {
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

  /// 构建邮件读取结果和列表。
  Widget _buildMailboxSection(
    BuildContext context, {
    required bool inlineDetail,
  }) {
    final theme = context.yhTheme;
    final result = _mailboxResult;
    if (result == null && _isFetchingMessages) {
      return YhCard(
        child: Row(
          children: [
            SizedBox(
              width: theme.spacing.xl2 * 2,
              child: const YhProgress(showPercent: false),
            ),
            SizedBox(width: theme.spacing.s),
            const Text('正在读取最近邮件...'),
          ],
        ),
      );
    }

    if (result == null) {
      return YhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('尚未读取邮箱', style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(
              text: _emailAutoRefreshEnabled
                  ? '邮箱自动刷新已开启，等待下一次读取；也可点击“读取最近邮件”立即刷新。'
                  : '选择 IMAP 或 POP 后点击“读取最近邮件”，也可以先校验各协议登录状态。',
            ),
          ],
        ),
      );
    }

    if (!result.isSuccess || result.snapshot == null) {
      return YhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(text: result.detail, kind: _severityOf(result.status)),
          ],
        ),
      );
    }

    final snapshot = result.snapshot!;
    final messages = snapshot.messages;
    _selectFirstMessageIfNeeded(messages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YhCard(
          child: Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${snapshot.protocol.label} 最近邮件：${messages.length} 封'),
              Text('上次刷新：${_formatDateTime(snapshot.fetchedAt)}'),
              if (_isFetchingMessages)
                const YhChip(label: '同步中', selected: true),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.m),
        if (messages.isEmpty)
          YhCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('暂无可展示邮件', style: theme.typography.h3),
                SizedBox(height: theme.spacing.s),
                const YhBanner(text: '邮箱协议登录成功，但最近邮件列表为空。'),
              ],
            ),
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
    final theme = context.yhTheme;
    final result = _mailboxResult;
    if (result == null && _isFetchingMessages) {
      return YhCard(
        key: Key('email-list-pane-loading'),
        child: Row(
          children: [
            SizedBox(
              width: theme.spacing.xl2 * 2,
              child: const YhProgress(showPercent: false),
            ),
            SizedBox(width: theme.spacing.s),
            const Text('正在读取最近邮件...'),
          ],
        ),
      );
    }

    if (result == null) {
      return YhCard(
        key: const Key('email-list-pane-empty'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EmailSectionHeading(
              title: '收件箱',
              subtitle: '尚未读取邮箱',
              icon: YhIcons.inbox,
            ),
            SizedBox(height: theme.spacing.m),
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
      return YhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: theme.typography.h3),
            SizedBox(height: theme.spacing.s),
            YhBanner(text: result.detail, kind: _severityOf(result.status)),
          ],
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
    final theme = context.yhTheme;
    final selectedMessage = _selectedMessage(messages);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width:
              theme.breakpoint.compact -
              theme.breakpoint.compact / 3 -
              theme.spacing.xl -
              theme.spacing.s,
          child: YhCard(
            padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
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
                  if (index != messages.length - 1)
                    Container(
                      height: theme.layout.divider,
                      color: theme.color.border,
                    ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: theme.spacing.m),
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
    final theme = context.yhTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.s),
      child: YhCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.subject,
                    style: theme.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: theme.spacing.s),
                Text(_formatOptionalDateTime(message.receivedAt)),
              ],
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              _senderLabel(message),
              style: theme.typography.caption.copyWith(
                color: theme.color.muted,
              ),
            ),
            SizedBox(height: theme.spacing.s),
            Text(message.preview, maxLines: 3, overflow: TextOverflow.ellipsis),
            SizedBox(height: theme.spacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: YhButton(
                label: '查看正文',
                variant: YhButtonVariant.secondary,
                onTap: () =>
                    _openOrSelectMessage(message, inline: inlineDetail),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSectionHeading extends StatelessWidget {
  const _EmailSectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: theme.control.compact,
          child: Icon(icon, color: theme.color.serviceMail),
        ),
        SizedBox(width: theme.spacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.typography.h3),
              SizedBox(height: theme.spacing.xs),
              Text(
                subtitle,
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
