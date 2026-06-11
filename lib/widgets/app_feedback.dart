/*
 * Fluent 2 页面反馈工具 — 统一紧凑浮层反馈入口
 * @Project : SSPU-AllinOne
 * @File : app_feedback.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import '../design/fluent_ui.dart';

OverlayEntry? _activeFeedbackEntry;

/// 页面反馈级别。
enum AppFeedbackSeverity {
  /// 普通信息。
  info,

  /// 成功反馈。
  success,

  /// 警告反馈。
  warning,

  /// 错误反馈。
  error,
}

/// 显示 Fluent 2 紧凑反馈。
void showAppFeedback(
  BuildContext context, {
  required String message,
  AppFeedbackSeverity severity = AppFeedbackSeverity.info,
}) {
  final infoSeverity = switch (severity) {
    AppFeedbackSeverity.info => FluentInfoSeverity.info,
    AppFeedbackSeverity.success => FluentInfoSeverity.success,
    AppFeedbackSeverity.warning => FluentInfoSeverity.warning,
    AppFeedbackSeverity.error => FluentInfoSeverity.error,
  };

  showFluentInfoBar(context, title: Text(message), severity: infoSeverity);
}

/// 显示自定义 Fluent 2 紧凑反馈。
void showFluentInfoBar(
  BuildContext context, {
  required Widget title,
  Widget? content,
  FluentInfoSeverity severity = FluentInfoSeverity.info,
  Widget Function(VoidCallback close)? actionBuilder,
}) {
  _activeFeedbackEntry?.remove();
  _activeFeedbackEntry = null;

  late OverlayEntry entry;
  void close() {
    if (!entry.mounted) return;
    entry.remove();
    if (identical(_activeFeedbackEntry, entry)) {
      _activeFeedbackEntry = null;
    }
  }

  entry = OverlayEntry(
    builder: (context) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.fluentSpacing.xl,
            vertical: context.fluentSpacing.xxl,
          ),
          child: _CompactFeedbackToast(
            title: title,
            content: content,
            severity: severity,
            action: actionBuilder?.call(close),
          ),
        ),
      ),
    ),
  );

  _activeFeedbackEntry = entry;
  Overlay.of(context).insert(entry);
  Future<void>.delayed(const Duration(seconds: 3), () {
    if (identical(_activeFeedbackEntry, entry)) close();
  });
}

/// 紧凑页面反馈浮层，不占据页面布局高度。
class _CompactFeedbackToast extends StatelessWidget {
  const _CompactFeedbackToast({
    required this.title,
    required this.severity,
    this.content,
    this.action,
  });

  /// 标题。
  final Widget title;

  /// 详情。
  final Widget? content;

  /// 级别。
  final FluentInfoSeverity severity;

  /// 右侧操作。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final spacing = context.fluentSpacing;
    final radii = context.fluentRadii;
    final theme = FluentTheme.of(context);
    final severityColors = _severityColors(colors);

    return ConstrainedBox(
      key: const Key('app-feedback-toast'),
      constraints: BoxConstraints(
        maxWidth: context.appMetrics.feedbackToastMaxWidth,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: radii.xLargeBorder,
          border: Border.all(color: colors.neutralStroke2),
          boxShadow: context.fluentElevation.shadow16,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.m,
            vertical: spacing.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(top: spacing.xxs),
                child: Icon(
                  _severityIcon,
                  size: 16,
                  color: severityColors.foreground,
                ),
              ),
              SizedBox(width: spacing.s),
              Flexible(
                child: DefaultTextStyle.merge(
                  style: context.fluentType.body1.copyWith(
                    color: colors.neutralForeground1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (content != null) ...[
                        SizedBox(height: spacing.xs),
                        DefaultTextStyle.merge(
                          style: context.fluentType.caption1.copyWith(
                            color: colors.neutralForeground2,
                          ),
                          child: content!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (action != null) ...[SizedBox(width: spacing.s), action!],
            ],
          ),
        ),
      ),
    );
  }

  IconData get _severityIcon {
    return switch (severity) {
      FluentInfoSeverity.success => FluentIcons.checkMark,
      FluentInfoSeverity.warning => FluentIcons.warning,
      FluentInfoSeverity.error => FluentIcons.networkOff,
      FluentInfoSeverity.info => FluentIcons.info,
    };
  }

  _FeedbackSeverityColors _severityColors(FluentColors colors) {
    return switch (severity) {
      FluentInfoSeverity.success => _FeedbackSeverityColors(
        foreground: colors.statusSuccessForeground,
      ),
      FluentInfoSeverity.warning => _FeedbackSeverityColors(
        foreground: colors.statusWarningForeground,
      ),
      FluentInfoSeverity.error => _FeedbackSeverityColors(
        foreground: colors.statusDangerForeground,
      ),
      FluentInfoSeverity.info => _FeedbackSeverityColors(
        foreground: colors.brandForeground1,
      ),
    };
  }
}

/// 紧凑反馈的语义色。
class _FeedbackSeverityColors {
  const _FeedbackSeverityColors({required this.foreground});

  /// 前景色。
  final Color foreground;
}
