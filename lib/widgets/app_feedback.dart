/*
 * 清源页面反馈工具 — 统一紧凑浮层反馈入口
 * @Project : SSPU-AllinOne
 * @File : app_feedback.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/app_feedback_severity.dart';

export '../models/app_feedback_severity.dart';

OverlayEntry? _activeFeedbackEntry;
int _feedbackGeneration = 0;

const _feedbackVisibleDuration = Duration(seconds: 3);

void showAppFeedback(
  BuildContext context, {
  required String message,
  String? details,
  AppFeedbackSeverity severity = AppFeedbackSeverity.info,
}) {
  _activeFeedbackEntry?.remove();
  _activeFeedbackEntry = null;
  final generation = ++_feedbackGeneration;

  late OverlayEntry entry;
  void close() {
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
          child: _YhFeedbackToast(
            message: message,
            details: details,
            severity: severity,
            onClose: close,
          ),
        ),
      );
    },
  );

  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  _activeFeedbackEntry = entry;
  overlay.insert(entry);
  Future<void>.delayed(_feedbackVisibleDuration, () {
    if (generation == _feedbackGeneration &&
        identical(_activeFeedbackEntry, entry)) {
      close();
    }
  });
}

class _YhFeedbackToast extends StatelessWidget {
  const _YhFeedbackToast({
    required this.message,
    required this.severity,
    required this.onClose,
    this.details,
  });

  final String message;
  final String? details;
  final AppFeedbackSeverity severity;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final color = switch (severity) {
      AppFeedbackSeverity.info => theme.color.brandStrong,
      AppFeedbackSeverity.success => theme.color.success,
      AppFeedbackSeverity.warning => theme.color.warning,
      AppFeedbackSeverity.error => theme.color.danger,
    };
    final icon = switch (severity) {
      AppFeedbackSeverity.info => YhIcons.info,
      AppFeedbackSeverity.success => YhIcons.check,
      AppFeedbackSeverity.warning => YhIcons.warning,
      AppFeedbackSeverity.error => YhIcons.close,
    };

    return Semantics(
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
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.copyWith(
                        color: theme.color.foreground,
                      ),
                    ),
                    if (details != null) ...[
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        details!,
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
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
