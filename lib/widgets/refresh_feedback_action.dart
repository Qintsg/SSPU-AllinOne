/*
 * 刷新反馈动作 — 在刷新按钮位置短暂展示成功或失败结果
 * @Project : SSPU-AllinOne
 * @File : refresh_feedback_action.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

import '../design/qingyuan/qingyuan_ui.dart';

class RefreshActionFeedback {
  const RefreshActionFeedback._({required this.success, this.reason});
  const RefreshActionFeedback.success() : this._(success: true);
  const RefreshActionFeedback.failure(String reason)
    : this._(success: false, reason: reason);

  final bool success;
  final String? reason;

  String get label {
    if (success) return '刷新成功√';
    final normalizedReason = reason?.trim();
    return '刷新失败:${normalizedReason?.isEmpty ?? true ? '未知错误' : normalizedReason}×';
  }
}

class RefreshStatusLine extends StatelessWidget {
  const RefreshStatusLine({
    super.key,
    required this.label,
    required this.action,
    this.labelStyle,
    this.minLineHeight = 32,
    this.actionReservedWidth = 48,
  });

  final String label;
  final Widget action;
  final TextStyle? labelStyle;
  final double minLineHeight;
  final double actionReservedWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: SizedBox(
            height: minLineHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
          ),
        ),
        SizedBox(width: theme.spacing.s),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: actionReservedWidth),
            child: action,
          ),
        ),
      ],
    );
  }
}

class RefreshFeedbackAction extends StatelessWidget {
  const RefreshFeedbackAction({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.feedback,
    this.size = 32,
    this.iconSize = 16,
    this.minTouchSize = 48,
    this.maxFeedbackWidth = 220,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final String tooltip;
  final String semanticLabel;
  final RefreshActionFeedback? feedback;
  final double size;
  final double iconSize;
  final double minTouchSize;
  final double maxFeedbackWidth;

  @override
  Widget build(BuildContext context) {
    final currentFeedback = feedback;
    if (currentFeedback != null) {
      return _RefreshFeedbackLabel(
        feedback: currentFeedback,
        minTouchSize: minTouchSize,
        maxWidth: maxFeedbackWidth,
      );
    }
    return YhTooltip(
      message: tooltip,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minTouchSize,
          minHeight: minTouchSize,
        ),
        child: YhIconButton(
          icon: isLoading ? YhIcons.sync : YhIcons.refresh,
          semanticLabel: isLoading ? '正在$semanticLabel' : semanticLabel,
          onTap: isLoading ? null : onPressed,
        ),
      ),
    );
  }
}

class _RefreshFeedbackLabel extends StatelessWidget {
  const _RefreshFeedbackLabel({
    required this.feedback,
    required this.minTouchSize,
    required this.maxWidth,
  });

  final RefreshActionFeedback feedback;
  final double minTouchSize;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final foreground = feedback.success
        ? theme.color.success
        : theme.color.danger;
    return YhTooltip(
      message: feedback.label,
      child: Semantics(
        label: feedback.label,
        liveRegion: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minTouchSize,
            maxWidth: maxWidth,
          ),
          child: Center(
            child: Text(
              feedback.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typography.small.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
