/*
 * 消息列表项组件 — 从 info_page.dart 提取的消息展示行
 * @Project : SSPU-AllinOne
 * @File : message_tile.dart
 * @Author : Qintsg
 * @Date : 2026-04-17
 */

import '../design/fluent_ui.dart';

import '../models/message_item.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_motion.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';

/// 单条消息列表项组件。
/// 展示消息标题、标签、日期、已读/未读状态、操作按钮。
class MessageTile extends StatefulWidget {
  /// 消息数据。
  final MessageItem message;

  /// 是否已读。
  final bool isRead;

  /// 当前是否暗色主题；保留历史入参，组件实际从 Fluent 主题读取颜色。
  final bool isDark;

  /// 点击跳转回调。
  final VoidCallback onTap;

  /// 标为已读回调。
  final VoidCallback onMarkRead;

  const MessageTile({
    super.key,
    required this.message,
    required this.isRead,
    required this.isDark,
    required this.onTap,
    required this.onMarkRead,
  });

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final titleStyle = widget.isRead
        ? type.body1.copyWith(color: colors.neutralForeground2)
        : type.body1Strong;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? colors.neutralBackground1Hover : null,
            borderRadius: AppShapes.md,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow =
                  AppBreakpoints.fromWidth(constraints.maxWidth) ==
                  WindowSizeClass.compact;
              final content = _buildMessageContent(context, titleStyle);
              final actions = _buildDateAndActions(context, isNarrow: isNarrow);

              if (isNarrow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUnreadIndicator(context),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content,
                          const SizedBox(height: AppSpacing.sm),
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
                  const SizedBox(width: AppSpacing.md),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建未读指示点。
  Widget _buildUnreadIndicator(BuildContext context) {
    final colors = context.fluentColors;
    return Container(
      width: AppSpacing.sm,
      height: AppSpacing.sm,
      margin: const EdgeInsetsDirectional.only(
        top: AppSpacing.xs,
        end: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isRead ? null : colors.brandBackground,
      ),
    );
  }

  /// 构建消息主体内容。
  Widget _buildMessageContent(BuildContext context, TextStyle? titleStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.message.title,
          style: titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _buildMetadataTags(context),
        ),
      ],
    );
  }

  /// 构建日期与操作按钮区域。
  Widget _buildDateAndActions(BuildContext context, {required bool isNarrow}) {
    final colors = context.fluentColors;
    final type = context.fluentType;
    final dateText = Text(
      _formatDisplayDateTime(widget.message),
      style: type.caption1.copyWith(color: colors.neutralForeground2),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final buttons = Row(mainAxisSize: MainAxisSize.min, children: _actionButtons);

    if (isNarrow) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [dateText, buttons],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: dateText,
        ),
        const SizedBox(height: AppSpacing.xs),
        buttons,
      ],
    );
  }

  List<Widget> get _actionButtons {
    return [
      FluentIconButton(
        tooltip: '在浏览器中打开',
        icon: const Icon(FluentIcons.openInNewWindow),
        onPressed: widget.onTap,
      ),
      if (!widget.isRead)
        FluentIconButton(
          tooltip: '标为已读',
          icon: const Icon(FluentIcons.read),
          onPressed: widget.onMarkRead,
        ),
    ];
  }

  /// 格式化消息展示日期时间，保证当天官网消息不会只显示时间。
  String _formatDisplayDateTime(MessageItem message) {
    final displayDate = message.date.trim().isNotEmpty
        ? message.date.trim()
        : message.timestamp != null
        ? _formatDate(message.timestamp!)
        : '';

    if (message.timestamp == null || displayDate.isEmpty) {
      return displayDate;
    }
    return '$displayDate ${_formatTime(message.timestamp!)}';
  }

  /// 格式化时间戳为 YYYY-MM-DD，用于修复旧缓存中的空日期。
  String _formatDate(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 格式化时间戳为 HH:mm。
  String _formatTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 构建标签 badge。
  Widget _buildTag(
    BuildContext context,
    String text, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, borderRadius: AppShapes.sm),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            text,
            style: context.fluentType.caption2Strong.copyWith(
              color: foregroundColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMetadataTags(BuildContext context) {
    final colors = context.fluentColors;
    final tags = <Widget>[];
    final seenSourceLabels = <String>{};

    void addSourceTag(
      String text, {
      required Color backgroundColor,
      required Color foregroundColor,
    }) {
      final trimmed = text.trim();
      if (trimmed.isEmpty || !seenSourceLabels.add(trimmed)) return;
      tags.add(
        _buildTag(
          context,
          trimmed,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      );
    }

    if (_isWechatMessage) {
      addSourceTag(
        widget.message.sourceType.label,
        backgroundColor: colors.brandBackgroundSelected.withValues(alpha: 0.12),
        foregroundColor: colors.brandForeground1,
      );
      addSourceTag(
        _wechatAccountName,
        backgroundColor: colors.neutralBackground2,
        foregroundColor: colors.neutralForeground2,
      );
    } else {
      addSourceTag(
        widget.message.sourceType.label,
        backgroundColor: colors.brandBackgroundSelected.withValues(alpha: 0.12),
        foregroundColor: colors.brandForeground1,
      );
      addSourceTag(
        widget.message.sourceName.label,
        backgroundColor: colors.neutralBackground2,
        foregroundColor: colors.neutralForeground2,
      );
      addSourceTag(
        widget.message.category.label,
        backgroundColor: colors.neutralBackground3,
        foregroundColor: colors.neutralForeground2,
      );

      final mpName = widget.message.mpName?.trim();
      if (mpName != null && mpName.isNotEmpty) {
        addSourceTag(
          mpName,
          backgroundColor: colors.neutralBackground2,
          foregroundColor: colors.neutralForeground2,
        );
      }
    }

    return tags;
  }

  bool get _isWechatMessage {
    return widget.message.sourceType == MessageSourceType.wechatPublic ||
        widget.message.sourceType == MessageSourceType.wechatService;
  }

  String get _wechatAccountName {
    final mpName = widget.message.mpName?.trim();
    if (mpName == null || mpName.isEmpty) return '公众号名称未知';
    return mpName;
  }
}
