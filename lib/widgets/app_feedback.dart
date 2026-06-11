/*
 * Fluent 2 页面反馈工具 — 统一信息条反馈入口
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

/// 显示 Fluent 2 信息条反馈。
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

/// 显示自定义 Fluent 2 信息条反馈。
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
    builder: (context) => PrimaryScrollController.none(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: PhysicalModel(
              color: Colors.transparent,
              elevation: 8,
              child: FluentInfoBar(
                title: title,
                content: content,
                severity: severity,
                action: actionBuilder?.call(close),
              ),
            ),
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
