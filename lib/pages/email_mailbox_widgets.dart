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
    final theme = FluentTheme.of(context);
    final colors = context.fluentColors;
    return FluentSurface(
      key: const Key('email-mailbox-list-pane'),
      minHeight: 520,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(FluentSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('收件箱', style: theme.typography.subtitle),
                    ),
                    if (refreshing)
                      const FluentStatusChip(
                        label: '同步中',
                        icon: FluentIcons.refresh,
                        tone: FluentStatusChipTone.brand,
                      ),
                  ],
                ),
                const SizedBox(height: FluentSpacing.xs),
                Wrap(
                  spacing: FluentSpacing.s,
                  runSpacing: FluentSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${snapshot.protocol.label} 最近邮件：${messages.length} 封',
                      style: theme.typography.caption?.copyWith(
                        color: colors.neutralForeground3,
                      ),
                    ),
                    Text(
                      '上次刷新：${formatDateTime(snapshot.fetchedAt)}',
                      style: theme.typography.caption?.copyWith(
                        color: colors.neutralForeground3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          if (messages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(FluentSpacing.l),
              child: FluentInfoBar(
                title: Text('暂无可展示邮件'),
                content: Text('邮箱协议登录成功，但最近邮件列表为空。'),
                severity: FluentInfoSeverity.info,
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
              if (index != messages.length - 1) const Divider(),
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
    final colors = context.fluentColors;
    final theme = FluentTheme.of(context);
    return HoverButton(
      onPressed: onPressed,
      builder: (context, states) {
        final background = selected
            ? colors.brandStroke2.withValues(alpha: 0.16)
            : states.isHovered || states.isFocused
            ? colors.subtleBackgroundHover
            : null;
        return Container(
          color: background,
          padding: const EdgeInsets.all(FluentSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmailSenderAnchor(label: senderLabel(message)),
              const SizedBox(width: FluentSpacing.s),
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
                            style: theme.typography.bodyStrong,
                          ),
                        ),
                        const SizedBox(width: FluentSpacing.s),
                        Text(
                          formatDateTime(message.receivedAt),
                          style: theme.typography.caption?.copyWith(
                            color: colors.neutralForeground3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FluentSpacing.xxs),
                    Text(
                      senderLabel(message),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption?.copyWith(
                        color: colors.neutralForeground3,
                      ),
                    ),
                    const SizedBox(height: FluentSpacing.xxs),
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
    );
  }
}

class _EmailSenderAnchor extends StatelessWidget {
  const _EmailSenderAnchor({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = context.fluentAccents.mail;
    final initial = label.trim().isEmpty ? '邮' : label.trim().characters.first;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: context.fluentRadii.mediumBorder,
      ),
      child: Text(
        initial,
        style: FluentTheme.of(context).typography.bodyStrong?.copyWith(
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
    final theme = FluentTheme.of(context);
    final colors = context.fluentColors;
    return FluentSurface(
      key: const Key('email-reading-placeholder'),
      minHeight: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FluentSectionHeader(
            title: '阅读窗格',
            subtitle: '选择一封邮件查看正文快照，或点击写邮件打开撰写面板',
            icon: FluentIcons.read,
          ),
          const SizedBox(height: FluentSpacing.xl),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  FluentSurfaceIcon(
                    icon: FluentIcons.mail,
                    color: context.fluentAccents.mail,
                    size: 56,
                  ),
                  const SizedBox(height: FluentSpacing.m),
                  Text('保持只读收件箱', style: theme.typography.bodyStrong),
                  const SizedBox(height: FluentSpacing.xs),
                  Text(
                    '这里展示最近读取到的邮件正文快照。当前不会执行回复、转发、删除、移动或标记已读操作。',
                    textAlign: TextAlign.center,
                    style: theme.typography.caption?.copyWith(
                      color: colors.neutralForeground3,
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
    final theme = FluentTheme.of(context);
    final colors = context.fluentColors;
    final current = message;
    if (current == null) {
      return const FluentSurface(
        minHeight: 320,
        child: Center(child: Text('选择一封邮件查看正文快照')),
      );
    }

    return FluentSurface(
      minHeight: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FluentStatusChip(
                label: '$protocolLabel 只读快照',
                icon: FluentIcons.mail,
                tone: FluentStatusChipTone.brand,
              ),
              FluentStatusChip(
                label: '刷新 $fetchedAtLabel',
                icon: FluentIcons.clock,
              ),
            ],
          ),
          const SizedBox(height: FluentSpacing.m),
          Text(current.subject, style: theme.typography.subtitle),
          const SizedBox(height: FluentSpacing.s),
          Text(
            senderLabel(current),
            style: theme.typography.caption?.copyWith(
              color: colors.neutralForeground3,
            ),
          ),
          Text(
            formatDateTime(current.receivedAt),
            style: theme.typography.caption?.copyWith(
              color: colors.neutralForeground3,
            ),
          ),
          const SizedBox(height: FluentSpacing.m),
          const FluentInfoBar(
            title: Text('只读正文快照'),
            content: Text('不会执行回复、转发、删除、移动或标记已读操作。'),
            severity: FluentInfoSeverity.info,
          ),
          const SizedBox(height: FluentSpacing.m),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: SingleChildScrollView(
              primary: false,
              child: SelectableText(
                current.body.isEmpty ? '无可展示正文。' : current.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
