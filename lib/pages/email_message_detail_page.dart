/*
 * 邮件正文详情页 — 展示邮箱只读收信结果中的正文快照
 * @Project : SSPU-AllinOne
 * @File : email_message_detail_page.dart
 * @Author : Qintsg
 * @Date : 2026-05-02
 */

part of 'email_page.dart';

/// 邮件正文详情页。
class EmailMessageDetailPage extends StatelessWidget {
  /// 列表页传入的邮件快照。
  final EmailMessageSnapshot message;

  /// 视觉测试与相对时间文案使用的固定时钟。
  final DateTime? nowOverride;
  final Future<void> Function(EmailAttachmentSnapshot attachment)?
  onDownloadAttachment;
  final Set<String> downloadingAttachmentIds;

  const EmailMessageDetailPage({
    super.key,
    required this.message,
    this.nowOverride,
    this.onDownloadAttachment,
    this.downloadingAttachmentIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: YhAppBar(
        title: '邮件正文',
        leading: YhIconButton(
          icon: YhIcons.back,
          semanticLabel: '返回',
          variant: YhIconButtonVariant.ghost,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.medium),
            child: Padding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < theme.breakpoint.medium
                    ? theme.spacing.m
                    : theme.spacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: theme.layout.popoverWidth + theme.spacing.xl,
                ),
                child: YhCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _senderDisplayName(message),
                              style: theme.typography.caption.copyWith(
                                color: theme.color.muted,
                              ),
                            ),
                          ),
                          SizedBox(width: theme.spacing.m),
                          Text(
                            _formatOptionalDateTime(message.receivedAt),
                            style: theme.typography.caption.copyWith(
                              color: theme.color.muted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: theme.spacing.s),
                      Text(message.subject, style: theme.typography.h2),
                      SizedBox(height: theme.spacing.s),
                      Text(
                        '来自 ${message.senderAddress}',
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
                        message.body.isEmpty ? '无可展示正文。' : message.body,
                        style: theme.typography.reading.copyWith(
                          color: theme.color.muted,
                        ),
                        semanticLabel: '邮件正文内容',
                      ),
                      if (message.attachments.isNotEmpty &&
                          onDownloadAttachment != null) ...[
                        SizedBox(height: theme.spacing.l),
                        _EmailAttachmentList(
                          message: message,
                          downloadingAttachmentIds: downloadingAttachmentIds,
                          onDownloadAttachment: (_, attachment) =>
                              onDownloadAttachment!(attachment),
                        ),
                      ],
                      SizedBox(height: theme.spacing.l),
                      const YhBanner(
                        text: '打开邮件会回写 IMAP 已读；不会执行回复、转发、删除或移动操作。',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _senderDisplayName(EmailMessageSnapshot message) {
    return message.senderName.isEmpty
        ? message.senderAddress
        : message.senderName;
  }

  String _formatOptionalDateTime(DateTime? dateTime) {
    if (dateTime == null) return '时间未知';
    final now = nowOverride ?? DateTime.now();
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(date).inDays;
    final clock =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    if (days == 0) return '今天 $clock';
    if (days == 1) return '昨天 $clock';
    if (dateTime.year == now.year) {
      return '${dateTime.month} 月 ${dateTime.day} 日';
    }
    return '${dateTime.year} 年 ${dateTime.month} 月 ${dateTime.day} 日';
  }
}
