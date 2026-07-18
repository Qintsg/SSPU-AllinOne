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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? theme.spacing.m : theme.spacing.l,
              vertical: theme.spacing.m,
            ),
            child: child,
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

class YhSegmented<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
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
              for (final option in options)
                YhPressable(
                  semanticLabel: option.label,
                  selected: option.value == value,
                  inMutuallyExclusiveGroup: true,
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(option.value),
                  builder: (context, state, child) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: option.value == value
                          ? theme.color.surface
                          : state.hovered
                          ? theme.color.brandTint
                          : theme.color.surface.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(theme.radius.s),
                      boxShadow: option.value == value
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
                      if (option.icon != null) ...[
                        Icon(option.icon, size: theme.spacing.l),
                        SizedBox(width: theme.spacing.s),
                      ],
                      Text(
                        option.label,
                        style: theme.typography.small.copyWith(
                          color: option.value == value
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

class YhSlider extends StatefulWidget {
  const YhSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '滑杆',
    this.divisions,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String label;
  final int? divisions;

  @override
  State<YhSlider> createState() => _YhSliderState();
}

class _YhSliderState extends State<YhSlider> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'YhSlider');

  double get _value => widget.value.clamp(0, 1);

  void _setValue(double value) {
    if (widget.onChanged == null) return;
    final normalized = value.clamp(0.0, 1.0);
    final divisions = widget.divisions;
    widget.onChanged!(
      divisions == null
          ? normalized
          : (normalized * divisions).round() / divisions,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Semantics(
      slider: true,
      enabled: widget.onChanged != null,
      label: widget.label,
      value: '${(_value * 100).round()}%',
      increasedValue: '${((_value + 0.1).clamp(0, 1) * 100).round()}%',
      decreasedValue: '${((_value - 0.1).clamp(0, 1) * 100).round()}%',
      onIncrease: widget.onChanged == null
          ? null
          : () => _setValue(_value + 0.1),
      onDecrease: widget.onChanged == null
          ? null
          : () => _setValue(_value - 0.1),
      child: FocusableActionDetector(
        enabled: widget.onChanged != null,
        focusNode: _focusNode,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight):
              DirectionalFocusIntent(TraversalDirection.right),
          SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
            TraversalDirection.left,
          ),
        },
        actions: {
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (intent) {
              _setValue(
                _value +
                    (intent.direction == TraversalDirection.right ? 0.1 : -0.1),
              );
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onChanged == null
                ? null
                : (details) => _setValue(
                    details.localPosition.dx / constraints.maxWidth,
                  ),
            onHorizontalDragUpdate: widget.onChanged == null
                ? null
                : (details) => _setValue(
                    details.localPosition.dx / constraints.maxWidth,
                  ),
            child: SizedBox(
              height: theme.control.minimumTarget,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: theme.spacing.s,
                    decoration: BoxDecoration(
                      color: theme.color.border,
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _value,
                    child: Container(
                      height: theme.spacing.s,
                      decoration: BoxDecoration(
                        color: theme.color.brandStrong,
                        borderRadius: BorderRadius.circular(theme.radius.full),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(_value * 2 - 1, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.color.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.color.brandStrong,
                          width: theme.focus.ringWidth,
                        ),
                        boxShadow: theme.elevation.e1,
                      ),
                      child: SizedBox.square(dimension: theme.spacing.l),
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

class YhStepper extends StatelessWidget {
  const YhStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepSelected,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: theme.focus.ringWidth,
                color: index <= currentStep
                    ? theme.color.brandStrong
                    : theme.color.border,
              ),
            ),
          YhPressable(
            semanticLabel: '第 ${index + 1} 步，${steps[index]}',
            selected: index == currentStep,
            onPressed: onStepSelected == null
                ? null
                : () => onStepSelected!(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? theme.color.brandStrong
                        : theme.color.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.color.border),
                  ),
                  child: SizedBox.square(
                    dimension: theme.spacing.xl,
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.typography.small.copyWith(
                          color: index <= currentStep
                              ? theme.color.onBrand
                              : theme.color.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(steps[index], style: theme.typography.caption),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
