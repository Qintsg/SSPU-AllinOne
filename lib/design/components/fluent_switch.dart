/*
 * Fluent 开关兼容层 — 包装外部 fluent_ui ToggleSwitch
 * @Project : SSPU-AllinOne
 * @File : fluent_switch.dart
 * @Author : Qintsg
 * @Date : 2026-05-29
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

/// Fluent 开关控件。
class FluentSwitch extends StatelessWidget {
  const FluentSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  /// 当前开关值。
  final bool value;

  /// 值变化回调；为空时进入禁用态。
  final ValueChanged<bool>? onChanged;

  /// 无障碍语义标签。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ToggleSwitch(
      checked: value,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
    );
  }
}
