/* 消息列表项 — 清源信息流行。 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/message_item.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.isRead,
    required this.onTap,
    this.nowOverride,
  });

  final MessageItem message;
  final bool isRead;
  final VoidCallback onTap;
  final DateTime? nowOverride;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      semanticLabel: '打开消息：${message.title}',
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: YhStatusPill(
                    label: _sourceLabel,
                    kind: YhStatusKind.info,
                  ),
                ),
              ),
              SizedBox(width: theme.spacing.s),
              Text(
                _formatDisplayDateTime(message),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption.copyWith(
                  color: theme.color.muted,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            message.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.feed.copyWith(
              color: isRead ? theme.color.muted : theme.color.foreground,
              fontWeight: isRead ? theme.typography.body.fontWeight : null,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            _summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.supporting.copyWith(
              color: theme.color.muted,
            ),
          ),
        ],
      ),
    );
  }

  String get _summary {
    final summary = message.summary?.trim();
    if (summary != null && summary.isNotEmpty) return summary;
    if (_isWechatMessage) {
      return '${message.sourceType.label} · $_wechatAccountName，点击查看原文。';
    }
    return '${message.sourceType.label} · ${message.category.label}，点击查看原文。';
  }

  bool get _isWechatMessage =>
      message.sourceType == MessageSourceType.wechatPublic ||
      message.sourceType == MessageSourceType.wechatService;

  String get _sourceLabel {
    if (_isWechatMessage) return '微信公众号';
    if (message.sourceType == MessageSourceType.schoolWebsite &&
        message.sourceName != MessageSourceName.jwc) {
      return '学校官网';
    }
    return message.sourceName.label;
  }

  String get _wechatAccountName {
    final name = message.mpName?.trim();
    return name == null || name.isEmpty ? '公众号名称未知' : name;
  }

  String _formatDisplayDateTime(MessageItem item) {
    if (item.timestamp == null) return item.date.trim();
    final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp!);
    final now = nowOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final dayDifference = today.difference(messageDay).inDays;
    final time = _formatTime(item.timestamp!);
    if (dayDifference == 0) return '今天 $time';
    if (dayDifference == 1) return '昨天 $time';
    return '${date.month} 月 ${date.day} 日';
  }

  String _formatTime(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
