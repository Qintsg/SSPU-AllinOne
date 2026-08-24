/* 清源数值输入框 — 受限整数输入与确定性外部值同步。 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';
import 'yh_text_field.dart';

class YhNumberField extends StatefulWidget {
  const YhNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onSubmitted,
    this.min = 0,
    this.max = 999,
    this.suffix,
    this.enabled = true,
    this.showLabel = true,
  }) : assert(min <= max),
       assert(value >= min && value <= max);

  final String label;
  final int value;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onSubmitted;
  final int min;
  final int max;
  final String? suffix;
  final bool enabled;
  final bool showLabel;

  @override
  State<YhNumberField> createState() => _YhNumberFieldState();
}

class _YhNumberFieldState extends State<YhNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode(debugLabel: widget.label);
  }

  @override
  void didUpdateWidget(YhNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.value = TextEditingValue(
        text: widget.value.toString(),
        selection: TextSelection.collapsed(
          offset: widget.value.toString().length,
        ),
      );
    }
  }

  int? _parseInRange(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < widget.min || parsed > widget.max) {
      return null;
    }
    return parsed;
  }

  void _handleChanged(String text) {
    final parsed = _parseInRange(text);
    if (parsed != null && parsed != widget.value) {
      widget.onChanged?.call(parsed);
    }
  }

  void _handleSubmitted(String text) {
    final parsed = int.tryParse(text);
    final normalized = (parsed ?? widget.value).clamp(widget.min, widget.max);
    _controller.value = TextEditingValue(
      text: normalized.toString(),
      selection: TextSelection.collapsed(offset: normalized.toString().length),
    );
    if (normalized != widget.value) widget.onChanged?.call(normalized);
    widget.onSubmitted?.call(normalized);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhTextField(
      label: widget.label,
      showLabel: widget.showLabel,
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled && widget.onChanged != null,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      suffix: widget.suffix == null
          ? null
          : Text(
              widget.suffix!,
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
      onChanged: _handleChanged,
      onSubmitted: _handleSubmitted,
    );
  }
}
