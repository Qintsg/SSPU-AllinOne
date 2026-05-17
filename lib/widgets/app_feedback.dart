/*
 * Material 3 页面反馈工具 — 统一 SnackBar 反馈入口
 * @Project : SSPU-AllinOne
 * @File : app_feedback.dart
 * @Author : Qintsg
 * @Date : 2026-05-16
 */

import 'package:flutter/material.dart';

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

/// 显示 Material 3 SnackBar 反馈。
void showAppFeedback(
  BuildContext context, {
  required String message,
  AppFeedbackSeverity severity = AppFeedbackSeverity.info,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  final backgroundColor = switch (severity) {
    AppFeedbackSeverity.info => colorScheme.inverseSurface,
    AppFeedbackSeverity.success => colorScheme.primaryContainer,
    AppFeedbackSeverity.warning => colorScheme.tertiaryContainer,
    AppFeedbackSeverity.error => colorScheme.errorContainer,
  };
  final foregroundColor = switch (severity) {
    AppFeedbackSeverity.info => colorScheme.onInverseSurface,
    AppFeedbackSeverity.success => colorScheme.onPrimaryContainer,
    AppFeedbackSeverity.warning => colorScheme.onTertiaryContainer,
    AppFeedbackSeverity.error => colorScheme.onErrorContainer,
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: foregroundColor,
      ),
    );
}
