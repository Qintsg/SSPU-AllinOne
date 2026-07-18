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
    required this.senderLabel,
    required this.formatDateTime,
    required this.onMessagePressed,
  });

  final EmailMailboxSnapshot snapshot;
  final List<EmailMessageSnapshot> messages;
  final String? selectedMessageId;
  final bool refreshing;
  final String Function(EmailMessageSnapshot message) senderLabel;
  final String Function(DateTime? dateTime) formatDateTime;
  final ValueChanged<EmailMessageSnapshot> onMessagePressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-mailbox-list-pane'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('收件箱', style: theme.typography.h3)),
                    if (refreshing) const YhChip(label: '同步中', selected: true),
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
          Container(height: 1, color: theme.color.border),
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
              _EmailListRow(
                message: messages[index],
                selected: messages[index].id == selectedMessageId,
                senderLabel: senderLabel,
                formatDateTime: formatDateTime,
                onPressed: () => onMessagePressed(messages[index]),
              ),
              if (index != messages.length - 1)
                Container(height: 1, color: theme.color.border),
            ],
        ],
      ),
    );
  }
}

class _EmailListRow extends StatelessWidget {
  const _EmailListRow({
    required this.message,
    required this.selected,
    required this.senderLabel,
    required this.formatDateTime,
    required this.onPressed,
  });

  final EmailMessageSnapshot message;
  final bool selected;
  final String Function(EmailMessageSnapshot message) senderLabel;
  final String Function(DateTime? dateTime) formatDateTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: '打开邮件 ${message.subject}',
      onPressed: onPressed,
      builder: (context, state, child) {
        final background = selected
            ? theme.color.brandTint
            : state.hovered || state.focused
            ? theme.color.sunken
            : null;
        return Container(
          color: background,
          padding: EdgeInsets.all(theme.spacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmailSenderAnchor(label: senderLabel(message)),
              SizedBox(width: theme.spacing.s),
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
                      ),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      message.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption,
                    ),
                  ],
                ),
              ),
            ],
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

class _EmailReadingPlaceholder extends StatelessWidget {
  const _EmailReadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('email-reading-placeholder'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EmailSectionHeading(
            title: '阅读窗格',
            subtitle: '选择一封邮件查看正文快照，或点击写邮件打开撰写面板',
            icon: YhIcons.mail,
          ),
          SizedBox(height: theme.spacing.xl),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    theme.breakpoint.compact -
                    theme.breakpoint.compact / 3 -
                    theme.spacing.xl -
                    theme.spacing.s,
              ),
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: theme.spacing.xl2 + theme.spacing.s,
                    child: Icon(YhIcons.mail, color: theme.color.serviceMail),
                  ),
                  SizedBox(height: theme.spacing.m),
                  Text('保持只读收件箱', style: theme.typography.h3),
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    '这里展示最近读取到的邮件正文快照。当前不会执行回复、转发、删除、移动或标记已读操作。',
                    textAlign: TextAlign.center,
                    style: theme.typography.caption.copyWith(
                      color: theme.color.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailInlineDetailPanel extends StatelessWidget {
  const _EmailInlineDetailPanel({
    required this.message,
    required this.protocolLabel,
    required this.fetchedAtLabel,
    required this.senderLabel,
    required this.formatDateTime,
  });

  final EmailMessageSnapshot? message;
  final String protocolLabel;
  final String fetchedAtLabel;
  final String Function(EmailMessageSnapshot message) senderLabel;
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

    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              YhChip(label: '$protocolLabel 只读快照', selected: true),
              YhChip(label: '刷新 $fetchedAtLabel'),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          Text(current.subject, style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          Text(
            senderLabel(current),
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          Text(
            formatDateTime(current.receivedAt),
            style: theme.typography.caption.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          const YhBanner(text: '只读正文快照：不会执行回复、转发、删除、移动或标记已读操作。'),
          SizedBox(height: theme.spacing.m),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  theme.breakpoint.compact / 3 -
                  theme.spacing.l +
                  theme.spacing.xs,
            ),
            child: SingleChildScrollView(
              primary: false,
              child: YhSelectableText(
                current.body.isEmpty ? '无可展示正文。' : current.body,
                semanticLabel: '邮件正文快照',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
