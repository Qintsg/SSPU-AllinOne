/*
 * Fluent 2 表单辅助组件 — 标签与数值输入
 * @Project : SSPU-AllinOne
 * @File : fluent_form.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:flutter/services.dart';

import '../fluent/fluent_context_ext.dart';
import 'fluent_text_field.dart';

/// Fluent 2 表单标签。
class FluentInfoLabel extends StatelessWidget {
  const FluentInfoLabel({super.key, required this.label, required this.child});

  /// 标签文本。
  final String label;

  /// 表单控件。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final colors = context.fluentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: type.caption1Strong.copyWith(color: colors.neutralForeground1),
        ),
        SizedBox(height: spacing.xs),
        child,
      ],
    );
  }
}

/// Fluent 2 正整数输入框。
class FluentNumberBox extends StatelessWidget {
  const FluentNumberBox({
    super.key,
    required this.value,
    this.enabled = true,
    this.suffixText,
    this.min = 0,
    this.max,
    this.onChanged,
    this.onSubmitted,
  });

  /// 当前数值。
  final int value;

  /// 是否启用。
  final bool enabled;

  /// 后缀文本。
  final String? suffixText;

  /// 最小值。
  final int min;

  /// 最大值。
  final int? max;

  /// 数值变化回调。
  final ValueChanged<int>? onChanged;

  /// 提交回调。
  final ValueChanged<int>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return FluentTextField(
      key: ValueKey('$value-$enabled'),
      initialValue: value.toString(),
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      suffix: suffixText == null ? null : Text(suffixText!),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed == null) return;
        onChanged?.call(_normalize(parsed));
      },
      onSubmitted: (text) => onSubmitted?.call(_normalize(int.tryParse(text) ?? value)),
    );
  }

  int _normalize(int raw) {
    final upper = max;
    if (upper == null) return raw < min ? min : raw;
    return raw.clamp(min, upper);
  }
}
