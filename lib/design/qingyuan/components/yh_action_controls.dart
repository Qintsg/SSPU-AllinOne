/* 清源操作控件 — FAB、分段、勾选、单选、滑杆与步骤器。 */

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundations/yh_pressable.dart';
import '../icons/yh_icons.dart';
import '../theme/yh_theme.dart';

class YhFab extends StatelessWidget {
  const YhFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.label,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: semanticLabel,
      onPressed: onTap,
      builder: (context, state, child) => Opacity(
        opacity: state.disabled ? 0.4 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: state.pressed
                ? theme.color.brandInk
                : theme.color.brandStrong,
            borderRadius: BorderRadius.circular(theme.radius.full),
            boxShadow: theme.elevation.e2,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: theme.control.regular),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: label == null ? theme.spacing.m : theme.spacing.l,
                vertical: theme.spacing.s,
              ),
              child: child,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.color.onBrand),
          if (label != null) ...[
            SizedBox(width: theme.spacing.s),
            Text(
              label!,
              style: theme.typography.body.copyWith(
                color: theme.color.onBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

@immutable
class YhSegmentedOption<T> {
  const YhSegmentedOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class YhSegmented<T> extends StatefulWidget {
  const YhSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<YhSegmentedOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  State<YhSegmented<T>> createState() => _YhSegmentedState<T>();
}

class _MoveSegmentIntent extends Intent {
  const _MoveSegmentIntent(this.offset);

  final int offset;
}

class _YhSegmentedState<T> extends State<YhSegmented<T>> {
  late List<FocusNode> _focusNodes = _createFocusNodes();

  List<FocusNode> _createFocusNodes() => [
    for (final option in widget.options)
      FocusNode(debugLabel: 'YhSegmented(${option.label})'),
  ];

  @override
  void didUpdateWidget(covariant YhSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOptions(oldWidget.options, widget.options)) {
      for (final node in _focusNodes) {
        node.dispose();
      }
      _focusNodes = _createFocusNodes();
    }
    _updateTraversal();
  }

  bool _sameOptions(
    List<YhSegmentedOption<T>> previous,
    List<YhSegmentedOption<T>> current,
  ) {
    if (previous.length != current.length) return false;
    for (var index = 0; index < previous.length; index++) {
      if (previous[index].value != current[index].value ||
          previous[index].label != current[index].label ||
          previous[index].icon != current[index].icon) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _updateTraversal() {
    for (var index = 0; index < _focusNodes.length; index++) {
      _focusNodes[index].skipTraversal =
          widget.onChanged == null ||
          widget.options[index].value != widget.value;
    }
  }

  void _moveSelection(int offset) {
    if (widget.onChanged == null || widget.options.isEmpty) return;
    var current = _focusNodes.indexWhere((node) => node.hasFocus);
    if (current < 0) {
      current = widget.options.indexWhere(
        (option) => option.value == widget.value,
      );
    }
    if (current < 0) current = 0;
    final next = (current + offset) % widget.options.length;
    widget.onChanged!(widget.options[next].value);
    _focusNodes[next].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    _updateTraversal();
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveSegmentIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveSegmentIntent(1),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MoveSegmentIntent: CallbackAction<_MoveSegmentIntent>(
            onInvoke: (intent) {
              _moveSelection(intent.offset);
              return null;
            },
          ),
        },
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.sunken,
              border: Border.all(color: theme.color.border),
              borderRadius: BorderRadius.circular(theme.radius.input),
            ),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < widget.options.length; index++)
                    YhPressable(
                      focusNode: _focusNodes[index],
                      semanticLabel: widget.options[index].label,
                      selected: widget.options[index].value == widget.value,
                      inMutuallyExclusiveGroup: true,
                      onPressed: widget.onChanged == null
                          ? null
                          : () =>
                                widget.onChanged!(widget.options[index].value),
                      builder: (context, state, child) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.options[index].value == widget.value
                              ? theme.color.surface
                              : state.hovered
                              ? theme.color.brandTint
                              : theme.color.surface.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(theme.radius.s),
                          boxShadow: widget.options[index].value == widget.value
                              ? theme.elevation.e1
                              : const [],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.m,
                            vertical: theme.spacing.s,
                          ),
                          child: child,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.options[index].icon != null) ...[
                            Icon(
                              widget.options[index].icon,
                              size: theme.spacing.l,
                            ),
                            SizedBox(width: theme.spacing.s),
                          ],
                          Text(
                            widget.options[index].label,
                            style: theme.typography.small.copyWith(
                              color: widget.options[index].value == widget.value
                                  ? theme.color.brandInk
                                  : theme.color.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YhCheckbox extends StatelessWidget {
  const YhCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return YhPressable(
      semanticLabel: label,
      toggled: value ?? false,
      onPressed: onChanged == null ? null : () => onChanged!(value != true),
      builder: (context, state, child) =>
          Opacity(opacity: state.disabled ? 0.4 : 1, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: value == false
                  ? theme.color.surface
                  : theme.color.brandStrong,
              border: Border.all(
                color: value == false
                    ? theme.color.border
                    : theme.color.brandStrong,
                width: theme.focus.ringWidth,
              ),
              borderRadius: BorderRadius.circular(theme.radius.s / 2),
            ),
            child: SizedBox.square(
              dimension: theme.spacing.l,
              child: value == false
                  ? null
                  : Icon(
                      value == null ? YhIcons.minimize : YhIcons.check,
                      size: theme.spacing.m,
                      color: theme.color.onBrand,
                    ),
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Text(
            label,
            style: theme.typography.body.copyWith(
              color: theme.color.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class YhRadio<T> extends StatelessWidget {
  const YhRadio({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final selected = value == groupValue;
    return YhPressable(
      semanticLabel: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onPressed: onChanged == null ? null : () => onChanged!(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? theme.color.brandStrong : theme.color.surface,
              border: Border.all(
                color: selected ? theme.color.brandStrong : theme.color.border,
                width: theme.focus.ringWidth,
              ),
            ),
            child: SizedBox.square(
              dimension: theme.spacing.l,
              child: selected
                  ? Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.color.onBrand,
                        ),
                        child: SizedBox.square(dimension: theme.spacing.s),
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: theme.spacing.s),
          Text(label, style: theme.typography.body),
        ],
      ),
    );
  }
}
