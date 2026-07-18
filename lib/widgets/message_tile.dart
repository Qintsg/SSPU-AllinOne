/* 消息列表项 — 清源信息流行。 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/message_item.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.isRead,
    required this.isDark,
    required this.onTap,
    required this.onMarkRead,
  });

  final MessageItem message;
  final bool isRead;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      semanticLabel: '打开消息：${message.title}',
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.m,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < theme.breakpoint.compact;
          final content = _buildContent(context);
          final actions = _buildDateAndActions(context, narrow: narrow);
          if (narrow) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUnreadIndicator(context),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      SizedBox(height: theme.spacing.s),
                      actions,
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              _buildUnreadIndicator(context),
              Expanded(child: content),
              SizedBox(width: theme.spacing.m),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnreadIndicator(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      label: isRead ? '已读' : '未读',
      child: Container(
        width: theme.spacing.s,
        height: theme.spacing.s,
        margin: EdgeInsetsDirectional.only(
          top: theme.spacing.xs,
          end: theme.spacing.s,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRead ? theme.color.border : theme.color.brandStrong,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.yhTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.copyWith(
            color: isRead ? theme.color.muted : theme.color.foreground,
            fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        Wrap(
          spacing: theme.spacing.xs,
          runSpacing: theme.spacing.xs,
          children: _metadataTags(context),
        ),
      ],
    );
  }

  Widget _buildDateAndActions(BuildContext context, {required bool narrow}) {
    final theme = context.yhTheme;
    final date = Text(
      _formatDisplayDateTime(message),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.caption.copyWith(color: theme.color.muted),
    );
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        YhIconButton(
          icon: YhIcons.open,
          semanticLabel: '在浏览器中打开',
          onTap: onTap,
        ),
        if (!isRead)
          YhIconButton(
            icon: YhIcons.check,
            semanticLabel: '标为已读',
            onTap: onMarkRead,
          ),
      ],
    );
    if (narrow) {
      return Wrap(
        spacing: theme.spacing.s,
        runSpacing: theme.spacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [date, buttons],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: theme.control.regular * 3 + theme.spacing.m,
          ),
          child: date,
        ),
        SizedBox(height: theme.spacing.xs),
        buttons,
      ],
    );
  }

  List<Widget> _metadataTags(BuildContext context) {
    final tags = <Widget>[];
    final labels = <String>{};
    void add(String value, {required bool primary}) {
      final text = value.trim();
      if (text.isEmpty || !labels.add(text)) return;
      tags.add(_MetadataTag(text: text, primary: primary));
    }

    add(message.sourceType.label, primary: true);
    if (_isWechatMessage) {
      add(_wechatAccountName, primary: false);
    } else {
      add(message.sourceName.label, primary: false);
      add(message.category.label, primary: false);
      final name = message.mpName?.trim();
      if (name != null) add(name, primary: false);
    }
    return tags;
  }

  bool get _isWechatMessage =>
      message.sourceType == MessageSourceType.wechatPublic ||
      message.sourceType == MessageSourceType.wechatService;

  String get _wechatAccountName {
    final name = message.mpName?.trim();
    return name == null || name.isEmpty ? '公众号名称未知' : name;
  }

  String _formatDisplayDateTime(MessageItem item) {
    final displayDate = item.date.trim().isNotEmpty
        ? item.date.trim()
        : item.timestamp != null
        ? _formatDate(item.timestamp!)
        : '';
    if (item.timestamp == null || displayDate.isEmpty) return displayDate;
    return '$displayDate ${_formatTime(item.timestamp!)}';
  }

  String _formatDate(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MetadataTag extends StatelessWidget {
  const _MetadataTag({required this.text, required this.primary});

  final String text;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary ? theme.color.brandTint : theme.color.sunken,
        borderRadius: BorderRadius.circular(theme.radius.s),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.s,
          vertical: theme.spacing.xs,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: theme.breakpoint.compact / 2 - theme.spacing.m,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption.copyWith(
              color: primary ? theme.color.brandInk : theme.color.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
