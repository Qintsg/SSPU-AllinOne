/* 清源可选择文本 — 基于 EditableText 的只读机械层。 */

import 'package:flutter/widgets.dart';

import '../theme/yh_theme.dart';

class YhSelectableText extends StatefulWidget {
  const YhSelectableText(
    this.data, {
    super.key,
    this.style,
    this.semanticLabel,
  });

  final String data;
  final TextStyle? style;
  final String? semanticLabel;

  @override
  State<YhSelectableText> createState() => _YhSelectableTextState();
}

class _YhSelectableTextState extends State<YhSelectableText> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.data);
    _focusNode = FocusNode(debugLabel: 'YhSelectableText');
  }

  @override
  void didUpdateWidget(YhSelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.value = TextEditingValue(
        text: widget.data,
        selection: TextSelection.collapsed(offset: widget.data.length),
      );
    }
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
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      readOnly: true,
      child: EditableText(
        controller: _controller,
        focusNode: _focusNode,
        style:
            widget.style ??
            theme.typography.body.copyWith(color: theme.color.foreground),
        cursorColor: theme.color.brandStrong,
        backgroundCursorColor: theme.color.muted,
        selectionColor: theme.color.brand.withValues(alpha: 0.28),
        readOnly: true,
        showCursor: false,
        maxLines: null,
        textDirection: Directionality.of(context),
        selectionControls: null,
        enableInteractiveSelection: true,
      ),
    );
  }
}
