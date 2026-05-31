/*
 * Fluent 2 输入框 — 描边 / 聚焦强调线 / 错误态全走令牌
 * @Project : SSPU-AllinOne
 * @File : fluent_text_field.dart
 * @Author : Qintsg
 * @Date : 2026-05-18
 *
 * 令牌映射见 DESIGN.md §6.2：高度 32；圆角 radiusMedium；内边距 spacingM；
 * 默认描边 neutralStroke1 1px，聚焦底部强调线 brandStroke1 2px；
 * 错误态描边与辅助文字 statusDangerForeground。
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fluent/fluent_context_ext.dart';

/// Fluent 2 输入框。
class FluentTextField extends StatelessWidget {
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

  /// 顶部标签（caption1Strong）。
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
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final radii = context.fluentRadii;
    final spacing = context.fluentSpacing;
    final stroke = context.fluentStroke;
    final type = context.fluentType;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: type.caption1Strong.copyWith(
              color: colors.neutralForeground1,
            ),
          ),
          SizedBox(height: spacing.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: expands ? null : (obscureText ? 1 : maxLines),
          expands: expands,
          textAlignVertical: textAlignVertical,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style:
              style ?? type.body1.copyWith(color: colors.neutralForeground1),
          cursorColor: colors.brandStroke1,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled
                ? colors.neutralBackground1
                : colors.neutralBackground3,
            hintText: placeholder,
            hintStyle: type.body1.copyWith(
              color: colors.neutralForeground3,
            ),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 18,
                    color: colors.neutralForeground3,
                  ),
            suffixIcon: suffix,
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.s,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radii.mediumBorder,
              borderSide: BorderSide(
                color: hasError
                    ? colors.statusDangerForeground
                    : enabled
                    ? colors.neutralStroke1
                    : colors.neutralStroke2,
                width: stroke.thin,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: radii.mediumBorder,
              borderSide: BorderSide(
                color: colors.neutralStroke2,
                width: stroke.thin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radii.mediumBorder,
              borderSide: BorderSide(
                color: hasError
                    ? colors.statusDangerForeground
                    : colors.brandStroke1,
                width: stroke.thick,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: spacing.xs),
          Text(
            errorText!,
            style: type.caption1.copyWith(
              color: colors.statusDangerForeground,
            ),
          ),
        ] else if (helperText != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            helperText!,
            style: type.caption1.copyWith(
              color: colors.neutralForeground3,
            ),
          ),
        ],
      ],
    );
  }
}
