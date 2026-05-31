/*
 * Fluent 2 页面反馈工具 — 统一信息条反馈入口
 * @Project : SSPU-AllinOne
 * @File : app_feedback.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import '../design/fluent_ui.dart';

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
  final messenger = ScaffoldMessenger.of(context);
  final infoSeverity = switch (severity) {
    AppFeedbackSeverity.info => FluentInfoSeverity.info,
    AppFeedbackSeverity.success => FluentInfoSeverity.success,
    AppFeedbackSeverity.warning => FluentInfoSeverity.warning,
    AppFeedbackSeverity.error => FluentInfoSeverity.error,
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: FluentInfoBar(
          title: Text(message),
          severity: infoSeverity,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// 显示自定义 Fluent 2 信息条反馈。
void showFluentInfoBar(
  BuildContext context, {
  required Widget title,
  Widget? content,
  FluentInfoSeverity severity = FluentInfoSeverity.info,
  Widget Function(VoidCallback close)? actionBuilder,
}) {
  final messenger = ScaffoldMessenger.of(context);
  late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
  controller = messenger.showSnackBar(
    SnackBar(
      content: Builder(
        builder: (context) => FluentInfoBar(
          title: title,
          content: content,
          severity: severity,
          action: actionBuilder?.call(() => controller.close()),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
