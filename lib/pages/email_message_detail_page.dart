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

  const EmailMessageDetailPage({super.key, required this.message});

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
        padding: EdgeInsets.all(theme.spacing.m),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.breakpoint.expanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YhCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.subject, style: theme.typography.h3),
                      SizedBox(height: theme.spacing.s),
                      Text('发件人：${_senderLabel(message)}'),
                      Text('时间：${_formatOptionalDateTime(message.receivedAt)}'),
                    ],
                  ),
                ),
                SizedBox(height: theme.spacing.m),
                const YhBanner(
                  text: '只读正文快照：正文来自本次收信结果，不会执行回复、转发、删除、移动或标记已读操作。',
                ),
                SizedBox(height: theme.spacing.m),
                YhCard(
                  child: YhSelectableText(
                    message.body.isEmpty ? '无可展示正文。' : message.body,
                    semanticLabel: '邮件正文内容',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _senderLabel(EmailMessageSnapshot message) {
    if (message.senderName.isEmpty) return message.senderAddress;
    return '${message.senderName} <${message.senderAddress}>';
  }

  String _formatOptionalDateTime(DateTime? dateTime) {
    if (dateTime == null) return '时间未知';
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
