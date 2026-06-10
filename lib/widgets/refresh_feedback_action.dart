/*
 * 刷新反馈动作 — 在刷新按钮位置短暂展示成功或失败结果
 * @Project : SSPU-AllinOne
 * @File : refresh_feedback_action.dart
 * @Author : Qintsg
 * @Date : 2026-06-10
 */

import '../design/fluent_ui.dart';
import '../theme/fluent_tokens.dart';

/// 刷新结束后的短暂反馈状态。
class RefreshActionFeedback {
  const RefreshActionFeedback._({required this.success, this.reason});

  /// 构建刷新成功反馈。
  const RefreshActionFeedback.success() : this._(success: true);

  /// 构建刷新失败反馈。
  const RefreshActionFeedback.failure(String reason)
    : this._(success: false, reason: reason);

  /// 是否刷新成功。
  final bool success;

  /// 刷新失败原因。
  final String? reason;

  /// 按钮位置展示的文案。
  String get label {
    if (success) return '刷新成功√';
    final normalizedReason = reason?.trim();
    return '刷新失败:${normalizedReason?.isEmpty ?? true ? '未知错误' : normalizedReason}×';
  }
}

/// 刷新按钮与刷新结果反馈的统一动作控件。
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

  /// 当前是否正在刷新。
  final bool isLoading;

  /// 刷新按钮回调。
  final VoidCallback? onPressed;

  /// 刷新按钮提示。
  final String tooltip;

  /// 无障碍标签。
  final String semanticLabel;

  /// 刷新结束后的短暂反馈。
  final RefreshActionFeedback? feedback;

  /// 视觉尺寸。
  final double size;

  /// 图标尺寸。
  final double iconSize;

  /// 最小触控尺寸。
  final double minTouchSize;

  /// 反馈文本最大宽度。
  final double maxFeedbackWidth;

  @override
  Widget build(BuildContext context) {
    final currentFeedback = feedback;
    if (currentFeedback != null) {
      return _RefreshFeedbackLabel(
        feedback: currentFeedback,
        minTouchSize: minTouchSize,
        height: size,
        maxWidth: maxFeedbackWidth,
      );
    }

    return _RefreshIconButton(
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      size: size,
      iconSize: iconSize,
      minTouchSize: minTouchSize,
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: const FluentProgressRing(strokeWidth: 2),
            )
          : const Icon(FluentIcons.refresh),
    );
  }
}

class _RefreshIconButton extends StatelessWidget {
  const _RefreshIconButton({
    required this.tooltip,
    required this.semanticLabel,
    required this.size,
    required this.iconSize,
    required this.minTouchSize,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final double minTouchSize;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = context.fluentColors;
    final foregroundColor = enabled
        ? colors.neutralForeground2
        : colors.neutralForegroundDisabled;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTouchSize,
            minHeight: minTouchSize,
          ),
          child: Center(
            child: SizedBox.square(
              dimension: size,
              child: IconButton(
                style: ButtonStyle(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  iconSize: WidgetStatePropertyAll(iconSize),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: context.fluentRadii.mediumBorder,
                    ),
                  ),
                  foregroundColor: WidgetStatePropertyAll(foregroundColor),
                ),
                onPressed: onPressed,
                icon: IconTheme.merge(
                  data: IconThemeData(size: iconSize, color: foregroundColor),
                  child: icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshFeedbackLabel extends StatelessWidget {
  const _RefreshFeedbackLabel({
    required this.feedback,
    required this.minTouchSize,
    required this.height,
    required this.maxWidth,
  });

  final RefreshActionFeedback feedback;
  final double minTouchSize;
  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final foreground = feedback.success
        ? colors.statusSuccessForeground
        : colors.statusDangerForeground;
    final background = feedback.success
        ? colors.statusSuccessBackground
        : colors.statusDangerBackground;
    final label = feedback.label;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: false,
        label: label,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTouchSize,
            minHeight: minTouchSize,
          ),
          child: Center(
            child: Container(
              height: height,
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.s),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: context.fluentRadii.mediumBorder,
                border: Border.all(color: foreground.withValues(alpha: 0.28)),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.fluentType.caption1Strong.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
