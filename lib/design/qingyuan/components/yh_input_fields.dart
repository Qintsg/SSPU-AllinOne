/* 清源输入扩展 — 搜索、长文本、日期与一次性验证码。 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';
import 'yh_text_field.dart';

class YhSearch extends StatelessWidget {
  const YhSearch({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = '搜索',
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => YhTextField(
    label: '搜索',
    showLabel: false,
    controller: controller,
    focusNode: focusNode,
    hint: hint,
    prefixIcon: YhIcons.search,
    textInputAction: TextInputAction.search,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

class YhTextarea extends StatelessWidget {
  const YhTextarea({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.maxLines = 4,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => YhTextField(
    label: label,
    controller: controller,
    hint: hint,
    helper: helper,
    errorText: errorText,
    maxLines: maxLines,
    textInputAction: TextInputAction.newline,
    keyboardType: TextInputType.multiline,
    onChanged: onChanged,
  );
}

class YhDatePicker extends StatelessWidget {
  const YhDatePicker({
    super.key,
    required this.label,
    this.value,
    this.placeholder = '选择日期',
    this.onTap,
    this.errorText,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.typography.small.copyWith(color: theme.color.muted),
        ),
        SizedBox(height: theme.spacing.xs),
        YhPressable(
          semanticLabel: label,
          hint: placeholder,
          onPressed: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.surface,
              border: Border.all(
                color: hasError ? theme.color.danger : theme.color.border,
                width: theme.focus.ringWidth,
              ),
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.control.regular),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
                child: Row(
                  children: [
                    Icon(YhIcons.calendar, color: theme.color.brandStrong),
                    SizedBox(width: theme.spacing.s),
                    Expanded(
                      child: Text(
                        value ?? placeholder,
                        style: theme.typography.body.copyWith(
                          color: value == null
                              ? theme.color.muted
                              : theme.color.foreground,
                        ),
                      ),
                    ),
                    Icon(YhIcons.chevronRight, color: theme.color.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: theme.spacing.xs),
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: theme.typography.caption.copyWith(
                color: theme.color.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class YhOtp extends StatelessWidget {
  const YhOtp({
    super.key,
    required this.controller,
    this.length = 6,
    this.label = '验证码',
    this.errorText,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onCompleted;

  @override
  Widget build(BuildContext context) => YhTextField(
    label: label,
    controller: controller,
    errorText: errorText,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(length),
    ],
    onChanged: (value) {
      if (value.length == length) onCompleted?.call(value);
    },
  );
}
