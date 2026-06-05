/*
 * Fluent 输入框兼容层 — 包装外部 fluent_ui TextBox / InfoLabel
 * @Project : SSPU-AllinOne
 * @File : fluent_text_field.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 */

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:flutter/services.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 输入框。
class FluentTextField extends StatefulWidget {
  const FluentTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.expands = false,
    this.textAlignVertical,
    this.inputFormatters,
    this.style,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  /// 文本控制器。
  final TextEditingController? controller;

  /// 无控制器时的初始值。
  final String? initialValue;

  /// 顶部标签。
  final String? label;

  /// 占位文本。
  final String? placeholder;

  /// 辅助说明文本。
  final String? helperText;

  /// 错误文本；非空时进入错误态。
  final String? errorText;

  /// 是否密文。
  final bool obscureText;

  /// 前置图标。
  final IconData? prefixIcon;

  /// 后置组件。
  final Widget? suffix;

  /// 键盘类型。
  final TextInputType? keyboardType;

  /// 焦点节点。
  final FocusNode? focusNode;

  /// 是否自动聚焦。
  final bool autofocus;

  /// 是否启用。
  final bool enabled;

  /// 最大行数。
  final int? maxLines;

  /// 是否填满父级高度。
  final bool expands;

  /// 文本垂直对齐。
  final TextAlignVertical? textAlignVertical;

  /// 输入过滤器。
  final List<TextInputFormatter>? inputFormatters;

  /// 文本样式覆盖。
  final TextStyle? style;

  /// 输入动作。
  final TextInputAction? textInputAction;

  /// 内容变更回调。
  final ValueChanged<String>? onChanged;

  /// 提交回调。
  final ValueChanged<String>? onSubmitted;

  @override
  State<FluentTextField> createState() => _FluentTextFieldState();
}

class _FluentTextFieldState extends State<FluentTextField> {
  TextEditingController? _localController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null && widget.initialValue != null) {
      _localController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void didUpdateWidget(covariant FluentTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && _localController == null && widget.initialValue != null) {
      _localController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final spacing = context.fluentSpacing;
    final type = context.fluentType;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    Widget field = TextBox(
      controller: widget.controller ?? _localController,
      focusNode: widget.focusNode,
      placeholder: widget.placeholder,
      prefix: widget.prefixIcon == null
          ? null
          : Padding(
              padding: EdgeInsetsDirectional.only(start: spacing.s),
              child: Icon(
                widget.prefixIcon,
                size: 18,
                color: colors.neutralForeground3,
              ),
            ),
      suffix: widget.suffix,
      keyboardType: widget.keyboardType,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      maxLines: widget.expands ? null : (widget.obscureText ? 1 : widget.maxLines),
      expands: widget.expands,
      textAlignVertical: widget.textAlignVertical,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style ?? type.body1,
      highlightColor: hasError ? colors.statusDangerForeground : null,
      unfocusedColor: hasError ? colors.statusDangerForeground : null,
    );

    if (widget.label != null) {
      field = InfoLabel(label: widget.label!, child: field);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        if (hasError) ...[
          SizedBox(height: spacing.xs),
          Text(
            widget.errorText!,
            style: type.caption1.copyWith(color: colors.statusDangerForeground),
          ),
        ] else if (widget.helperText != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            widget.helperText!,
            style: type.caption1.copyWith(color: colors.neutralForeground3),
          ),
        ],
      ],
    );
  }
}
