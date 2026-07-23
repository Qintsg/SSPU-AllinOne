/*
 * 邮箱收件箱组件 — 展示邮件列表与内联正文快照
 * @Project : SSPU-AllinOne
 * @File : email_mailbox_widgets.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

part of 'email_page.dart';

class _EmailMailboxListPanel extends StatelessWidget {
  const _EmailMailboxListPanel({
    required this.snapshot,
    required this.messages,
    required this.selectedMessageId,
    required this.refreshing,
    this.showHeader = true,
    this.showSenderAnchor = true,
    this.minHeight,
    required this.senderLabel,
    required this.formatDateTime,
    required this.onMessageFocused,
    required this.onMessagePressed,
  });

  final EmailMailboxSnapshot snapshot;
  final List<EmailMessageSnapshot> messages;
  final String? selectedMessageId;
  final bool refreshing;
  final bool showHeader;
  final bool showSenderAnchor;
  final double? minHeight;
  final String Function(EmailMessageSnapshot message) senderLabel;
  final String Function(DateTime? dateTime) formatDateTime;
  final ValueChanged<EmailMessageSnapshot> onMessageFocused;
  final ValueChanged<EmailMessageSnapshot> onMessagePressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-mailbox-list-pane'),
      padding: EdgeInsets.zero,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
            TraversalDirection.down,
          ),
          SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
            TraversalDirection.up,
          ),
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            theme.radius.l - theme.layout.divider,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight ?? 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader) ...[
                  Padding(
                    padding: EdgeInsets.all(theme.spacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text('收件箱', style: theme.typography.h3),
                            ),
                            if (refreshing)
                              const YhChip(label: '同步中', selected: true),
                          ],
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Wrap(
                          spacing: theme.spacing.s,
                          runSpacing: theme.spacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${snapshot.protocol.label} 最近邮件：${messages.length} 封',
                              style: theme.typography.caption.copyWith(
                                color: theme.color.muted,
                              ),
                            ),
                            Text(
                              '上次刷新：${formatDateTime(snapshot.fetchedAt)}',
                              style: theme.typography.caption.copyWith(
                                color: theme.color.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: theme.layout.divider,
                    color: theme.color.border,
                  ),
                ],
                if (messages.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(theme.spacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('暂无可展示邮件', style: theme.typography.h3),
                        SizedBox(height: theme.spacing.s),
                        const YhBanner(text: '邮箱协议登录成功，但最近邮件列表为空。'),
                      ],
                    ),
                  )
                else
                  for (var index = 0; index < messages.length; index++) ...[
                    Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onFocusChange: (focused) {
                        if (focused) onMessageFocused(messages[index]);
                      },
                      child: _EmailListRow(
                        message: messages[index],
                        selected: messages[index].id == selectedMessageId,
                        showSenderAnchor: showSenderAnchor,
                        senderLabel: senderLabel,
                        formatDateTime: formatDateTime,
                        onPressed: () => onMessagePressed(messages[index]),
                      ),
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
      ),
    );
  }
}

class _EmailListRow extends StatelessWidget {
  const _EmailListRow({
    required this.message,
    required this.selected,
    required this.showSenderAnchor,
    required this.senderLabel,
    required this.formatDateTime,
    required this.onPressed,
  });

  final EmailMessageSnapshot message;
  final bool selected;
  final bool showSenderAnchor;
  final String Function(EmailMessageSnapshot message) senderLabel;
  final String Function(DateTime? dateTime) formatDateTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: '打开邮件 ${message.subject}',
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onPressed: onPressed,
      builder: (context, state, child) {
        final background = selected
            ? theme.color.brandTint
            : state.hovered || state.focused
            ? theme.color.sunken
            : null;
        return ConstrainedBox(
          key: Key('email-message-${message.id}'),
          // Chromium 的 1.5 caption 行高落在半像素；Flutter 用半分隔线
          // 保持三行邮件文本和分隔线的冻结节奏。
          constraints: BoxConstraints(
            minHeight: theme.control.regular * 2 - theme.layout.divider / 2,
          ),
          child: Container(
            color: background,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.m,
              // Flutter 字形基线比浏览器低 1px，补偿后视觉内边距一致。
              vertical: theme.spacing.m - theme.layout.divider,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSenderAnchor) ...[
                  _EmailSenderAnchor(label: senderLabel(message)),
                  SizedBox(width: theme.spacing.s),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: theme.spacing.s),
                          Text(
                            formatDateTime(message.receivedAt),
                            style: theme.typography.caption.copyWith(
                              color: theme.color.muted,
                              height: theme.typography.body.height,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        senderLabel(message),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption.copyWith(
                          color: theme.color.muted,
                          height: theme.typography.body.height,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        message.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption.copyWith(
                          color: theme.color.muted,
                          height: theme.typography.body.height,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

class _EmailSenderAnchor extends StatelessWidget {
  const _EmailSenderAnchor({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final accent = theme.color.serviceMail;
    final initial = label.trim().isEmpty ? '邮' : label.trim().characters.first;
    return Container(
      width: theme.spacing.xl + theme.spacing.xs / 2,
      height: theme.spacing.xl + theme.spacing.xs / 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(theme.radius.s),
      ),
      child: Text(
        initial,
        style: theme.typography.body.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmailInlineDetailPanel extends StatelessWidget {
  const _EmailInlineDetailPanel({
    required this.message,
    required this.accountLabel,
    required this.protocolLabel,
    required this.fetchedAtLabel,
    required this.formatDateTime,
  });

  final EmailMessageSnapshot? message;
  final String accountLabel;
  final String protocolLabel;
  final String fetchedAtLabel;
  final String Function(DateTime? dateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final current = message;
    if (current == null) {
      return YhCard(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                theme.breakpoint.compact / 2 +
                theme.spacing.m +
                theme.spacing.xs,
          ),
          child: const Center(child: Text('选择一封邮件查看正文快照')),
        ),
      );
    }

    return Semantics(
      label: '$protocolLabel 只读快照，$fetchedAtLabel 同步',
      child: YhCard(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                theme.layout.popoverWidth + theme.spacing.xl2 + theme.spacing.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      current.senderName.isEmpty
                          ? current.senderAddress
                          : current.senderName,
                      style: theme.typography.caption.copyWith(
                        color: theme.color.muted,
                      ),
                    ),
                  ),
                  SizedBox(width: theme.spacing.m),
                  Text(
                    formatDateTime(current.receivedAt),
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: theme.spacing.s),
              Text(current.subject, style: theme.typography.h2),
              SizedBox(height: theme.spacing.s),
              Text(
                '发送至 $accountLabel',
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.m),
              Container(
                height: theme.layout.divider,
                color: theme.color.border,
              ),
              SizedBox(height: theme.spacing.m),
              YhSelectableText(
                current.body.isEmpty ? '无可展示正文。' : current.body,
                semanticLabel: '邮件正文快照',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
