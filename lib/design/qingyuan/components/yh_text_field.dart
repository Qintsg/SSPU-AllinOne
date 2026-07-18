/* 清源文本输入框 — 标签与输入机械层分离。 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhTextField extends StatefulWidget {
  const YhTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.keyboardType,
    this.inputFormatters,
    this.showLabel = true,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool showLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<YhTextField> createState() => _YhTextFieldState();
}

class _YhTextFieldState extends State<YhTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _ownsController;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _attachFocusNode(widget.focusNode);
  }

  void _attachController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
    _controller.addListener(_handleValueChanged);
  }

  void _attachFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode(debugLabel: widget.label);
    _focusNode.addListener(_handleValueChanged);
  }

  void _handleValueChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(YhTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleValueChanged);
      if (_ownsController) _controller.dispose();
      _attachController(widget.controller);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleValueChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      _attachFocusNode(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleValueChanged);
    _focusNode.removeListener(_handleValueChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? theme.color.danger
        : _focusNode.hasFocus
        ? theme.color.brandStrong
        : theme.color.border;
    final helpText = widget.errorText ?? widget.helper;
    final textStyle = theme.typography.body.copyWith(
      color: widget.enabled ? theme.color.foreground : theme.color.muted,
    );

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.label,
      value: widget.obscure ? null : _controller.text,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLabel) ...[
              Text(
                widget.label,
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
              SizedBox(height: theme.spacing.xs),
            ],
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _focusNode.requestFocus : null,
              child: AnimatedContainer(
                duration: theme.motion.fast,
                curve: theme.motion.curve,
                constraints: BoxConstraints(
                  minHeight: widget.maxLines > 1
                      ? theme.control.regular * widget.maxLines
                      : theme.control.regular,
                ),
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? theme.color.surface
                      : theme.color.sunken,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(theme.radius.input),
                ),
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
                child: Row(
                  crossAxisAlignment: widget.maxLines > 1
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Padding(
                        padding: EdgeInsets.only(
                          top: widget.maxLines > 1 ? theme.spacing.m : 0,
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: _focusNode.hasFocus
                              ? theme.color.brandStrong
                              : theme.color.muted,
                        ),
                      ),
                      SizedBox(width: theme.spacing.s),
                    ],
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          if (_controller.text.isEmpty && widget.hint != null)
                            IgnorePointer(
                              child: Text(
                                widget.hint!,
                                style: textStyle.copyWith(
                                  color: theme.color.muted,
                                ),
                              ),
                            ),
                          EditableText(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: textStyle,
                            cursorColor: theme.color.brandStrong,
                            backgroundCursorColor: theme.color.muted,
                            selectionColor: theme.color.brand.withValues(
                              alpha: 0.28,
                            ),
                            readOnly: !widget.enabled,
                            autofocus: widget.autofocus,
                            obscureText: widget.obscure,
                            maxLines: widget.obscure ? 1 : widget.maxLines,
                            keyboardType: widget.keyboardType,
                            inputFormatters: widget.inputFormatters,
                            textInputAction: widget.textInputAction,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                          ),
                        ],
                      ),
                    ),
                    if (widget.suffix != null) ...[
                      SizedBox(width: theme.spacing.s),
                      widget.suffix!,
                    ],
                  ],
                ),
              ),
            ),
            if (helpText != null) ...[
              SizedBox(height: theme.spacing.xs),
              Semantics(
                liveRegion: hasError,
                child: Text(
                  helpText,
                  style: theme.typography.caption.copyWith(
                    color: hasError ? theme.color.danger : theme.color.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
