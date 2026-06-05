/*
 * Fluent 信息条兼容层 — 包装外部 fluent_ui InfoBar
 * @Project : SSPU-AllinOne
 * @File : fluent_info_bar.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

/// 信息条严重级别。
enum FluentInfoSeverity { info, success, warning, error }

/// Fluent 信息条。
class FluentInfoBar extends StatelessWidget {
  const FluentInfoBar({
    super.key,
    required this.title,
    this.content,
    this.severity = FluentInfoSeverity.info,
    this.action,
  });

  /// 标题。
  final Widget title;

  /// 详情内容。
  final Widget? content;

  /// 严重级别。
  final FluentInfoSeverity severity;

  /// 右侧操作。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return InfoBar(
      title: title,
      content: content,
      action: action,
      severity: _severity,
      isLong: content != null,
    );
  }

  InfoBarSeverity get _severity {
    return switch (severity) {
      FluentInfoSeverity.info => InfoBarSeverity.info,
      FluentInfoSeverity.success => InfoBarSeverity.success,
      FluentInfoSeverity.warning => InfoBarSeverity.warning,
      FluentInfoSeverity.error => InfoBarSeverity.error,
    };
  }
}
