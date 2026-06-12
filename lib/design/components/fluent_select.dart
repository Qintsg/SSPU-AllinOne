/*
 * Fluent 选择器兼容层 — 包装外部 fluent_ui ComboBox
 * @Project : SSPU-AllinOne
 * @File : fluent_select.dart
 * @Author : Qintsg
 * @Date : 2026-05-30
 */

import 'package:fluent_ui/fluent_ui.dart' as fluent hide FluentIcons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Fluent 选择器选项。
class FluentSelectItem<T> {
  const FluentSelectItem({this.key, required this.value, required this.child});

  /// 选项键，用于测试和保持弹出层项身份稳定。
  final Key? key;

  /// 选项值。
  final T value;

  /// 选项内容。
  final Widget child;
}

/// Fluent 选择器。
class FluentSelect<T> extends StatefulWidget {
  const FluentSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.placeholder,
    this.isExpanded = false,
  });

  /// 当前值。
  final T? value;

  /// 可选项。
  final List<FluentSelectItem<T>> items;

  /// 选中项变化回调；为空时禁用。
  final ValueChanged<T?>? onChanged;

  /// 未选择时的占位内容。
  final Widget? placeholder;

  /// 是否占满可用宽度。
  final bool isExpanded;

  @override
  State<FluentSelect<T>> createState() => _FluentSelectState<T>();
}

class _FluentSelectState<T> extends State<FluentSelect<T>> {
  final GlobalKey<fluent.ComboBoxState<T>> _comboBoxKey =
      GlobalKey<fluent.ComboBoxState<T>>();

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey != LogicalKeyboardKey.arrowDown &&
        event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }

    final state = _comboBoxKey.currentState;
    if (state == null || !state.isEnabled) return KeyEventResult.ignored;
    state.openPopup();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final combo = fluent.ComboBox<T>(
      key: _comboBoxKey,
      value: widget.value,
      items: [
        for (final item in widget.items)
          fluent.ComboBoxItem<T>(
            key: item.key,
            value: item.value,
            child: item.child,
          ),
      ],
      onChanged: widget.onChanged,
      placeholder: widget.placeholder,
      isExpanded: widget.isExpanded,
    );

    return Focus(
      canRequestFocus: false,
      onKeyEvent: _handleKeyEvent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widget.isExpanded ? null : 1,
          child: combo,
        ),
      ),
    );
  }
}
