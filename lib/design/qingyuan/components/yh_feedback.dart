/*
 * 清源页面反馈组件 — 统一紧凑浮层反馈入口
 * @Project : SSPU-AllinOne
 * @File : yh_feedback.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../models/app_feedback_severity.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_card.dart';
import 'yh_icon_button.dart';

export '../../../models/app_feedback_severity.dart';

OverlayEntry? _activeFeedbackEntry;

const _feedbackVisibleDuration = Duration(seconds: 3);

/// 显示全局清源反馈浮层；连续调用时替换上一条反馈。
///
/// :param context: 提供目标 [Overlay] 与清源主题的页面上下文。
/// :param message: 面向用户的主要操作结果。
/// :param details: 可选的恢复说明或补充上下文。
/// :param severity: 信息、成功、警告或错误语义等级。
void showYhFeedback(
  BuildContext context, {
  required String message,
  String? details,
  AppFeedbackSeverity severity = AppFeedbackSeverity.info,
}) {
  _activeFeedbackEntry?.remove();
  _activeFeedbackEntry = null;

  late OverlayEntry entry;

  /// 立即移除当前反馈 Overlay，并清理全局活动引用。
  ///
  /// :returns: 无返回值。
  void removeEntry() {
    if (!entry.mounted) return;
    entry.remove();
    if (identical(_activeFeedbackEntry, entry)) {
      _activeFeedbackEntry = null;
    }
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      final theme = overlayContext.yhTheme;
      final media = MediaQuery.of(overlayContext);
      final availableWidth =
          media.size.width -
          media.padding.left -
          media.padding.right -
          theme.spacing.l * 2;
      final preferredWidth = theme.breakpoint.medium / 2 + theme.spacing.xl2;
      final maxWidth = availableWidth.clamp(0.0, preferredWidth).toDouble();
      return PositionedDirectional(
        top: media.padding.top + theme.spacing.l,
        end: media.padding.right + theme.spacing.l,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _YhFeedbackOverlay(
            message: message,
            details: details,
            severity: severity,
            disableAnimations: MediaQuery.disableAnimationsOf(context),
            onDismissed: removeEntry,
          ),
        ),
      );
    },
  );

  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  _activeFeedbackEntry = entry;
  overlay.insert(entry);
}

class _YhFeedbackOverlay extends StatefulWidget {
  const _YhFeedbackOverlay({
    required this.message,
    required this.severity,
    required this.disableAnimations,
    required this.onDismissed,
    this.details,
  });

  final String message;
  final String? details;
  final AppFeedbackSeverity severity;
  final bool disableAnimations;
  final VoidCallback onDismissed;

  @override
  State<_YhFeedbackOverlay> createState() => _YhFeedbackOverlayState();
}

class _YhFeedbackOverlayState extends State<_YhFeedbackOverlay> {
  Timer? _dismissTimer;
  bool _visible = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      _dismissTimer = Timer(_feedbackVisibleDuration, dismiss);
    });
  }

  /// 启动退出动效，并在动效完成后移除 Overlay。
  void dismiss() {
    if (_dismissed || !mounted) return;
    _dismissTimer?.cancel();
    final duration = context.yhTheme.motion.effective(
      context.yhTheme.motion.base,
      disableAnimations: widget.disableAnimations,
    );
    if (duration == Duration.zero) {
      _finishDismissal();
      return;
    }
    setState(() => _visible = false);
    _dismissTimer = Timer(duration, _finishDismissal);
  }

  /// 确保 Overlay 只被移除一次。
  void _finishDismissal() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final duration = theme.motion.effective(
      theme.motion.base,
      disableAnimations: widget.disableAnimations,
    );
    final color = switch (widget.severity) {
      AppFeedbackSeverity.info => theme.color.brandStrong,
      AppFeedbackSeverity.success => theme.color.success,
      AppFeedbackSeverity.warning => theme.color.warning,
      AppFeedbackSeverity.error => theme.color.danger,
    };
    final icon = switch (widget.severity) {
      AppFeedbackSeverity.info => YhIcons.info,
      AppFeedbackSeverity.success => YhIcons.check,
      AppFeedbackSeverity.warning => YhIcons.warning,
      AppFeedbackSeverity.error => YhIcons.close,
    };

    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -0.12),
      duration: duration,
      curve: theme.motion.curve,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: duration,
        curve: theme.motion.curve,
        onEnd: () {
          if (!_visible) _finishDismissal();
        },
        child: Semantics(
          liveRegion: true,
          child: ConstrainedBox(
            key: const Key('app-feedback-toast'),
            constraints: BoxConstraints(
              maxWidth: theme.breakpoint.medium / 2 + theme.spacing.xl2,
            ),
            child: YhCard(
              elevated: true,
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.m,
                vertical: theme.spacing.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.xs),
                    child: Icon(icon, size: theme.spacing.m, color: color),
                  ),
                  SizedBox(width: theme.spacing.s),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.copyWith(
                            color: theme.color.foreground,
                          ),
                        ),
                        if (widget.details != null) ...[
                          SizedBox(height: theme.spacing.xs),
                          Text(
                            widget.details!,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.small.copyWith(
                              color: theme.color.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: theme.spacing.s),
                  YhIconButton(
                    icon: YhIcons.close,
                    semanticLabel: '关闭反馈',
                    variant: YhIconButtonVariant.ghost,
                    onTap: dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
